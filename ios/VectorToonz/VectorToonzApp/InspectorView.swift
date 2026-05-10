import SwiftUI

struct InspectorView: View {
    @EnvironmentObject private var store: DocumentStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Document") {
                    TextField("Title", text: $store.document.title)
                    Stepper("Frame Rate: \(store.document.frameRate) fps", value: $store.document.frameRate, in: 12...60)
                }

                Section("Palette") {
                    ForEach(store.document.palette) { style in
                        Button {
                            store.document.selectedStyleID = style.id
                            store.save()
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(red: style.red, green: style.green, blue: style.blue, opacity: style.alpha))
                                    .frame(width: 28, height: 28)
                                Text(style.name)
                                Spacer()
                                if style.id == store.document.selectedStyleID {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section("Scope") {
                    Label("Vector layers only", systemImage: "checkmark.seal")
                    Label("Raster brushes, raster levels, plastic, and rigging are intentionally absent", systemImage: "nosign")
                }
            }
            .navigationTitle("Inspector")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
