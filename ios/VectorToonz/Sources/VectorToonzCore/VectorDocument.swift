import Foundation

public enum VectorTool: String, CaseIterable, Codable, Identifiable, Sendable {
    case animate
    case selection
    case brush
    case geometric
    case type
    case fill
    case eraser
    case tape
    case stylePicker
    case rgbPicker
    case controlPoint
    case pinch
    case pump
    case magnet
    case bender
    case iron
    case cutter
    case hook
    case zoom
    case hand
    case rotate

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .animate: "Animate"
        case .selection: "Select"
        case .brush: "Brush"
        case .geometric: "Shape"
        case .type: "Type"
        case .fill: "Fill"
        case .eraser: "Eraser"
        case .tape: "Tape"
        case .stylePicker: "Style"
        case .rgbPicker: "RGB"
        case .controlPoint: "Points"
        case .pinch: "Pinch"
        case .pump: "Pump"
        case .magnet: "Magnet"
        case .bender: "Bender"
        case .iron: "Iron"
        case .cutter: "Cutter"
        case .hook: "Hook"
        case .zoom: "Zoom"
        case .hand: "Hand"
        case .rotate: "Rotate"
        }
    }

    public var systemImageName: String {
        switch self {
        case .animate: "arrow.up.left.and.arrow.down.right"
        case .selection: "cursorarrow.motionlines"
        case .brush: "pencil.tip"
        case .geometric: "square.on.circle"
        case .type: "textformat"
        case .fill: "paintpalette"
        case .eraser: "eraser"
        case .tape: "link"
        case .stylePicker: "eyedropper.halffull"
        case .rgbPicker: "eyedropper"
        case .controlPoint: "point.topleft.down.curvedto.point.bottomright.up"
        case .pinch: "arrow.down.right.and.arrow.up.left"
        case .pump: "arrow.up.and.down.and.arrow.left.and.right"
        case .magnet: "magnet"
        case .bender: "alternatingcurrent"
        case .iron: "scribble.variable"
        case .cutter: "scissors"
        case .hook: "paperclip"
        case .zoom: "magnifyingglass"
        case .hand: "hand.draw"
        case .rotate: "rotate.3d"
        }
    }

    public var editsExistingVectors: Bool {
        switch self {
        case .eraser, .tape, .fill, .controlPoint, .pinch, .pump, .magnet, .bender, .iron, .cutter:
            true
        case .animate, .selection, .brush, .geometric, .type, .stylePicker, .rgbPicker, .hook, .zoom, .hand, .rotate:
            false
        }
    }
}

public struct VectorPoint: Codable, Hashable, Sendable {
    public var x: Double
    public var y: Double
    public var pressure: Double

    public init(x: Double, y: Double, pressure: Double = 1.0) {
        self.x = x
        self.y = y
        self.pressure = pressure
    }

    public func distance(to other: VectorPoint) -> Double {
        hypot(x - other.x, y - other.y)
    }

    public func translated(dx: Double, dy: Double) -> VectorPoint {
        VectorPoint(x: x + dx, y: y + dy, pressure: pressure)
    }

    public func moved(toward target: VectorPoint, amount: Double) -> VectorPoint {
        VectorPoint(
            x: x + (target.x - x) * amount,
            y: y + (target.y - y) * amount,
            pressure: pressure
        )
    }
}

public struct VectorStyle: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var red: Double
    public var green: Double
    public var blue: Double
    public var alpha: Double
    public var width: Double

    public init(
        id: UUID = UUID(),
        name: String,
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double = 1.0,
        width: Double = 4.0
    ) {
        self.id = id
        self.name = name
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
        self.width = width
    }
}

public struct VectorStroke: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var styleID: UUID
    public var points: [VectorPoint]
    public var isClosed: Bool

    public init(id: UUID = UUID(), styleID: UUID, points: [VectorPoint] = [], isClosed: Bool = false) {
        self.id = id
        self.styleID = styleID
        self.points = points
        self.isClosed = isClosed
    }

    public mutating func append(_ point: VectorPoint) {
        points.append(point)
    }
}

