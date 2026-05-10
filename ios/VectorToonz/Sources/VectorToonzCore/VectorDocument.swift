import Foundation

public enum VectorTool: String, CaseIterable, Codable, Identifiable, Sendable {
    case brush
    case eraser
    case selection
    case controlPoint
    case fill
    case geometric
    case stylePicker

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .brush: "Brush"
        case .eraser: "Eraser"
        case .selection: "Select"
        case .controlPoint: "Points"
        case .fill: "Fill"
        case .geometric: "Shape"
        case .stylePicker: "Picker"
        }
    }

    public var systemImageName: String {
        switch self {
        case .brush: "pencil.tip"
        case .eraser: "eraser"
        case .selection: "cursorarrow.motionlines"
        case .controlPoint: "point.topleft.down.curvedto.point.bottomright.up"
        case .fill: "paintpalette"
        case .geometric: "square.on.circle"
        case .stylePicker: "eyedropper"
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
        let defaultStyle = VectorStyle(name: "Ink", red: 0.05, green: 0.05, blue: 0.08, width: 5.0)
        let styleList = palette ?? [
            defaultStyle,
            VectorStyle(name: "Blue", red: 0.10, green: 0.38, blue: 0.90, width: 5.0),
            VectorStyle(name: "Fill", red: 1.00, green: 0.76, blue: 0.20, width: 2.0)
        ]
        let layerID = selectedLayerID ?? UUID()
        self.id = id
        self.title = title
        self.frameRate = frameRate
        self.currentFrameIndex = currentFrameIndex
        self.selectedLayerID = layerID
        self.selectedStyleID = selectedStyleID ?? styleList[0].id
        self.layers = layers ?? [VectorLayer(id: layerID, name: "Vector Layer 1", frames: [VectorFrame(index: 0)])]
        self.palette = styleList
    }

    public var selectedLayer: VectorLayer? {
        layers.first { $0.id == selectedLayerID }
    }

    public var selectedStyle: VectorStyle {
        palette.first { $0.id == selectedStyleID } ?? palette[0]
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
}
