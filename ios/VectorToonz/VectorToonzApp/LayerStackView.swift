import SwiftUI

struct LayerStackView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vector Layers")
                    .font(.headline)
                Spacer()
                Button {
                    store.addLayer()
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
            }

            ForEach(store.document.layers) { layer in
                HStack(spacing: 12) {
                    Button {
                        store.toggleLayerVisibility(layer.id)
                    } label: {
                        Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                    }
                    Button {
                        store.selectLayer(layer.id)
                    } label: {
                        HStack {
                            Text(layer.name)
                                .font(.body.weight(store.document.selectedLayerID == layer.id ? .semibold : .regular))
                            Spacer()
                            Text("\(layer.frames.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(store.document.selectedLayerID == layer.id ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}
