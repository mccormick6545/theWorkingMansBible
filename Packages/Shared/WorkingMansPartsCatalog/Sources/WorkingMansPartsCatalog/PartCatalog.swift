// SPDX-License-Identifier: Apache-2.0
import Foundation

/// Offline searchable catalog. JSON persistence starts the project; a future
/// SQLite adapter can implement the same higher-level catalog interface.
public actor PartCatalog {
    private var parts: [String: CatalogPart] = [:]

    public init() {}

    public func count() -> Int { parts.count }

    public func part(id: String) -> CatalogPart? { parts[id] }

    public func allParts() -> [CatalogPart] {
        parts.values.sorted { $0.id < $1.id }
    }

    /// Imports only redistributable records and assets; entire batch is atomic.
    public func importRedistributable(_ records: [CatalogPart]) throws {
        var incoming = Set<String>()
        for record in records {
            guard !record.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !record.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !record.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  !record.source.publisher.isEmpty,
                  !record.source.licenseIdentifier.isEmpty else {
                throw CatalogError.invalidRecord(record.id)
            }
            guard incoming.insert(record.id).inserted, parts[record.id] == nil else {
                throw CatalogError.duplicateIdentifier(record.id)
            }
            guard record.source.redistributionApproved,
                  record.assets.allSatisfy({ $0.redistributionApproved }) else {
                throw CatalogError.redistributionNotApproved(record.id)
            }
        }
        for record in records { parts[record.id] = record }
    }

    public func search(_ query: String, category: String? = nil) -> [CatalogPart] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return parts.values.filter { part in
            let categoryMatches = category.map { part.category.localizedCaseInsensitiveCompare($0) == .orderedSame } ?? true
            guard categoryMatches else { return false }
            guard !needle.isEmpty else { return true }
            let text = ([part.id, part.name, part.category, part.manufacturer ?? "",
                         part.manufacturerPartNumber ?? "", part.description] +
                        part.specifications.flatMap { [$0.key, $0.value] })
            return text.contains { $0.localizedStandardContains(needle) }
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public func exportJSON(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(allParts())
    }

    public func importJSON(_ data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        try importRedistributable(decoder.decode([CatalogPart].self, from: data))
    }
}
