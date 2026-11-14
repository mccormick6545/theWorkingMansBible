// SPDX-License-Identifier: Apache-2.0
import SwiftUI
import UniformTypeIdentifiers

/// The parts catalog: categories, a searchable list and part details. Three columns on iPad and Mac,
/// a navigation stack on iPhone.
public struct PartsCatalogView: View {
    @State private var store: PartsCatalogStore
    @State private var scope: CatalogScope? = .all
    @State private var selectedPartID: String?
    @State private var query = ""
    @State private var importing = false
    @State private var importMessage: String?
    @State private var errorMessage: String?

    /// - Parameter store: Defaults to the catalog saved in this app's Application Support folder.
    @MainActor
    public init(store: PartsCatalogStore? = nil) {
        _store = State(initialValue: store ?? PartsCatalogStore())
    }

    private struct SearchKey: Hashable {
        let query: String
        let scope: CatalogScope?
        let totalCount: Int
        let favorites: Set<String>
    }

    public var body: some View {
        NavigationSplitView {
            List(selection: $scope) {
                Section("Library") {
                    Label("All Parts", systemImage: "shippingbox").tag(CatalogScope.all)
                    Label("Favorites", systemImage: "star").tag(CatalogScope.favorites)
                }
                if !store.categories.isEmpty {
                    Section("Categories") {
                        ForEach(store.categories, id: \.self) { category in
                            Label(category, systemImage: "folder").tag(CatalogScope.category(category))
                        }
                    }
                }
            }
            .navigationTitle("Parts Catalog")
            .toolbar {
                ToolbarItem {
                    Button("Import Catalog", systemImage: "square.and.arrow.down") { importing = true }
                        .disabled(store.loadError != nil)
                }
            }
        } content: {
            PartsList(store: store, selection: $selectedPartID)
                .searchable(text: $query, prompt: "Name, manufacturer or part number")
                .navigationTitle(title)
                .overlay { emptyState }
        } detail: {
            if let id = selectedPartID, let part = store.part(id: id) {
                PartDetailView(part: part, isFavorite: store.isFavorite(id)) { store.toggleFavorite(id) }
            } else {
                ContentUnavailableView("Select a Part", systemImage: "shippingbox",
                                       description: Text("Details, specifications and sources appear here."))
            }
        }
        .task { await store.load() }
        .task(id: SearchKey(query: query, scope: scope, totalCount: store.totalCount, favorites: store.favoriteIDs)) {
            // Brief pause so each keystroke doesn't start its own search.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            await store.refresh(query: query, scope: scope ?? .all)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            Task { await importFile(result) }
        }
        .alert("Catalog Imported", isPresented: Binding(
            get: { importMessage != nil }, set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK") { importMessage = nil }
        } message: { Text(importMessage ?? "") }
        .alert("Import Failed", isPresented: Binding(
            get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var title: String {
        switch scope ?? .all {
        case .all: "All Parts"
        case .favorites: "Favorites"
        case .category(let name): name
        }
    }

    @ViewBuilder private var emptyState: some View {
        if let loadError = store.loadError {
            ContentUnavailableView("Catalog Unavailable", systemImage: "exclamationmark.triangle",
                                   description: Text(loadError))
        } else if store.isLoaded, store.totalCount == 0 {
            ContentUnavailableView {
                Label("No Parts Yet", systemImage: "shippingbox")
            } description: {
                Text("Import a parts catalog file (JSON). Every record must name its source and license and have recorded permission to redistribute. No third-party catalog is bundled with the app.")
            } actions: {
                Button("Import Catalog") { importing = true }
            }
        } else if store.isLoaded, store.results.isEmpty {
            if !query.isEmpty {
                ContentUnavailableView.search(text: query)
            } else if scope == .favorites {
                ContentUnavailableView("No Favorites", systemImage: "star",
                                       description: Text("Tap the star on a part to keep it here."))
            }
        }
    }

    private func importFile(_ result: Result<URL, Error>) async {
        do {
            let url = try result.get()
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            let added = try await store.importCatalog(Data(contentsOf: url))
            importMessage = "Added \(added) \(added == 1 ? "part" : "parts")."
        } catch {
            errorMessage = PartsCatalogStore.message(for: error)
        }
    }
}

private struct PartsList: View {
    let store: PartsCatalogStore
    @Binding var selection: String?

    var body: some View {
        List(store.results, selection: $selection) { part in
            PartRow(part: part, isFavorite: store.isFavorite(part.id))
        }
    }
}

private struct PartRow: View {
    let part: CatalogPart
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(part.name).font(.headline)
                let maker = [part.manufacturer, part.manufacturerPartNumber].compactMap { $0 }.joined(separator: " · ")
                if !maker.isEmpty {
                    Text(maker).font(.subheadline).foregroundStyle(.secondary)
                }
                Text(part.category).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Favorite")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Empty catalog") {
    PartsCatalogView(store: PartsCatalogStore(
        folder: FileManager.default.temporaryDirectory.appending(path: "PreviewCatalog-\(UUID().uuidString)"),
        defaults: UserDefaults(suiteName: "preview") ?? .standard))
}