public struct VectorFrame: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var index: Int
    public var strokes: [VectorStroke]

    public init(id: UUID = UUID(), index: Int, strokes: [VectorStroke] = []) {
        self.id = id
        self.index = index
        self.strokes = strokes
    }
}

public struct VectorLayer: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var isVisible: Bool
    public var frames: [VectorFrame]

    public init(id: UUID = UUID(), name: String, isVisible: Bool = true, frames: [VectorFrame] = []) {
        self.id = id
        self.name = name
        self.isVisible = isVisible
        self.frames = frames
    }
}

public struct VectorDocument: Identifiable, Codable, Hashable, Sendable {
    public static let fallbackStyle = VectorStyle(name: "Ink", red: 0.05, green: 0.05, blue: 0.08, width: 5.0)
    private static let minimumStrokePressure = 0.15
    private static let maximumStrokePressure = 4.0
    private static let pumpPressureIncrement = 0.45
    private static let pinchMovementStrength = 0.18
    private static let benderHorizontalTranslationFactor = 0.25
    private static let ironSmoothingStrength = 0.55
    private static let eraserRadiusScale = 0.35

    public var id: UUID
    public var title: String
    public var frameRate: Int
    public var currentFrameIndex: Int
    public var selectedLayerID: UUID
    public var selectedStyleID: UUID
    public var layers: [VectorLayer]
    public var palette: [VectorStyle]

    public init(
        id: UUID = UUID(),
        title: String = "Untitled Vector Animation",
        frameRate: Int = 24,
        currentFrameIndex: Int = 0,
        selectedLayerID: UUID? = nil,
        selectedStyleID: UUID? = nil,
        layers: [VectorLayer]? = nil,
        palette: [VectorStyle]? = nil
    ) {
        let styleList: [VectorStyle]
        if let palette, !palette.isEmpty {
            styleList = palette
        } else {
            styleList = [
                Self.fallbackStyle,
                VectorStyle(name: "Blue", red: 0.10, green: 0.38, blue: 0.90, width: 5.0),
                VectorStyle(name: "Fill", red: 1.00, green: 0.76, blue: 0.20, width: 2.0)
            ]
        }
        let layerID = selectedLayerID ?? UUID()
        self.id = id
        self.title = title
        self.frameRate = frameRate
        self.currentFrameIndex = currentFrameIndex
        self.selectedLayerID = layerID
        self.selectedStyleID = selectedStyleID ?? styleList.first?.id ?? Self.fallbackStyle.id
        self.layers = layers ?? [VectorLayer(id: layerID, name: "Vector Layer 1", frames: [VectorFrame(index: 0)])]
        self.palette = styleList
    }

    public var selectedLayer: VectorLayer? {
        layers.first { $0.id == selectedLayerID }
    }

    public var selectedStyle: VectorStyle {
        palette.first { $0.id == selectedStyleID } ?? palette.first ?? Self.fallbackStyle
    }

    public mutating func addLayer(named name: String? = nil) {
        let layer = VectorLayer(name: name ?? "Vector Layer \(layers.count + 1)", frames: [VectorFrame(index: currentFrameIndex)])
        layers.insert(layer, at: 0)
        selectedLayerID = layer.id
    }

    public mutating func toggleLayerVisibility(_ layerID: UUID) {
        guard let index = layers.firstIndex(where: { $0.id == layerID }) else { return }
        layers[index].isVisible.toggle()
    }

    public mutating func selectLayer(_ layerID: UUID) {
        guard layers.contains(where: { $0.id == layerID }) else { return }
        selectedLayerID = layerID
        ensureFrame(layerID: layerID, frameIndex: currentFrameIndex)
    }

    public mutating func setCurrentFrame(_ frameIndex: Int) {
        currentFrameIndex = max(0, frameIndex)
        ensureFrame(layerID: selectedLayerID, frameIndex: currentFrameIndex)
    }

