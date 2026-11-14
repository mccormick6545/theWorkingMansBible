// SPDX-License-Identifier: Apache-2.0
import Foundation
import Testing
@testable import WorkingMansVehicles

struct VINTests {
    @Test func findsVINInText() {
        #expect(VIN.find(in: "VIN: 1m8gdm9axkp042788 thanks") == "1M8GDM9AXKP042788")
        // Door-jamb barcodes often add a leading "I".
        #expect(VIN.find(in: "I1M8GDM9AXKP042788") == "1M8GDM9AXKP042788")
        // Printed in groups with spaces.
        #expect(VIN.find(in: "1M8GD M9AXK P042788") == "1M8GDM9AXKP042788")
        #expect(VIN.find(in: "too short 1M8GDM9AX") == nil)
    }

    @Test func rejectsForbiddenLetters() {
        #expect(!VIN.isWellFormed("1M8GDM9AXKP04278O"))   // O
        #expect(!VIN.isWellFormed("1M8GDM9AXKP04278I"))   // I
        #expect(!VIN.isWellFormed("1M8GDM9AXKP04278Q"))   // Q
    }

    @Test func checkDigit() {
        // The standard worked example (check digit X) and an all-ones VIN (check digit 1).
        #expect(VIN.hasValidCheckDigit("1M8GDM9AXKP042788"))
        #expect(VIN.hasValidCheckDigit("11111111111111111"))
        #expect(!VIN.hasValidCheckDigit("1M8GDM9A1KP042788"))
    }

    @Test func parsesValidatedDecode() throws {
        let json = #"{"Results":[{"Make":"FORD","Model":"F-150","ModelYear":"2024","ErrorCode":"0","DriveType":"4WD","Trim":""}]}"#
        let decoded = try NHTSAVINDecoder.parse(Data(json.utf8), vin: "1FTFW3LDXRFB40317")
        #expect(decoded.title == "2024 FORD F-150")
        #expect(decoded.details["Drive"] == "4WD")
        #expect(decoded.details["Trim"] == nil)
    }

    @Test func rejectsDecodeWithErrors() {
        let json = #"{"Results":[{"Make":"FORD","Model":"F-150","ModelYear":"2024","ErrorCode":"1","ErrorText":"Check digit invalid"}]}"#
        #expect(throws: VINError.rejected("Check digit invalid")) {
            try NHTSAVINDecoder.parse(Data(json.utf8), vin: "1FTFW3LDXRFB40317")
        }
    }

    @Test func recallsDropDuplicates() throws {
        let json = #"{"results":[{"NHTSACampaignNumber":"24V001"},{"NHTSACampaignNumber":"24V001"},{"NHTSACampaignNumber":"23V999"}]}"#
        #expect(try VehicleRecalls.parse(Data(json.utf8)).map(\.id) == ["24V001", "23V999"])
    }

    @Test func vinLookupLinkIsOfficial() throws {
        let link = try #require(VehicleRecalls.vinLookupLink(vin: "1FTFW3LDXRFB40317"))
        #expect(link.isOfficial)
        #expect(link.url.absoluteString == "https://www.nhtsa.gov/recalls?vin=1FTFW3LDXRFB40317")
    }
}
