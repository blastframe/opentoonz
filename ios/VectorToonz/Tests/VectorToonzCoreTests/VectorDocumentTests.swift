import Testing
@testable import VectorToonzCore

@Test func newDocumentIsVectorOnly() {
    let document = VectorDocument()

    #expect(document.layers.count == 1)
    #expect(document.layers[0].name == "Vector Layer 1")
    #expect(document.layers[0].frames[0].strokes.isEmpty)
    #expect(VectorTool.allCases.map(\.rawValue).contains("brush"))
    #expect(!VectorTool.allCases.map(\.rawValue).contains("plastic"))
}

@Test func vectorToolSetIncludesOpenToonzStyleVectorTools() {
    let tools = Set(VectorTool.allCases.map(\.rawValue))
    let expectedTools: Set<String> = [
        "animate", "selection", "brush", "geometric", "type", "fill", "eraser", "tape",
        "stylePicker", "rgbPicker", "controlPoint", "pinch", "pump", "magnet", "bender",
        "iron", "cutter", "hook", "zoom", "hand", "rotate"
    ]

    #expect(expectedTools.isSubset(of: tools))
}

@Test func addingStrokeTargetsSelectedLayerAndFrame() {
    var document = VectorDocument()
    let stroke = VectorStroke(
        styleID: document.selectedStyleID,
        points: [VectorPoint(x: 0, y: 0), VectorPoint(x: 10, y: 12, pressure: 0.7)]
    )

    document.addStroke(stroke)

    let frame = document.frame(layerID: document.selectedLayerID, index: 0)
    #expect(frame?.strokes == [stroke])
}

@Test func duplicateFrameCopiesVectorStrokesToNextFrame() {
    var document = VectorDocument()
    let stroke = VectorStroke(styleID: document.selectedStyleID, points: [VectorPoint(x: 1, y: 2)])
    document.addStroke(stroke)

    document.duplicateCurrentFrame()

    #expect(document.currentFrameIndex == 1)
    #expect(document.frame(layerID: document.selectedLayerID, index: 1)?.strokes == [stroke])
}

@Test func pumpToolIncreasesNearbyVectorPressure() throws {
    var document = VectorDocument()
    document.addStroke(VectorStroke(styleID: document.selectedStyleID, points: [
        VectorPoint(x: 0, y: 0, pressure: 1),
        VectorPoint(x: 10, y: 0, pressure: 1)
    ]))

    document.apply(tool: .pump, at: VectorPoint(x: 0, y: 0), radius: 24)

    let pressure = try #require(document.frame(layerID: document.selectedLayerID, index: 0)?.strokes[0].points[0].pressure)
    #expect(pressure > 1)
}

@Test func magnetToolMovesNearbyVectorPoints() throws {
    var document = VectorDocument()
    document.addStroke(VectorStroke(styleID: document.selectedStyleID, points: [
        VectorPoint(x: 0, y: 0),
        VectorPoint(x: 10, y: 0)
    ]))

    document.apply(tool: .magnet, at: VectorPoint(x: 20, y: 0), from: VectorPoint(x: 0, y: 0), radius: 48)

    let movedX = try #require(document.frame(layerID: document.selectedLayerID, index: 0)?.strokes[0].points[0].x)
    #expect(movedX > 0)
}

@Test func cutterToolSplitsVectorStroke() throws {
    var document = VectorDocument()
    document.addStroke(VectorStroke(styleID: document.selectedStyleID, points: [
        VectorPoint(x: 0, y: 0),
        VectorPoint(x: 10, y: 0),
        VectorPoint(x: 20, y: 0)
    ]))

    document.apply(tool: .cutter, at: VectorPoint(x: 10, y: 0), radius: 12)

    let strokes = try #require(document.frame(layerID: document.selectedLayerID, index: 0)?.strokes)
    #expect(strokes.count == 2)
}


@Test func emptyPaletteFallsBackToDefaultStyle() {
    var document = VectorDocument(palette: [])
    document.palette.removeAll()

    #expect(document.selectedStyle.name == "Ink")
}
