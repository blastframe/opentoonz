import SwiftUI
import UIKit

struct VectorCanvasView: View {
    private let minCanvasScale: CGFloat = 0.35
    private let maxCanvasScale: CGFloat = 4.0
    @EnvironmentObject private var store: DocumentStore
    @State private var inProgressPoints: [VectorPoint] = []
    @State private var toolStartPoint: VectorPoint?
    @State private var previousToolPoint: VectorPoint?
    @GestureState private var magnification: CGFloat = 1
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var rotation: Angle = .zero

    var body: some View {
        GeometryReader { _ in
            let visibleLayers = store.document.layers.reversed().filter(\.isVisible)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))

                for layer in visibleLayers {
                    if let frame = store.document.frame(layerID: layer.id, index: store.document.currentFrameIndex) {
                        draw(frame.strokes, in: &context)
                    }
                }

                if store.selectedTool == .brush {
                    draw([VectorStroke(styleID: store.document.selectedStyleID, points: inProgressPoints)], in: &context)
                } else if store.selectedTool == .geometric, let toolStartPoint, let end = inProgressPoints.last {
                    draw([VectorStroke(styleID: store.document.selectedStyleID, points: rectanglePoints(from: toolStartPoint, to: end), isClosed: true)], in: &context)
                }
            }
            .overlay(alignment: .topLeading) {
                Text(helpText)
                    .font(.caption.weight(.medium))
                    .padding(10)
                    .background(.thinMaterial, in: Capsule())
                    .padding(12)
            }
            .overlay {
                DrawingTouchOverlay(
                    isEnabled: acceptsCanvasInput,
                    onBegan: handleTouchBegan,
                    onMoved: handleTouchMoved,
                    onEnded: handleTouchEnded
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(radius: 20, y: 10)
            .scaleEffect(store.canvasScale * magnification)
            .rotationEffect(store.canvasRotation + rotation)
            .offset(width: store.canvasOffset.width + dragOffset.width, height: store.canvasOffset.height + dragOffset.height)
            .simultaneousGesture(navigationGesture)
            .padding(24)
        }
    }

    private var acceptsCanvasInput: Bool {
        switch store.selectedTool {
        case .brush, .geometric, .type:
            true
        default:
            store.selectedTool.editsExistingVectors
        }
    }

    private var helpText: String {
        switch store.selectedTool {
        case .brush: "Apple Pencil or touch draws pressure-aware vector strokes"
        case .geometric: "Drag to create a vector rectangle"
        case .type: "Tap to place a vector text placeholder"
        case .pump: "Drag over vectors to pump stroke thickness"
        case .magnet: "Drag near vectors to magnetically deform them"
        case .pinch: "Drag near vectors to pinch control points inward"
        case .bender: "Drag near vectors to bend them"
        case .iron: "Drag over vectors to smooth creases"
        case .cutter: "Tap a vector point to cut the stroke"
        case .tape: "Tap near two open vector ends to join them"
        case .eraser: "Drag over vector points to erase them"
        case .controlPoint: "Drag a nearby control point to reshape a vector"
        case .fill: "Tap a vector stroke to close it for filling"
        case .zoom, .hand, .rotate: "Pinch, pan, and rotate the canvas with gestures"
        default: "Select a vector tool, then work directly on the canvas"
        }
    }

    private var navigationGesture: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($magnification) { value, state, _ in state = value }
                .onEnded { value in store.canvasScale = min(max(store.canvasScale * value, minCanvasScale), maxCanvasScale) },
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

    private func handleTouchBegan(_ point: VectorPoint) {
        toolStartPoint = point
        previousToolPoint = point
        inProgressPoints = [point]
        if store.selectedTool.editsExistingVectors {
            store.applySelectedTool(at: point, from: nil)
        }
    }

    private func handleTouchMoved(_ point: VectorPoint) {
        switch store.selectedTool {
        case .brush, .geometric:
            if inProgressPoints.last != point {
                inProgressPoints.append(point)
            }
        case let tool where tool.editsExistingVectors:
            store.applySelectedTool(at: point, from: previousToolPoint)
        default:
            break
        }
        previousToolPoint = point
    }

    private func handleTouchEnded(_ point: VectorPoint) {
        switch store.selectedTool {
        case .brush:
            store.addStroke(points: inProgressPoints)
        case .geometric:
            if let toolStartPoint {
                store.addShape(from: toolStartPoint, to: point)
            }
        case .type:
            store.addTextPlaceholder(at: point)
        case let tool where tool.editsExistingVectors:
            store.applySelectedTool(at: point, from: previousToolPoint)
        default:
            break
        }
        toolStartPoint = nil
        previousToolPoint = nil
        inProgressPoints.removeAll(keepingCapacity: true)
    }

    private func rectanglePoints(from start: VectorPoint, to end: VectorPoint) -> [VectorPoint] {
        [
            start,
            VectorPoint(x: end.x, y: start.y, pressure: start.pressure),
            end,
            VectorPoint(x: start.x, y: end.y, pressure: end.pressure),
            start
        ]
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

private struct DrawingTouchOverlay: UIViewRepresentable {
    var isEnabled: Bool
    var onBegan: (VectorPoint) -> Void
    var onMoved: (VectorPoint) -> Void
    var onEnded: (VectorPoint) -> Void

    func makeUIView(context: Context) -> TouchCaptureView {
        let view = TouchCaptureView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = false
        view.handlers = handlers
        return view
    }

    func updateUIView(_ uiView: TouchCaptureView, context: Context) {
        uiView.isUserInteractionEnabled = isEnabled
        uiView.handlers = handlers
    }

    private var handlers: TouchCaptureView.Handlers {
        TouchCaptureView.Handlers(onBegan: onBegan, onMoved: onMoved, onEnded: onEnded)
    }
}

private final class TouchCaptureView: UIView {
    struct Handlers {
        var onBegan: (VectorPoint) -> Void
        var onMoved: (VectorPoint) -> Void
        var onEnded: (VectorPoint) -> Void
    }

    var handlers = Handlers(onBegan: { _ in }, onMoved: { _ in }, onEnded: { _ in })

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = vectorPoint(from: touches.first) else { return }
        handlers.onBegan(point)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = vectorPoint(from: touches.first) else { return }
        handlers.onMoved(point)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = vectorPoint(from: touches.first) else { return }
        handlers.onEnded(point)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = vectorPoint(from: touches.first) else { return }
        handlers.onEnded(point)
    }

    private func vectorPoint(from touch: UITouch?) -> VectorPoint? {
        guard let touch else { return nil }
        let location = touch.location(in: self)
        let pressure = touch.maximumPossibleForce > 0 ? Double(touch.force / touch.maximumPossibleForce) : 1
        return VectorPoint(x: location.x, y: location.y, pressure: max(0.1, pressure))
    }
}
