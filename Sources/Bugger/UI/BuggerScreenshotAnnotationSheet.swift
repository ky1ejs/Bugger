import SwiftUI
import UIKit

struct BuggerScreenshotAnnotationSheet: View {
    let image: UIImage
    let onCancel: () -> Void
    let onApply: (UIImage) -> Void

    @State private var strokes: [[CGPoint]] = []
    @State private var inProgressStroke: [CGPoint] = []

    private var hasChanges: Bool {
        !strokes.isEmpty || !inProgressStroke.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()

                    GeometryReader { geometry in
                        let size = geometry.size
                        Path { path in
                            addStrokePath(strokes, to: &path, in: size)
                            addStrokePath([inProgressStroke], to: &path, in: size)
                        }
                        .stroke(
                            Color.red,
                            style: StrokeStyle(
                                lineWidth: 4,
                                lineCap: .round,
                                lineJoin: .round
                            )
                        )
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let point = normalizedPoint(value.location, in: size)
                                    guard point.x >= 0, point.x <= 1, point.y >= 0, point.y <= 1 else {
                                        return
                                    }
                                    inProgressStroke.append(point)
                                }
                                .onEnded { _ in
                                    guard !inProgressStroke.isEmpty else { return }
                                    strokes.append(inProgressStroke)
                                    inProgressStroke = []
                                }
                        )
                    }
                }
                .aspectRatio(image.size, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(16)
            .navigationTitle("Annotate")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled(hasChanges)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("Undo") {
                        strokes = []
                        inProgressStroke = []
                    }
                    .disabled(!hasChanges)

                    Button("Apply") {
                        let mergedStrokes = strokes + (inProgressStroke.isEmpty ? [] : [inProgressStroke])
                        guard let annotatedImage = renderAnnotatedImage(from: image, strokes: mergedStrokes) else {
                            return
                        }
                        onApply(annotatedImage)
                    }
                }
            }
        }
    }

    private func addStrokePath(_ strokes: [[CGPoint]], to path: inout Path, in size: CGSize) {
        for stroke in strokes where !stroke.isEmpty {
            let points = stroke.map { denormalizedPoint($0, in: size) }
            path.move(to: points[0])
            for point in points.dropFirst() {
                path.addLine(to: point)
            }
            if points.count == 1 {
                path.addLine(to: CGPoint(x: points[0].x + 0.01, y: points[0].y + 0.01))
            }
        }
    }

    private func normalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return .zero }
        return CGPoint(x: point.x / size.width, y: point.y / size.height)
    }

    private func denormalizedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: point.x * size.width, y: point.y * size.height)
    }

    private func renderAnnotatedImage(from baseImage: UIImage, strokes: [[CGPoint]]) -> UIImage? {
        let size = baseImage.size
        guard size.width > 0, size.height > 0 else { return nil }

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = baseImage.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let lineWidth = max(2, min(12, min(size.width, size.height) * 0.006))

        return renderer.image { context in
            baseImage.draw(in: CGRect(origin: .zero, size: size))

            let cgContext = context.cgContext
            cgContext.setStrokeColor(UIColor.systemRed.cgColor)
            cgContext.setLineWidth(lineWidth)
            cgContext.setLineCap(.round)
            cgContext.setLineJoin(.round)

            for stroke in strokes where !stroke.isEmpty {
                let points = stroke.map { denormalizedPoint($0, in: size) }
                cgContext.beginPath()
                cgContext.move(to: points[0])
                for point in points.dropFirst() {
                    cgContext.addLine(to: point)
                }
                if points.count == 1 {
                    cgContext.addLine(to: CGPoint(x: points[0].x + 0.01, y: points[0].y + 0.01))
                }
                cgContext.strokePath()
            }
        }
    }
}

struct BuggerScreenshotAnnotationTarget: Identifiable {
    let id: UUID
    let image: UIImage
}
