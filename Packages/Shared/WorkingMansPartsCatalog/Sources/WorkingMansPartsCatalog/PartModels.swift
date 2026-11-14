// SPDX-License-Identifier: Apache-2.0
import Foundation

/// License and provenance must be recorded at the individual asset level.
public struct PartAsset: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable { case image, cad, datasheet, manual, drawing }
    public let id: String
    public let kind: Kind
    public let url: URL
    public let licenseIdentifier: String
    public let attribution: String
    public let redistributionApproved: Bool

    public init(id: String, kind: Kind, url: URL, licenseIdentifier: String,
                attribution: String, redistributionApproved: Bool) {
        self.id = id
        self.kind = kind
        self.url = url
        self.licenseIdentifier = licenseIdentifier
        self.attribution = attribution
        self.redistributionApproved = redistributionApproved
    }
}

public struct PartProvenance: Codable, Sendable, Hashable {
    public let publisher: String
    public let sourceURL: URL
    public let licenseIdentifier: String
    public let attribution: String
    /// Approval must be recorded, not inferred from a public URL or free API tier.
    public let redistributionApproved: Bool
    public let verifiedAt: Date?

    public init(publisher: String, sourceURL: URL, licenseIdentifier: String,
                attribution: String, redistributionApproved: Bool, verifiedAt: Date? = nil) {
        self.publisher = publisher
        self.sourceURL = sourceURL
        self.licenseIdentifier = licenseIdentifier
        self.attribution = attribution
        self.redistributionApproved = redistributionApproved
        self.verifiedAt = verifiedAt
    }
}

public struct CatalogPart: Codable, Sendable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public let manufacturer: String?
    public let manufacturerPartNumber: String?
    public let description: String
    /// Descriptive metadata, not an engineering certification.
    public let specifications: [String: String]
    public let source: PartProvenance
    public let assets: [PartAsset]

    public init(id: String, name: String, category: String, manufacturer: String? = nil,
                manufacturerPartNumber: String? = nil, description: String = "",
                specifications: [String: String] = [:], source: PartProvenance,
                assets: [PartAsset] = []) {
        self.id = id
        self.name = name
        self.category = category
        self.manufacturer = manufacturer
        self.manufacturerPartNumber = manufacturerPartNumber
        self.description = description
        self.specifications = specifications
        self.source = source
        self.assets = assets
    }
}

public enum CatalogError: Error, Equatable, Sendable {
    case duplicateIdentifier(String)
    case invalidRecord(String)
    case redistributionNotApproved(String)
}
