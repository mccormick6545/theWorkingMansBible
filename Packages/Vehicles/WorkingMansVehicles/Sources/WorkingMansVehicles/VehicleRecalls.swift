// SPDX-License-Identifier: Apache-2.0
import Foundation
import WorkingMansCore

/// A recall campaign from NHTSA's free recalls API (api.nhtsa.gov), U.S. government data.
public struct VehicleRecall: Codable, Identifiable, Equatable, Sendable {
    public var id: String { NHTSACampaignNumber }
    public let NHTSACampaignNumber: String
    public let Component: String?
    public let Summary: String?
    public let Consequence: String?
    public let Remedy: String?
    public let ReportReceivedDate: String?
    public let Notes: String?
}

public enum VehicleRecalls {
    /// Recalls for the year, make and model. These are model-level results – they don't show whether a
    /// specific vehicle is affected or already repaired; check the VIN at `vinLookupURL`.
    public static func recalls(for vehicle: DecodedVIN, session: URLSession = .shared) async throws -> [VehicleRecall] {
        guard let year = vehicle.year else { throw URLError(.cannotParseResponse) }
        var components = URLComponents(string: "https://api.nhtsa.gov/recalls/recallsByVehicle")
        components?.queryItems = [
            URLQueryItem(name: "make", value: vehicle.make),
            URLQueryItem(name: "model", value: vehicle.model),
            URLQueryItem(name: "modelYear", value: String(year)),
        ]
        guard let url = components?.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try parse(data)
    }

    /// Decodes the response, dropping duplicate campaigns.
    static func parse(_ data: Data) throws -> [VehicleRecall] {
        struct Response: Decodable { let results: [VehicleRecall] }
        var seen: Set<String> = []
        return try JSONDecoder().decode(Response.self, from: data).results.filter { seen.insert($0.id).inserted }
    }

    /// NHTSA's per-VIN recall check, which shows open (unrepaired) recalls for one vehicle.
    public static func vinLookupLink(vin: String) -> SourceLink? {
        var components = URLComponents(string: "https://www.nhtsa.gov/recalls")
        components?.queryItems = [URLQueryItem(name: "vin", value: vin)]
        guard let url = components?.url else { return nil }
        return SourceLink(title: "Check this VIN for open recalls", publisher: "NHTSA", kind: .official, url: url)
    }
}
