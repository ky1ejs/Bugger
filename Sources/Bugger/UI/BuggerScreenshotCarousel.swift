import ImageIO
import Photos
import PhotosUI
import SwiftUI
import UIKit

@MainActor
struct BuggerScreenshotCarousel: View {
    @Bindable
    var viewModel: BuggerScreenshotCarouselViewModel

    @State private var selection: [PhotosPickerItem] = []
    @State private var isLoading = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                addTile
                ForEach(viewModel.items) { item in
                    BuggerScreenshotThumbnail(
                        data: item.data,
                        thumbnail: item.thumbnail,
                        onDelete: { viewModel.remove(item.id) }
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: 200)
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
        let data = await viewModel.loadFromPicker(items)
        await MainActor.run {
            viewModel.add(data)
            selection = []
            isLoading = false
        }
    }

    private func loadFromManual() async {
        await MainActor.run { isLoading = true }
        let data = await viewModel.loadFromManual()
        await MainActor.run {
            viewModel.add(data)
            isLoading = false
        }
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
    func add(_ data: [Data]) {
        let newItems = data.map { data in
            BuggerScreenshotItem(
                data: data,
                thumbnail: Self.makeThumbnail(from: data)
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

    func apply(to draft: BuggerReportDraft) async throws -> BuggerReportDraft {
        var draft = draft
        draft.screenshots = items.map(\.data)
        return draft
    }

    func capture() async throws -> [Data] {
        items.map(\.data)
    }

    func loadFromPicker(_ items: [PhotosPickerItem]) async -> [Data] {
        await source.loadFromPicker(items)
    }

    func loadFromManual() async -> [Data] {
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
}

struct BuggerScreenshotItem: Identifiable {
    let id: UUID
    let data: Data
    let thumbnail: UIImage?

    init(id: UUID = UUID(), data: Data, thumbnail: UIImage?) {
        self.id = id
        self.data = data
        self.thumbnail = thumbnail
    }
}

struct BuggerScreenshotSource {
    enum Mode {
        case photoLibrary(matching: PHPickerFilter, library: PHPhotoLibrary)
        case manual
    }

    let mode: Mode
    let addTitle: String
    let loadFromPicker: ([PhotosPickerItem]) async -> [Data]
    let loadFromManual: () async -> [Data]
}

extension BuggerScreenshotSource {
    static var photoLibrary: BuggerScreenshotSource {
        BuggerScreenshotSource(
            mode: .photoLibrary(matching: .screenshots, library: .shared()),
            addTitle: "Add",
            loadFromPicker: { items in
                var data: [Data] = []
                for item in items {
                    if let itemData = try? await item.loadTransferable(type: Data.self) {
                        data.append(itemData)
                    }
                }
                return data
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
                    ].compactMap { $0 }
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

    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailView
                .frame(width: 120, height: 180)
                .background(Color.black.opacity(0.05))
                .cornerRadius(12)
                .clipped()

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
