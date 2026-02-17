import ImageIO
import Photos
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

@MainActor
struct BuggerScreenshotCarousel: View {
    @Bindable
    var viewModel: BuggerScreenshotCarouselViewModel

    @State private var selection: [PhotosPickerItem] = []
    @State private var isLoading = false
    @State private var annotationTarget: BuggerScreenshotAnnotationTarget?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                addTile
                ForEach(viewModel.items) { item in
                    BuggerScreenshotThumbnail(
                        data: item.data,
                        thumbnail: item.thumbnail,
                        onDelete: { viewModel.remove(item.id) },
                        onTap: item.isAnnotatable ? { openAnnotation(for: item) } : nil
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 200)
        .sheet(item: $annotationTarget) { target in
            BuggerScreenshotAnnotationSheet(
                image: target.image,
                onCancel: {
                    annotationTarget = nil
                },
                onApply: { image in
                    _ = viewModel.replaceAnnotatedImage(for: target.id, with: image)
                    annotationTarget = nil
                }
            )
        }
    }

    @MainActor
    @ViewBuilder
    private var addTile: some View {
        switch viewModel.source.mode {
        case .photoLibrary(let matching, let library):
            let addTileView =
            AddScreenshotTile(title: viewModel.source.addTitle, isLoading: isLoading)
            PhotosPicker(
                selection: $selection,
                matching: matching,
                photoLibrary: library
            ) {
                addTileView
            }
            .onChange(of: selection, { @MainActor _, newItems in
                guard !newItems.isEmpty else { return }
                Task { @MainActor in
                    await loadFromPicker(newItems)
                }
            })
        case .manual:
            let addTitle = viewModel.source.addTitle
            let loading = isLoading
            Button {
                Task { @MainActor in
                    await loadFromManual()
                }
            } label: {
                AddScreenshotTile(title: addTitle, isLoading: loading)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadFromPicker(_ items: [PhotosPickerItem]) async {
        await MainActor.run { isLoading = true }
        let attachments = await viewModel.loadFromPicker(items)
        await MainActor.run {
            viewModel.add(attachments)
            selection = []
            isLoading = false
        }
    }

    private func loadFromManual() async {
        await MainActor.run { isLoading = true }
        let attachments = await viewModel.loadFromManual()
        await MainActor.run {
            viewModel.add(attachments)
            isLoading = false
        }
    }

    private func openAnnotation(for item: BuggerScreenshotItem) {
        guard item.isAnnotatable, let image = item.decodedImage else {
            return
        }
        annotationTarget = BuggerScreenshotAnnotationTarget(id: item.id, image: image)
    }
}

@Observable
@MainActor
/// UI-bound state; conformance to Sendable is unchecked by design.
final class BuggerScreenshotCarouselViewModel: BuggerReportProviding, ScreenshotProviding, SectionTitleProviding, @unchecked Sendable {
    let sectionTitle = "Screenshots"
    let source: BuggerScreenshotSource

    var items: [BuggerScreenshotItem] = []

    init(source: BuggerScreenshotSource = .photoLibrary) {
        self.source = source
    }

    @MainActor
    func add(_ attachments: [BugReportAttachment]) {
        let newItems = attachments.map { attachment in
            BuggerScreenshotItem(
                attachment: attachment,
                thumbnail: Self.makeThumbnail(from: attachment.data)
            )
        }
        withAnimation(.snappy) {
            items.append(contentsOf: newItems)
        }
    }

    @MainActor
    func remove(_ id: UUID) {
        withAnimation(.snappy) {
            items.removeAll { $0.id == id }
        }
    }

    @MainActor
    @discardableResult
    func replaceAnnotatedImage(for id: UUID, with image: UIImage) -> Bool {
        guard
            let index = items.firstIndex(where: { $0.id == id }),
            let pngData = image.pngData()
        else {
            return false
        }

        let current = items[index]
        let updatedAttachment = BugReportAttachment(
            id: current.attachment.id,
            data: pngData,
            mimeType: "image/png",
            filename: Self.annotatedFilename(from: current.attachment.filename)
        )
        items[index] = BuggerScreenshotItem(
            id: current.id,
            attachment: updatedAttachment,
            thumbnail: Self.makeThumbnail(from: pngData)
        )
        return true
    }

    func apply(to draft: BuggerReportDraft) async throws -> BuggerReportDraft {
        var draft = draft
        draft.attachments = items.map(\.attachment)
        return draft
    }

    func capture() async throws -> [BugReportAttachment] {
        items.map(\.attachment)
    }

    func loadFromPicker(_ items: [PhotosPickerItem]) async -> [BugReportAttachment] {
        await source.loadFromPicker(items)
    }

    func loadFromManual() async -> [BugReportAttachment] {
        await source.loadFromManual()
    }

    private static func makeThumbnail(from data: Data, maxPixelSize: CGFloat = 320) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private static func annotatedFilename(from originalFilename: String?) -> String {
        guard
            let originalFilename,
            !originalFilename.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return "attachment-annotated.png"
        }

        let trimmed = originalFilename.trimmingCharacters(in: .whitespacesAndNewlines)
        let stem: String
        if let dotIndex = trimmed.lastIndex(of: "."), dotIndex != trimmed.startIndex {
            stem = String(trimmed[..<dotIndex])
        } else {
            stem = trimmed
        }
        return "\(stem)-annotated.png"
    }
}

struct BuggerScreenshotItem: Identifiable {
    let id: UUID
    let attachment: BugReportAttachment
    let thumbnail: UIImage?

    var data: Data {
        attachment.data
    }

    init(id: UUID = UUID(), attachment: BugReportAttachment, thumbnail: UIImage?) {
        self.id = id
        self.attachment = attachment
        self.thumbnail = thumbnail
    }

    var isImageMimeType: Bool {
        attachment.mimeType.lowercased().hasPrefix("image/")
    }

    var decodedImage: UIImage? {
        UIImage(data: attachment.data)
    }

    var isAnnotatable: Bool {
        isImageMimeType && decodedImage != nil
    }
}

struct BuggerScreenshotSource {
    enum Mode {
        case photoLibrary(matching: PHPickerFilter, library: PHPhotoLibrary)
        case manual
    }

    let mode: Mode
    let addTitle: String
    let loadFromPicker: ([PhotosPickerItem]) async -> [BugReportAttachment]
    let loadFromManual: () async -> [BugReportAttachment]
}

extension BuggerScreenshotSource {
    static var photoLibrary: BuggerScreenshotSource {
        BuggerScreenshotSource(
            mode: .photoLibrary(matching: .screenshots, library: .shared()),
            addTitle: "Add",
            loadFromPicker: { items in
                var attachments: [BugReportAttachment] = []
                for item in items {
                    if let itemData = try? await item.loadTransferable(type: Data.self) {
                        let contentType = item.supportedContentTypes.first
                        let mimeType = contentType?.preferredMIMEType ?? "application/octet-stream"
                        let fileExtension = contentType?.preferredFilenameExtension
                        let filename = fileExtension.map { "attachment.\($0)" }
                        attachments.append(
                            BugReportAttachment(
                                data: itemData,
                                mimeType: mimeType,
                                filename: filename
                            )
                        )
                    }
                }
                return attachments
            },
            loadFromManual: { [] }
        )
    }

    static var previewMock: BuggerScreenshotSource {
        BuggerScreenshotSource(
            mode: .manual,
            addTitle: "Add Sample",
            loadFromPicker: { _ in [] },
            loadFromManual: {
                await MainActor.run {
                    [
                        makeSample(color: .systemBlue),
                        makeSample(color: .systemGreen),
                        makeSample(color: .systemOrange)
                    ].compactMap { data in
                        guard let data else { return nil }
                        return BugReportAttachment(data: data, mimeType: "image/png")
                    }
                }
            }
        )
    }

    private static func makeSample(color: UIColor) -> Data? {
        let size = CGSize(width: 300, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData()
    }
}

struct BuggerScreenshotThumbnail: View {
    let data: Data
    let thumbnail: UIImage?
    let onDelete: () -> Void
    let onTap: (() -> Void)?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailView
                .frame(width: 120, height: 180)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .clipped()
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap?()
                }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = thumbnail {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Color.gray.opacity(0.2)
                .overlay(Text("Invalid").font(.caption))
        }
    }
}

struct AddScreenshotTile: View {
    let title: String
    let isLoading: Bool

    init(title: String = "Add", isLoading: Bool = false) {
        self.title = title
        self.isLoading = isLoading
    }

    var body: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView()
            } else {
                Image(systemName: "plus")
                    .font(.title2)
            }
            Text(title)
                .font(.caption)
        }
        .frame(width: 120, height: 180)
        .background(Color.black.opacity(0.04))
        .cornerRadius(12)
    }
}

#Preview {
    BuggerScreenshotCarousel(
        viewModel: BuggerScreenshotCarouselViewModel(source: .previewMock)
    )
    .padding()
}
