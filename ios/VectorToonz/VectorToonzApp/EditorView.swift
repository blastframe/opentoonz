import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var store: DocumentStore
    @State private var showingInspector = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground).ignoresSafeArea()

                VectorCanvasView()
                    .environmentObject(store)
                    .padding(.bottom, 118)
                    .padding(.trailing, 280)

                VStack {
                    HStack(alignment: .top) {
                        ToolPaletteView(selectedTool: $store.selectedTool)
                            .padding(.leading, 16)
                            .padding(.top, 16)
                        Spacer()
                        LayerStackView()
                            .environmentObject(store)
                            .frame(width: 260)
                            .padding(.trailing, 16)
                            .padding(.top, 16)
                    }
                    Spacer()
                    TimelineView()
                        .environmentObject(store)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
            }
            .navigationTitle(store.document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingInspector = true
                    } label: {
                        Label("Inspector", systemImage: "slider.horizontal.3")
                    }
                    Button {
                        store.save()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
            }
            .sheet(isPresented: $showingInspector) {
                InspectorView()
                    .environmentObject(store)
                    .presentationDetents([.medium])
            }
            .onAppear { store.load() }
        }
    }
}
