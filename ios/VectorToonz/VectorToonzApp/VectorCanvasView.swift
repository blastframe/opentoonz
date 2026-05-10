import SwiftUI

struct VectorCanvasView: View {
    @EnvironmentObject private var store: DocumentStore
    @State private var inProgressPoints: [VectorPoint] = []
    @GestureState private var magnification: CGFloat = 1
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var rotation: Angle = .zero

    var body: some View {
        GeometryReader { geometry in
            let visibleLayers = store.document.layers.reversed().filter(\.isVisible)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

                for layer in visibleLayers {
                    if let frame = store.document.frame(layerID: layer.id, index: store.document.currentFrameIndex) {
                        draw(frame.strokes, in: &context)
                    }
                }

                draw([VectorStroke(styleID: store.document.selectedStyleID, points: inProgressPoints)], in: &context)
            }
            .overlay(alignment: .topLeading) {
                Text("Pinch to zoom · two-finger pan · rotate canvas · Apple Pencil draws vectors")
                    .font(.caption.weight(.medium))
                    .padding(10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(radius: 20, y: 10)
            .scaleEffect(store.canvasScale * magnification)
            .rotationEffect(store.canvasRotation + rotation)
            .offset(width: store.canvasOffset.width + dragOffset.width, height: store.canvasOffset.height + dragOffset.height)
            .gesture(drawGesture(in: geometry.size), including: store.selectedTool == .brush ? .gesture : .subviews)
            .simultaneousGesture(navigationGesture)
            .padding(24)
        }
    }

    private var navigationGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($magnification) { value, state, _ in state = value }
                .onEnded { value in store.canvasScale = min(max(store.canvasScale * value, 0.35), 4.0) },
            SimultaneousGesture(
                DragGesture(minimumDistance: 8).updating($dragOffset) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        store.canvasOffset.width += value.translation.width
                        store.canvasOffset.height += value.translation.height
                    },
                RotationGesture().updating($rotation) { value, state, _ in state = value }
                    .onEnded { value in store.canvasRotation += value }
            )
        )
    }

    private func drawGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard store.selectedTool == .brush else { return }
                let point = VectorPoint(x: value.location.x, y: value.location.y, pressure: 1)
                if inProgressPoints.last != point {
                    inProgressPoints.append(point)
                }
            }
            .onEnded { _ in
                store.addStroke(points: inProgressPoints)
                inProgressPoints.removeAll(keepingCapacity: true)
            }
    }

    private func draw(_ strokes: [VectorStroke], in context: inout GraphicsContext) {
        for stroke in strokes where stroke.points.count > 1 {
            let style = store.document.palette.first { $0.id == stroke.styleID } ?? store.document.selectedStyle
            var path = Path()
            path.move(to: CGPoint(x: stroke.points[0].x, y: stroke.points[0].y))
            for point in stroke.points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x, y: point.y))
            }
            if stroke.isClosed { path.closeSubpath() }
            context.stroke(
                path,
                with: .color(Color(red: style.red, green: style.green, blue: style.blue, opacity: style.alpha)),
                style: StrokeStyle(lineWidth: style.width, lineCap: .round, lineJoin: .round)
            )
        }
    }
}
