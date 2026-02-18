import SwiftUI
import UIKit

struct BuggerScreenshotAnnotationSheet: View {
    let image: UIImage
    let onCancel: () -> Void
    let onApply: (UIImage) -> Void

    @State private var selectedColor: BuggerAnnotationColor = .red
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
                            selectedColor.swiftUIColor,
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
            .interactiveDismissDisabled(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        ForEach(BuggerAnnotationColor.allCases) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                HStack(spacing: 8) {
                                    colorSwatch(color)
                                    Text(color.label)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            colorSwatch(selectedColor)
                            Text("Color")
                        }
                    }

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

    private func colorSwatch(_ color: BuggerAnnotationColor) -> some View {
        Circle()
            .fill(color.swiftUIColor)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: 1)
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
            cgContext.setStrokeColor(selectedColor.uiColor.cgColor)
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

private enum BuggerAnnotationColor: CaseIterable, Identifiable {
    case red
    case yellow
    case cyan
    case white

    var id: String {
        label
    }

    var label: String {
        switch self {
        case .red:
            return "Red"
        case .yellow:
            return "Yellow"
        case .cyan:
            return "Cyan"
        case .white:
            return "White"
        }
    }

    var swiftUIColor: Color {
        switch self {
        case .red:
            return Color(uiColor: .systemRed)
        case .yellow:
            return Color(uiColor: .systemYellow)
        case .cyan:
            return Color(uiColor: .systemCyan)
        case .white:
            return .white
        }
    }

    var uiColor: UIColor {
        switch self {
        case .red:
            return .systemRed
        case .yellow:
            return .systemYellow
        case .cyan:
            return .systemCyan
        case .white:
            return .white
        }
    }

    var selectionMarkColor: Color {
        switch self {
        case .yellow, .white:
            return .black
        case .red, .cyan:
            return .white
        }
    }
}

struct BuggerScreenshotAnnotationTarget: Identifiable {
    let id: UUID
    let image: UIImage
}

#Preview {
    BuggerScreenshotAnnotationSheet(
        image: {
            let size = CGSize(width: 300, height: 620)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.systemGray6.setFill()
                context.fill(CGRect(origin: .zero, size: size))

                UIColor.systemBlue.withAlphaComponent(0.2).setFill()
                context.fill(CGRect(x: 20, y: 80, width: 260, height: 120))

                UIColor.systemOrange.withAlphaComponent(0.2).setFill()
                context.fill(CGRect(x: 20, y: 260, width: 260, height: 180))
            }
        }(),
        onCancel: {},
        onApply: { _ in }
    )
}
