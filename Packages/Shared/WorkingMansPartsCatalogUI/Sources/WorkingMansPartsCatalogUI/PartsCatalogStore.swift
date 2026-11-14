// SPDX-License-Identifier: Apache-2.0
import Foundation
import Observation
@_exported import WorkingMansPartsCatalog

/// Which parts the list shows.
public enum CatalogScope: Hashable, Sendable {
    case all
    case favorites
    case category(String)
}

/// Keeps the offline catalog on this device and drives the catalog screens. The catalog is saved as JSON in
/// Application Support; only records with recorded redistribution rights can be imported.
@MainActor
@Observable
public final class PartsCatalogStore {
    /// Parts matching the current search and scope, sorted by name.
    public private(set) var results: [CatalogPart] = []
    public private(set) var categories: [String] = []
    public private(set) var totalCount = 0
    public private(set) var favoriteIDs: Set<String>
    /// Set when the saved catalog couldn't be read. Imports are refused so the saved file isn't overwritten.
    public private(set) var loadError: String?
    public private(set) var isLoaded = false

    private var catalog = PartCatalog()
    private var partsByID: [String: CatalogPart] = [:]
    private let folder: URL
    private let defaults: UserDefaults
    private static let favoritesKey = "partsCatalog.favoriteIDs"

    private var fileURL: URL { folder.appending(path: "catalog.json") }

    public init(folder: URL = URL.applicationSupportDirectory.appending(path: "PartsCatalog", directoryHint: .isDirectory),
                defaults: UserDefaults = .standard) {
        self.folder = folder
        self.defaults = defaults
        favoriteIDs = Set(defaults.stringArray(forKey: Self.favoritesKey) ?? [])
    }

    /// Reads the saved catalog. Safe to call more than once.
    public func load() async {
        guard !isLoaded else { return }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let fresh = PartCatalog()
                try await fresh.importJSON(Data(contentsOf: fileURL))
                catalog = fresh
            }
        } catch {
            loadError = "The saved parts catalog could not be opened. \(Self.message(for: error))"
        }
        await snapshot()
        isLoaded = true
    }

    /// Adds every record in a catalog JSON file. The whole file is rejected if any record lacks a source,
    /// license or redistribution approval, or duplicates a part already in the catalog.
    /// - Returns: The number of parts added.
    @discardableResult
    public func importCatalog(_ data: Data) async throws -> Int {
        guard loadError == nil else { throw CatalogStoreError.catalogUnavailable }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let incoming = try decoder.decode([CatalogPart].self, from: data)
        let merged = PartCatalog()
        try await merged.importRedistributable(await catalog.allParts() + incoming)
        let json = try await merged.exportJSON(prettyPrinted: false)
        try json.write(to: fileURL, options: .atomic)
        catalog = merged
        await snapshot()
        return incoming.count
    }

    /// The saved catalog, for sharing or backup.
    public func exportCatalog() async throws -> Data {
        try await catalog.exportJSON()
    }

    public func part(id: String) -> CatalogPart? { partsByID[id] }

    /// Updates `results` for a search within a scope. Manufacturer, part number and specifications are searched too.
    public func refresh(query: String, scope: CatalogScope) async {
        let category: String? = if case .category(let name) = scope { name } else { nil }
        var found = await catalog.search(query, category: category)
        if scope == .favorites { found = found.filter { favoriteIDs.contains($0.id) } }
        results = found
    }

    public func isFavorite(_ id: String) -> Bool { favoriteIDs.contains(id) }

    public func toggleFavorite(_ id: String) {
        if favoriteIDs.contains(id) { favoriteIDs.remove(id) } else { favoriteIDs.insert(id) }
        defaults.set(favoriteIDs.sorted(), forKey: Self.favoritesKey)
    }

    private func snapshot() async {
        let parts = await catalog.allParts()
        partsByID = Dictionary(uniqueKeysWithValues: parts.map { ($0.id, $0) })
        categories = Set(parts.map(\.category)).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        totalCount = parts.count
    }

    /// A readable explanation for catalog, decoding and file errors.
    public static func message(for error: Error) -> String {
        switch error {
        case CatalogError.duplicateIdentifier(let id):
            "A part with ID “\(id)” is already in the catalog or appears twice in the file. Nothing was imported."
        case CatalogError.invalidRecord(let id):
            "Record “\(id)” is missing its ID, name, category, publisher or license. Nothing was imported."
        case CatalogError.redistributionNotApproved(let id):
            "Record “\(id)” or one of its files doesn't have recorded permission to redistribute. Nothing was imported."
        case is DecodingError:
            "The file isn't a parts catalog in the expected JSON format. Nothing was imported."
        case let error as CatalogStoreError:
            error.localizedDescription
        default:
            error.localizedDescription
        }
    }
}

public enum CatalogStoreError: LocalizedError {
    case catalogUnavailable

    public var errorDescription: String? {
        switch self {
        case .catalogUnavailable: "The saved catalog couldn't be opened, so imports are paused to protect it."
        }
    }
}
