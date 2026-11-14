// SPDX-License-Identifier: Apache-2.0
import Foundation
import WorkingMansCore

/// A recall from the U.S. Consumer Product Safety Commission's free recall API (saferproducts.gov).
public struct ApplianceRecall: Decodable, Identifiable, Sendable {
    public struct Named: Decodable, Sendable { public let Name: String? }
    public struct Product: Decodable, Sendable {
        public let Name: String?
        public let Model: String?
    }

    public var id: Int { recallID }
    public let recallID: Int
    public let recallNumber: String?
    public let recallDate: String?
    public let title: String?
    public let description: String?
    public let url: String?
    public let products: [Product]?
    public let hazards: [Named]?
    public let remedies: [Named]?

    enum CodingKeys: String, CodingKey {
        case recallID = "RecallID", recallNumber = "RecallNumber", recallDate = "RecallDate", title = "Title"
        case description = "Description", url = "URL", products = "Products", hazards = "Hazards", remedies = "Remedies"
    }
}

/// Reads the brand and model number off an appliance rating plate and links out to free parts-diagram
/// lookups, manuals and recalls. Only links to these sites – never scrapes or copies their diagrams.
public enum ApplianceLookup {
    /// Brands commonly found on water heaters, HVAC equipment, appliances and fixtures.
    public static let knownBrands = [
        "A.O. Smith", "American Standard", "Bosch", "Bradford White", "Broan", "Carrier", "Delta", "Electrolux",
        "Frigidaire", "GE", "Goodman", "Honeywell", "Hunter", "InSinkErator", "Kenmore", "KitchenAid", "Kohler",
        "Lennox", "LG", "Maytag", "Moen", "Navien", "Rheem", "Rinnai", "Ruud", "Samsung", "State", "Trane", "Whirlpool",
    ]

    /// The model number printed after a "MODEL", "MODEL NO." or "M/N" label (or on the line below it).
    public static func modelNumber(in text: String) -> String? {
        let lines = text.uppercased().components(separatedBy: .newlines)
        let labels = ["MODEL NUMBER", "MODEL NO", "MODEL", "MOD NO", "MOD.", "M/N"]
        for (index, line) in lines.enumerated() {
            guard let range = labels.lazy.compactMap({ line.range(of: $0) }).first else { continue }
            let rest = String(line[range.upperBound...])
            // The value is on the line below only when no digits follow the label (e.g. "MODEL / MODÈLE").
            let next = !rest.contains(where: \.isNumber) && index + 1 < lines.count ? tokens(lines[index + 1]) : []
            if let model = (tokens(rest) + next).first { return model }
        }
        return nil
    }

    /// A known brand name that appears as its own word in the text.
    public static func brand(in text: String) -> String? {
        let words = Set(text.uppercased().split(whereSeparator: { !$0.isLetter && $0 != "." }).map(String.init))
        let upper = text.uppercased()
        return knownBrands.first { brand in
            brand.contains(" ") ? upper.contains(brand.uppercased()) : words.contains(brand.uppercased())
        }
    }

    /// Model-number-like tokens: 4+ characters with at least one digit, skipping ratings like "120V" or "60HZ".
    private static func tokens(_ text: String) -> [String] {
        text.split(whereSeparator: { $0.isWhitespace || $0 == ":" || $0 == "#" })
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: ".,;-")) }
            .filter { $0.count >= 4 && $0.contains(where: \.isNumber) && !isRating($0) }
    }

    private static let ratingUnits = ["V", "VAC", "HZ", "W", "A", "AMPS", "GAL", "PSI", "BTU", "BTUH"]

    /// "120V", "60HZ", "4.5KW"-style electrical or capacity ratings.
    private static func isRating(_ token: String) -> Bool {
        guard let unitStart = token.firstIndex(where: { !$0.isNumber && $0 != "." }),
              unitStart != token.startIndex else { return false }
        return ratingUnits.contains(String(token[unitStart...]))
    }

    /// Free lookups that show the factory exploded view and part numbers for a model, then a manual search.
    public static func links(brand: String, model: String) -> [SourceLink] {
        let model = model.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "/", with: "")
        guard !model.isEmpty, let query = model.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return [] }
        let manual = [brand, model, "owner's manual installation manual pdf"].filter { !$0.isEmpty }.joined(separator: " ")
        let manualQuery = manual.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return [
            SourceLink(title: "Parts diagram & part numbers for \(model)",
                       publisher: "RepairClinic – free lookup, not the manufacturer", kind: .freeLookup,
                       address: "https://www.repairclinic.com/Shop-For-Parts?query=\(query)"),
            SourceLink(title: "Parts diagram & part numbers for \(model)",
                       publisher: "PartSelect – free lookup, not the manufacturer", kind: .freeLookup,
                       address: "https://www.partselect.com/Models/\(query)/"),
            // Sears PartsDirect model pages need internal brand/category IDs, so open the site and search there.
            SourceLink(title: "Parts diagrams – enter \(model) in the search box",
                       publisher: "Sears PartsDirect – free lookup, not the manufacturer", kind: .freeLookup,
                       address: "https://www.searspartsdirect.com"),
            SourceLink(title: "Find the owner's & installation manual", publisher: "Web search – not verified",
                       kind: .search, address: "https://www.google.com/search?q=\(manualQuery)"),
        ].compactMap { $0 }
    }

    /// CPSC recall search page, for brand searches the API can't do well.
    public static let cpscRecallsURL = URL(string: "https://www.cpsc.gov/Recalls")

    /// CPSC recalls whose product model matches. Only the model number is sent.
    public static func recalls(model: String, session: URLSession = .shared) async throws -> [ApplianceRecall] {
        var components = URLComponents(string: "https://www.saferproducts.gov/RestWebServices/Recall")
        components?.queryItems = [URLQueryItem(name: "format", value: "json"),
                                  URLQueryItem(name: "ProductModel", value: model)]
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try decodeRecalls(data)
    }

    /// Parses the CPSC response. When the service fails it answers 200 with a single record whose RecallID is 0.
    static func decodeRecalls(_ data: Data) throws -> [ApplianceRecall] {
        let records = try JSONDecoder().decode([ApplianceRecall].self, from: data)
        if records.contains(where: { $0.recallID == 0 }) { throw URLError(.badServerResponse) }
        return Array(records.prefix(25))
    }
}