    public mutating func addStroke(_ stroke: VectorStroke, to layerID: UUID? = nil, frameIndex: Int? = nil) {
        let targetLayerID = layerID ?? selectedLayerID
        let targetFrameIndex = frameIndex ?? currentFrameIndex
        ensureFrame(layerID: targetLayerID, frameIndex: targetFrameIndex)
        guard let layerIndex = layers.firstIndex(where: { $0.id == targetLayerID }),
              let frameIndexInLayer = layers[layerIndex].frames.firstIndex(where: { $0.index == targetFrameIndex }) else { return }
        layers[layerIndex].frames[frameIndexInLayer].strokes.append(stroke)
    }

    public mutating func duplicateCurrentFrame() {
        guard let layerIndex = layers.firstIndex(where: { $0.id == selectedLayerID }),
              let sourceFrame = layers[layerIndex].frames.first(where: { $0.index == currentFrameIndex }) else { return }
        let nextIndex = currentFrameIndex + 1
        layers[layerIndex].frames.removeAll { $0.index == nextIndex }
        var duplicate = sourceFrame
        duplicate.id = UUID()
        duplicate.index = nextIndex
        layers[layerIndex].frames.append(duplicate)
        layers[layerIndex].frames.sort { $0.index < $1.index }
        currentFrameIndex = nextIndex
    }

