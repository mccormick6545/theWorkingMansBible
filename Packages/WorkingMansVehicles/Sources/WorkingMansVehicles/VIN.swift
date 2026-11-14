// SPDX-License-Identifier: Apache-2.0
import Foundation
import WorkingMansCore

/// A vehicle identified from its VIN.
public struct DecodedVIN: Equatable, Codable, Identifiable, Sendable {
    public var id: String { vin }
    /// Extra decoded specifications, e.g. "Engine", "Drive", "Body", "Vehicle type".
    public var details: [String: String]
    public let vin: String
    public let year: Int?
    public let make: String
    public let model: String

    public init(vin: String, year: Int?, make: String, model: String, details: [String: String] = [:]) {
        self.vin = vin
        self.year = year
        self.make = make
        self.model = model
        self.details = details
    }

    public var title: String { [year.map(String.init), make, model].compactMap { $0 }.joined(separator: " ") }
}

public enum VINError: LocalizedError, Equatable {
    case invalidFormat
    case rejected(String)

    public var errorDescription: String? {
        switch self {
        case .invalidFormat: "A VIN is 17 letters and numbers, without I, O or Q."
        case .rejected(let reason): "Check the VIN. \(reason)"
        }
    }
}

public enum VIN {
    /// The first valid 17-character VIN in the text (no I, O or Q). Handles the leading "I" that
    /// many door-jamb VIN barcodes add.
    public static func find(in text: String) -> String? {
        let upper = text.uppercased()
        // Words as written first ("VIN 1M8… MADE IN USA"), then with spaces removed for VINs printed in groups.
        for source in [upper, upper.replacingOccurrences(of: " ", with: "")] {
            for token in source.split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                var candidate = String(token)
                if candidate.count == 18, candidate.hasPrefix("I") { candidate.removeFirst() }
                if isWellFormed(candidate) { return candidate }
            }
        }
        return nil
    }

    /// 17 characters from the VIN alphabet (A–Z and 0–9 except I, O, Q).
    public static func isWellFormed(_ vin: String) -> Bool {
        vin.count == 17 && vin.allSatisfy { $0.isASCII && ($0.isNumber || ($0.isUppercase && !"IOQ".contains($0))) }
    }

    /// The North American check digit (position 9) per 49 CFR 565.15. VINs from other markets may not use it.
    public static func hasValidCheckDigit(_ vin: String) -> Bool {
        guard isWellFormed(vin) else { return false }
        let weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2]
        let sum = zip(vin, weights).reduce(0) { total, pair in total + transliterate(pair.0) * pair.1 }
        let remainder = sum % 11
        let expected: Character = remainder == 10 ? "X" : Character(String(remainder))
        return Array(vin)[8] == expected
    }

    private static func transliterate(_ character: Character) -> Int {
        if let digit = character.wholeNumberValue { return digit }
        let values: [Character: Int] = [
            "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8,
            "J": 1, "K": 2, "L": 3, "M": 4, "N": 5, "P": 7, "R": 9,
            "S": 2, "T": 3, "U": 4, "V": 5, "W": 6, "X": 7, "Y": 8, "Z": 9,
        ]
        return values[character] ?? 0
    }
}

/// NHTSA's free vPIC VIN decoder (vpic.nhtsa.dot.gov), U.S. government data. Only the VIN is sent.
public enum NHTSAVINDecoder {
    struct Response: Decodable {
        struct Result: Decodable {
            let Make: String?
            let Model: String?
            let ModelYear: String?
            let ErrorCode: String?
            let ErrorText: String?
            let Trim: String?
            let EngineModel: String?
            let DisplacementL: String?
            let EngineCylinders: String?
            let FuelTypePrimary: String?
            let DriveType: String?
            let TransmissionStyle: String?
            let BodyClass: String?
            let VehicleType: String?
        }
        let Results: [Result]
    }

    public static func decode(vin: String, session: URLSession = .shared) async throws -> DecodedVIN {
        guard VIN.isWellFormed(vin),
              let url = URL(string: "https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/\(vin)?format=json")
        else { throw VINError.invalidFormat }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try parse(data, vin: vin)
    }

    /// Accepts only a fully validated decode (every vPIC error code "0") with year, make and model.
    static func parse(_ data: Data, vin: String) throws -> DecodedVIN {
        guard let result = try JSONDecoder().decode(Response.self, from: data).Results.first else {
            throw URLError(.cannotParseResponse)
        }
        let codes = (result.ErrorCode ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard !codes.isEmpty, codes.allSatisfy({ $0 == "0" }) else {
            throw VINError.rejected(result.ErrorText ?? "NHTSA could not fully validate this VIN.")
        }
        guard let make = result.Make, !make.isEmpty, let model = result.Model, !model.isEmpty,
              let yearText = result.ModelYear, let year = Int(yearText)
        else { throw URLError(.cannotParseResponse) }
        let fields: [String: String?] = [
            "Trim": result.Trim, "Engine": result.EngineModel, "Displacement (L)": result.DisplacementL,
            "Cylinders": result.EngineCylinders, "Fuel": result.FuelTypePrimary,
            "Drive": result.DriveType, "Transmission": result.TransmissionStyle,
            "Body": result.BodyClass, "Vehicle type": result.VehicleType,
        ]
        let details = fields.compactMapValues { value -> String? in
            guard let value, !value.isEmpty else { return nil }
            return value
        }
        return DecodedVIN(vin: vin, year: year, make: make, model: model, details: details)
    }
}
