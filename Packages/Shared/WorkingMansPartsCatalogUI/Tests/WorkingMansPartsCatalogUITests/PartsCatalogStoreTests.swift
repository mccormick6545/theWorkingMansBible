// SPDX-License-Identifier: Apache-2.0
import Foundation
import Testing
@testable import WorkingMansPartsCatalogUI

@MainActor
struct PartsCatalogStoreTests {
    private let folder = FileManager.default.temporaryDirectory.appending(path: "CatalogStoreTests-\(UUID().uuidString)")
    private let defaults = UserDefaults(suiteName: "CatalogStoreTests-\(UUID().uuidString)")!

    private func store() -> PartsCatalogStore { PartsCatalogStore(folder: folder, defaults: defaults) }

    /// Fictional fixture data – not real parts or specifications.
    private func json(_ parts: [(id: String, name: String, category: String, approved: Bool)]) -> Data {
        let records = parts.map { part in
            """
            {"id":"\(part.id)","name":"\(part.name)","category":"\(part.category)","manufacturer":"Example Co",
             "manufacturerPartNumber":"EX-\(part.id)","description":"Fictional test fixture","specifications":{"thread":"M8"},
             "source":{"publisher":"Example contributor","sourceURL":"https://example.org/\(part.id)",
                       "licenseIdentifier":"CC0-1.0","attribution":"Example contributor","redistributionApproved":\(part.approved)},
             "assets":[]}
            """
        }
        return Data("[\(records.joined(separator: ","))]".utf8)
    }

    @Test func emptyCatalogLoads() async {
        let store = store()
        await store.load()
        #expect(store.isLoaded)
        #expect(store.totalCount == 0)
        #expect(store.loadError == nil)
    }

    @Test func importSavesAndReloads() async throws {
        let first = store()
        await first.load()
        let added = try await first.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true),
                                                         ("valve", "Example Ball Valve", "Plumbing", true)]))
        #expect(added == 2)
        #expect(first.categories == ["Fasteners", "Plumbing"])

        let reopened = store()
        await reopened.load()
        #expect(reopened.totalCount == 2)
        #expect(reopened.part(id: "valve")?.name == "Example Ball Valve")
    }

    @Test func importAddsToExistingCatalog() async throws {
        let store = store()
        await store.load()
        try await store.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true)]))
        try await store.importCatalog(json([("nut", "Example Hex Nut", "Fasteners", true)]))
        #expect(store.totalCount == 2)
    }

    @Test func rejectsUnapprovedAndDuplicateRecords() async throws {
        let store = store()
        await store.load()
        try await store.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true)]))
        await #expect(throws: CatalogError.redistributionNotApproved("blocked")) {
            try await store.importCatalog(json([("ok", "Example Washer", "Fasteners", true),
                                                ("blocked", "Example Blocked", "Fasteners", false)]))
        }
        await #expect(throws: CatalogError.duplicateIdentifier("bolt")) {
            try await store.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true)]))
        }
        // Rejected files change nothing.
        #expect(store.totalCount == 1)
    }

    @Test func searchesByPartNumberAndScope() async throws {
        let store = store()
        await store.load()
        try await store.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true),
                                            ("valve", "Example Ball Valve", "Plumbing", true)]))
        await store.refresh(query: "EX-valve", scope: .all)
        #expect(store.results.map(\.id) == ["valve"])
        await store.refresh(query: "", scope: .category("Fasteners"))
        #expect(store.results.map(\.id) == ["bolt"])
        await store.refresh(query: "", scope: .favorites)
        #expect(store.results.isEmpty)
    }

    @Test func favoritesPersist() async throws {
        let first = store()
        await first.load()
        try await first.importCatalog(json([("bolt", "Example Hex Bolt", "Fasteners", true)]))
        first.toggleFavorite("bolt")
        await first.refresh(query: "", scope: .favorites)
        #expect(first.results.map(\.id) == ["bolt"])

        let reopened = store()
        #expect(reopened.isFavorite("bolt"))
        reopened.toggleFavorite("bolt")
        #expect(!reopened.isFavorite("bolt"))
    }

    @Test func malformedFileIsRejected() async {
        let store = store()
        await store.load()
        await #expect(throws: DecodingError.self) { try await store.importCatalog(Data("not json".utf8)) }
        #expect(PartsCatalogStore.message(for: CatalogError.invalidRecord("x")).contains("Nothing was imported"))
    }
}