    public mutating func apply(
        tool: VectorTool,
        at point: VectorPoint,
        from previousPoint: VectorPoint? = nil,
        radius: Double = 72,
        intensity: Double = 1
    ) {
        guard tool.editsExistingVectors else { return }
        ensureFrame(layerID: selectedLayerID, frameIndex: currentFrameIndex)
        guard let layerIndex = layers.firstIndex(where: { $0.id == selectedLayerID }),
              let frameIndexInLayer = layers[layerIndex].frames.firstIndex(where: { $0.index == currentFrameIndex }) else { return }

        switch tool {
        case .eraser:
            eraseVectors(at: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .tape:
            tapeOpenVectorEnds(near: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .fill:
            closeNearestStroke(near: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .controlPoint:
            moveNearestControlPoint(to: point, from: previousPoint, radius: radius, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .pinch:
            mapCurrentFrame(layerIndex: layerIndex, frameIndex: frameIndexInLayer) { vectorPoint in
                let falloff = Self.influence(of: point, on: vectorPoint, radius: radius)
                return vectorPoint.moved(toward: point, amount: Self.pinchMovementStrength * intensity * falloff)
            }
        case .pump:
            mapCurrentFrame(layerIndex: layerIndex, frameIndex: frameIndexInLayer) { vectorPoint in
                let falloff = Self.influence(of: point, on: vectorPoint, radius: radius)
                var changed = vectorPoint
                changed.pressure = max(Self.minimumStrokePressure, min(Self.maximumStrokePressure, changed.pressure + Self.pumpPressureIncrement * intensity * falloff))
                return changed
            }
        case .magnet:
            let drag = dragDelta(to: point, from: previousPoint)
            mapCurrentFrame(layerIndex: layerIndex, frameIndex: frameIndexInLayer) { vectorPoint in
                let falloff = Self.influence(of: point, on: vectorPoint, radius: radius)
                return vectorPoint.translated(dx: drag.dx * falloff, dy: drag.dy * falloff)
            }
        case .bender:
            let drag = dragDelta(to: point, from: previousPoint)
            mapCurrentFrame(layerIndex: layerIndex, frameIndex: frameIndexInLayer) { vectorPoint in
                let falloff = Self.influence(of: point, on: vectorPoint, radius: radius)
                let phase = (vectorPoint.x - point.x) / max(radius, 1) * Double.pi
                return vectorPoint.translated(dx: drag.dx * Self.benderHorizontalTranslationFactor * falloff, dy: sin(phase) * drag.dy * falloff)
            }
        case .iron:
            smoothVectors(near: point, radius: radius, strength: Self.ironSmoothingStrength * intensity, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .cutter:
            cutNearestStroke(near: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndexInLayer)
        case .animate, .selection, .brush, .geometric, .type, .stylePicker, .rgbPicker, .hook, .zoom, .hand, .rotate:
            break
        }
    }

    public mutating func addRectangle(from start: VectorPoint, to end: VectorPoint) {
        let points = [
            start,
            VectorPoint(x: end.x, y: start.y, pressure: start.pressure),
            end,
            VectorPoint(x: start.x, y: end.y, pressure: end.pressure),
            start
        ]
        addStroke(VectorStroke(styleID: selectedStyleID, points: points, isClosed: true))
    }

    public mutating func addTextPlaceholder(at point: VectorPoint) {
        let width = 96.0
        let height = 36.0
        let start = VectorPoint(x: point.x, y: point.y, pressure: point.pressure)
        let end = VectorPoint(x: point.x + width, y: point.y + height, pressure: point.pressure)
        addRectangle(from: start, to: end)
    }

    public mutating func ensureFrame(layerID: UUID, frameIndex: Int) {
        guard let layerIndex = layers.firstIndex(where: { $0.id == layerID }) else { return }
        if !layers[layerIndex].frames.contains(where: { $0.index == frameIndex }) {
            layers[layerIndex].frames.append(VectorFrame(index: frameIndex))
            layers[layerIndex].frames.sort { $0.index < $1.index }
        }
    }

    public func frame(layerID: UUID, index: Int) -> VectorFrame? {
        layers.first { $0.id == layerID }?.frames.first { $0.index == index }
    }

    private static func influence(of center: VectorPoint, on point: VectorPoint, radius: Double) -> Double {
        guard radius > 0 else { return 0 }
        let distance = center.distance(to: point)
        guard distance <= radius else { return 0 }
        let normalized = 1 - distance / radius
        return normalized * normalized
    }

    private func dragDelta(to point: VectorPoint, from previousPoint: VectorPoint?) -> (dx: Double, dy: Double) {
        guard let previousPoint else { return (0, 0) }
        return (point.x - previousPoint.x, point.y - previousPoint.y)
    }

    private mutating func mapCurrentFrame(
        layerIndex: Int,
        frameIndex: Int,
        transform: (VectorPoint) -> VectorPoint
    ) {
        for strokeIndex in layers[layerIndex].frames[frameIndex].strokes.indices {
            layers[layerIndex].frames[frameIndex].strokes[strokeIndex].points = layers[layerIndex].frames[frameIndex].strokes[strokeIndex].points.map(transform)
        }
    }

    private mutating func eraseVectors(at point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) {
        for strokeIndex in layers[layerIndex].frames[frameIndex].strokes.indices {
            layers[layerIndex].frames[frameIndex].strokes[strokeIndex].points.removeAll { $0.distance(to: point) <= radius * Self.eraserRadiusScale }
        }
        layers[layerIndex].frames[frameIndex].strokes.removeAll { $0.points.count < 2 }
    }

    private mutating func closeNearestStroke(near point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) {
        guard let strokeIndex = nearestStrokeIndex(near: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndex) else { return }
        layers[layerIndex].frames[frameIndex].strokes[strokeIndex].isClosed = true
    }

    private mutating func moveNearestControlPoint(to point: VectorPoint, from previousPoint: VectorPoint?, radius: Double, layerIndex: Int, frameIndex: Int) {
        let target = previousPoint ?? point
        guard let nearest = nearestPointIndex(near: target, radius: radius, layerIndex: layerIndex, frameIndex: frameIndex) else { return }
        layers[layerIndex].frames[frameIndex].strokes[nearest.strokeIndex].points[nearest.pointIndex] = point
    }

    private mutating func smoothVectors(near point: VectorPoint, radius: Double, strength: Double, layerIndex: Int, frameIndex: Int) {
        let originalStrokes = layers[layerIndex].frames[frameIndex].strokes
        for strokeIndex in originalStrokes.indices {
            let points = originalStrokes[strokeIndex].points
            guard points.count > 2 else { continue }
            for pointIndex in points.indices.dropFirst().dropLast() {
                let current = points[pointIndex]
                let falloff = Self.influence(of: point, on: current, radius: radius)
                guard falloff > 0 else { continue }
                let previous = points[pointIndex - 1]
                let next = points[pointIndex + 1]
                let average = VectorPoint(
                    x: (previous.x + next.x) / 2,
                    y: (previous.y + next.y) / 2,
                    pressure: (previous.pressure + current.pressure + next.pressure) / 3
                )
                layers[layerIndex].frames[frameIndex].strokes[strokeIndex].points[pointIndex] = current.moved(toward: average, amount: min(1, strength * falloff))
            }
        }
    }

    private mutating func cutNearestStroke(near point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) {
        guard let nearest = nearestPointIndex(near: point, radius: radius, layerIndex: layerIndex, frameIndex: frameIndex) else { return }
        let stroke = layers[layerIndex].frames[frameIndex].strokes[nearest.strokeIndex]
        guard nearest.pointIndex > 0, nearest.pointIndex < stroke.points.count - 1 else { return }
        let firstPoints = Array(stroke.points[...nearest.pointIndex])
        let secondPoints = Array(stroke.points[nearest.pointIndex...])
        layers[layerIndex].frames[frameIndex].strokes[nearest.strokeIndex] = VectorStroke(styleID: stroke.styleID, points: firstPoints, isClosed: false)
        layers[layerIndex].frames[frameIndex].strokes.insert(VectorStroke(styleID: stroke.styleID, points: secondPoints, isClosed: false), at: nearest.strokeIndex + 1)
    }

    private mutating func tapeOpenVectorEnds(near point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) {
        let frame = layers[layerIndex].frames[frameIndex]
        var candidates: [(strokeIndex: Int, isStart: Bool, point: VectorPoint)] = []
        for strokeIndex in frame.strokes.indices {
            let stroke = frame.strokes[strokeIndex]
            guard !stroke.isClosed, let first = stroke.points.first, let last = stroke.points.last else { continue }
            if first.distance(to: point) <= radius { candidates.append((strokeIndex, true, first)) }
            if last.distance(to: point) <= radius { candidates.append((strokeIndex, false, last)) }
        }
        guard candidates.count >= 2 else { return }
        let pair = candidates.sorted { $0.point.distance(to: point) < $1.point.distance(to: point) }.prefix(2)
        let first = pair[pair.startIndex]
        let second = pair[pair.index(after: pair.startIndex)]
        guard first.strokeIndex != second.strokeIndex else { return }
        var firstStroke = frame.strokes[first.strokeIndex]
        var secondStroke = frame.strokes[second.strokeIndex]
        if first.isStart { firstStroke.points.reverse() }
        if !second.isStart { secondStroke.points.reverse() }
        firstStroke.points.append(contentsOf: secondStroke.points)
        let removeIndex = max(first.strokeIndex, second.strokeIndex)
        let replaceIndex = min(first.strokeIndex, second.strokeIndex)
        layers[layerIndex].frames[frameIndex].strokes[replaceIndex] = firstStroke
        layers[layerIndex].frames[frameIndex].strokes.remove(at: removeIndex)
    }

    private func nearestStrokeIndex(near point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) -> Int? {
        layers[layerIndex].frames[frameIndex].strokes.indices.min { left, right in
            distance(from: point, to: layers[layerIndex].frames[frameIndex].strokes[left]) < distance(from: point, to: layers[layerIndex].frames[frameIndex].strokes[right])
        }.flatMap { index in
            distance(from: point, to: layers[layerIndex].frames[frameIndex].strokes[index]) <= radius ? index : nil
        }
    }

    private func nearestPointIndex(near point: VectorPoint, radius: Double, layerIndex: Int, frameIndex: Int) -> (strokeIndex: Int, pointIndex: Int)? {
        var best: (strokeIndex: Int, pointIndex: Int, distance: Double)?
        for strokeIndex in layers[layerIndex].frames[frameIndex].strokes.indices {
            let stroke = layers[layerIndex].frames[frameIndex].strokes[strokeIndex]
            for pointIndex in stroke.points.indices {
                let distance = stroke.points[pointIndex].distance(to: point)
                if distance <= radius, best.map({ distance < $0.distance }) ?? true {
                    best = (strokeIndex, pointIndex, distance)
                }
            }
        }
        guard let best else { return nil }
        return (best.strokeIndex, best.pointIndex)
    }

    private func distance(from point: VectorPoint, to stroke: VectorStroke) -> Double {
        stroke.points.map { $0.distance(to: point) }.min() ?? .infinity
    }
}
