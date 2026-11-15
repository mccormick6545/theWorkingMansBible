// SPDX-License-Identifier: Apache-2.0
import Foundation
import Testing
@testable import WorkingMansCore

struct CatalogDatasetTests {
    /// Fictional fixture data – not real vehicle records.
    private func source(license: String = "CC0-1.0", url: String = "https://example.org/data") -> DataSource {
        DataSource(publisher: "Example", url: url, license: license, attribution: "", retrievedOn: "2026-11-14")
    }

    private func vehicle(id: String = "v1", from: Int? = 1990, to: Int? = 1995,
                         source: DataSource = DataSource(publisher: "Example", url: "https://example.org/data",
                                                         license: "CC0-1.0", attribution: "", retrievedOn: "2026-11-14")) -> VehicleRecord {
        VehicleRecord(id: id, category: .car, make: "Example", model: "Model A", yearFrom: from, yearTo: to, source: source)
    }

    private func json(_ dataset: CatalogDataset) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(dataset)
    }

    @Test func emptyPlaceholderLoads() throws {
        let data = Data(#"{"schemaVersion":1,"generatedAt":"2026-11-14T00:00:00Z","vehicles":[]}"#.utf8)
        let dataset = try CatalogDataset.decode(data)
        #expect(dataset.vehicles.isEmpty)
    }

    @Test func validRecordRoundTrips() throws {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z", vehicles: [vehicle()])
        let loaded = try CatalogDataset.decode(try json(dataset))
        #expect(loaded == dataset)
    }

    @Test func rejectsMissingLicense() throws {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z",
                                     vehicles: [vehicle(id: "bad", source: source(license: "  "))])
        #expect(throws: CatalogDataError.missingLicense("bad")) {
            try CatalogDataset.decode(try json(dataset))
        }
    }

    @Test func rejectsInsecureSource() throws {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z",
                                     vehicles: [vehicle(id: "http", source: source(url: "http://example.org"))])
        #expect(throws: CatalogDataError.invalidURL("http")) {
            try dataset.validate()
        }
    }

    @Test func rejectsDuplicateIDs() {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z", vehicles: [vehicle(id: "same"), vehicle(id: "same")])
        #expect(throws: CatalogDataError.duplicateID("same")) {
            try dataset.validate()
        }
    }

    @Test func rejectsEndYearBeforeStartYear() {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z", vehicles: [vehicle(id: "years", from: 2000, to: 1990)])
        #expect(throws: CatalogDataError.invalidYears("years")) {
            try dataset.validate()
        }
    }

    @Test func refusesNewerSchema() throws {
        let dataset = CatalogDataset(schemaVersion: 99, generatedAt: "2026-11-14T00:00:00Z", vehicles: [])
        #expect(throws: CatalogDataError.unsupportedSchema(99)) {
            try CatalogDataset.decode(try json(dataset))
        }
    }

    @Test func rejectsMalformedJSON() {
        #expect(throws: CatalogDataError.self) {
            try CatalogDataset.decode(Data("not json".utf8))
        }
    }

    @Test func allowsUnknownYears() throws {
        let dataset = CatalogDataset(generatedAt: "2026-11-14T00:00:00Z", vehicles: [vehicle(id: "unknown", from: nil, to: nil)])
        try dataset.validate()
    }
}
