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
