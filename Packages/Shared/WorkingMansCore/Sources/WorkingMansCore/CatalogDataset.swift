// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A versioned data file the app loads: vehicles today, parts and guides later.
///
/// Every record names its source and the license it may be used under. A file with a record that lacks a
/// source or license is rejected as a whole, so unlicensed data can't reach users by accident. This file format
/// is open; the data in it is not. Only add records whose license you have checked.
public struct CatalogDataset: Codable, Sendable, Equatable {
    /// The newest format this app understands. Older files still load; newer ones are refused with a clear error.
    public static let supportedSchemaVersion = 1

    public let schemaVersion: Int
    /// When this file was built, as an ISO-8601 date-time string.
    public let generatedAt: String
    public let vehicles: [VehicleRecord]

    public init(schemaVersion: Int = CatalogDataset.supportedSchemaVersion, generatedAt: String, vehicles: [VehicleRecord]) {
        self.schemaVersion = schemaVersion
        self.generatedAt = generatedAt
        self.vehicles = vehicles
    }

    /// Decodes and checks a catalog file. Throws `CatalogDataError` for anything the app shouldn't use.
    public static func decode(_ data: Data) throws -> CatalogDataset {
        let dataset: CatalogDataset
        do {
            dataset = try JSONDecoder().decode(CatalogDataset.self, from: data)
        } catch {
            throw CatalogDataError.malformed(error.localizedDescription)
        }
        try dataset.validate()
        return dataset
    }

    /// Checks every rule the app relies on. Called by `decode`; call it directly for files built in code.
    public func validate() throws {
        guard schemaVersion >= 1, schemaVersion <= Self.supportedSchemaVersion else {
            throw CatalogDataError.unsupportedSchema(schemaVersion)
        }
        var seen = Set<String>()
        for vehicle in vehicles {
            guard !vehicle.id.trimmingCharacters(in: .whitespaces).isEmpty,
                  !vehicle.make.trimmingCharacters(in: .whitespaces).isEmpty,
                  !vehicle.model.trimmingCharacters(in: .whitespaces).isEmpty else {
                throw CatalogDataError.incompleteRecord(vehicle.id)
            }
            guard seen.insert(vehicle.id).inserted else {
                throw CatalogDataError.duplicateID(vehicle.id)
            }
            if let from = vehicle.yearFrom, let to = vehicle.yearTo, from > to {
                throw CatalogDataError.invalidYears(vehicle.id)
            }
            try vehicle.source.validate(recordID: vehicle.id)
        }
    }
}

/// One vehicle model and the years it was made.
public struct VehicleRecord: Codable, Sendable, Equatable, Identifiable {
    public enum Category: String, Codable, Sendable, CaseIterable {
        case car, truck, suv, motorcycle, dirtBike, atv, utv, mountainBike, scooter, skateboard
        case heavyEquipment, trailer, boat, lawnAndGarden, smallEngine
    }

    public let id: String
    public let category: Category
    public let make: String
    public let model: String
    /// First model year. `nil` when unknown; those records are still shown, labeled as such.
    public let yearFrom: Int?
    /// Last model year. `nil` when the model is still in production or the end year is unknown.
    public let yearTo: Int?
    public let source: DataSource

    public init(id: String, category: Category, make: String, model: String,
                yearFrom: Int?, yearTo: Int?, source: DataSource) {
        self.id = id
        self.category = category
        self.make = make
        self.model = model
        self.yearFrom = yearFrom
        self.yearTo = yearTo
        self.source = source
    }
}

/// Where a record came from and what it's licensed for. Required on every record.
public struct DataSource: Codable, Sendable, Equatable, Hashable {
    /// Who published the data, e.g. "NHTSA" or "Wikidata".
    public let publisher: String
    /// The page or file the record was taken from. Must be https.
    public let url: String
    /// A reviewed Basic license identifier, e.g. "CC0-1.0" or "CC-BY-4.0".
    /// Proprietary agreements and unverified government-work claims must not enter Basic.
    public let license: String
    /// Credit text the license requires, shown wherever the record is used. May be empty if none is required.
    public let attribution: String
    /// The date the data was retrieved, as YYYY-MM-DD.
    public let retrievedOn: String

    public init(publisher: String, url: String, license: String, attribution: String, retrievedOn: String) {
        self.publisher = publisher
        self.url = url
        self.license = license
        self.attribution = attribution
        self.retrievedOn = retrievedOn
    }

    func validate(recordID: String) throws {
        guard !publisher.trimmingCharacters(in: .whitespaces).isEmpty,
              !license.trimmingCharacters(in: .whitespaces).isEmpty,
              !retrievedOn.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw CatalogDataError.missingLicense(recordID)
        }
        guard let link = URL(string: url), link.scheme == "https", link.host != nil else {
            throw CatalogDataError.invalidURL(recordID)
        }
        // A license being present is NOT evidence it permits commercial reuse.
        try BasicLicensePolicy.validate(self, recordID: recordID)
    }
}

public enum CatalogDataError: LocalizedError, Equatable {
    case malformed(String)
    case unsupportedSchema(Int)
    case incompleteRecord(String)
    case missingLicense(String)
    case invalidURL(String)
    case duplicateID(String)
    case invalidYears(String)
    case unsupportedLicense(String, String)
    case missingAttribution(String)

    public var errorDescription: String? {
        switch self {
        case .malformed(let detail): "The catalog file isn't in the expected format. \(detail)"
        case .unsupportedSchema(let version): "This catalog needs a newer version of the app (format \(version))."
        case .incompleteRecord(let id): "Record “\(id)” is missing its ID, make or model. The catalog wasn't loaded."
        case .missingLicense(let id): "Record “\(id)” has no source or license. The catalog wasn't loaded."
        case .invalidURL(let id): "Record “\(id)” needs a secure (https) source link. The catalog wasn't loaded."
        case .duplicateID(let id): "Record “\(id)” appears more than once. The catalog wasn't loaded."
        case .invalidYears(let id): "Record “\(id)” ends before it starts. The catalog wasn't loaded."
        case .unsupportedLicense(let id, let license): "Record “\(id)” uses a license not approved for Basic: \(license). The catalog wasn't loaded."
        case .missingAttribution(let id): "Record “\(id)” requires attribution for CC-BY-4.0. The catalog wasn't loaded."
        }
    }
}
