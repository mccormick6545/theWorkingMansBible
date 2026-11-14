// SPDX-License-Identifier: Apache-2.0
import Foundation
import XCTest
@testable import WorkingMansPartsCatalog

final class PartCatalogTests: XCTestCase {
    private func part(id: String = "bolt-001", approved: Bool = true, assetApproved: Bool = true) -> CatalogPart {
        let source = PartProvenance(
            publisher: "Example original contributor",
            sourceURL: URL(string: "https://example.org/parts/bolt")!,
            licenseIdentifier: "CC0-1.0", attribution: "Example original contributor",
            redistributionApproved: approved
        )
        return CatalogPart(
            id: id, name: "Example M8 Hex Bolt", category: "Fasteners",
            manufacturerPartNumber: "M8-EXAMPLE",
            description: "Fictional test fixture; not an actual specification",
            specifications: ["thread": "M8"], source: source,
            assets: [PartAsset(id: "drawing-1", kind: .drawing,
                               url: URL(string: "https://example.org/drawing")!,
                               licenseIdentifier: "CC0-1.0",
                               attribution: "Example original contributor",
                               redistributionApproved: assetApproved)]
        )
    }

    func testImportAndSearch() async throws {
        let catalog = PartCatalog()
        try await catalog.importRedistributable([part()])
        let found = await catalog.search("M8", category: "Fasteners")
        XCTAssertEqual(found.count, 1)
        let wrongCategory = await catalog.search("M8", category: "Plumbing")
        XCTAssertTrue(wrongCategory.isEmpty)
    }

    func testRejectUnlicensedDataAndAssets() async throws {
        let catalog = PartCatalog()
        do {
            try await catalog.importRedistributable([part(approved: false)])
            XCTFail("Must reject unlicensed sources")
        } catch CatalogError.redistributionNotApproved { } catch { throw error }
        do {
            try await catalog.importRedistributable([part(assetApproved: false)])
            XCTFail("Must reject unlicensed assets")
        } catch CatalogError.redistributionNotApproved { } catch { throw error }
        let count = await catalog.count()
        XCTAssertEqual(count, 0)
    }

    func testAtomicBatchAndDuplicateID() async throws {
        let catalog = PartCatalog()
        do {
            try await catalog.importRedistributable([part(), part(id: "blocked", approved: false)])
            XCTFail("Entire batch should fail")
        } catch CatalogError.redistributionNotApproved { } catch { throw error }
        let count = await catalog.count()
        XCTAssertEqual(count, 0)
        do {
            try await catalog.importRedistributable([part(), part()])
            XCTFail("Duplicate identifiers should fail")
        } catch CatalogError.duplicateIdentifier { } catch { throw error }
    }

    func testJSONRoundTrip() async throws {
        let catalog = PartCatalog()
        try await catalog.importRedistributable([part()])
        let json = try await catalog.exportJSON()
        let restored = PartCatalog()
        try await restored.importJSON(json)
        let count = await restored.count()
        XCTAssertEqual(count, 1)
    }
}
