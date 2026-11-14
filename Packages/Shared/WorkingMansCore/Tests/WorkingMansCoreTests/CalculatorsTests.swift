// SPDX-License-Identifier: Apache-2.0
import XCTest
@testable import WorkingMansCore

final class CalculatorsTests: XCTestCase {
    func testConcrete() throws {
        XCTAssertEqual(try MaterialCalculators.concreteCubicYards(lengthFeet: 9, widthFeet: 9, thicknessInches: 4), 1, accuracy: 1e-9)
    }

    func testInvalidDimension() {
        XCTAssertThrowsError(try MaterialCalculators.rectangleAreaSquareFeet(lengthFeet: 0, widthFeet: 8))
    }

    func testArea() throws {
        XCTAssertEqual(try MaterialCalculators.rectangleAreaSquareFeet(lengthFeet: 10, widthFeet: 8), 80)
    }

    func testTorqueRoundTrip() {
        let original = 100.0
        XCTAssertEqual(TorqueUnits.footPounds(fromNewtonMeters: TorqueUnits.newtonMeters(fromFootPounds: original)), original, accuracy: 1e-9)
        XCTAssertEqual(TorqueUnits.inchPounds(fromFootPounds: 10), 120)
    }
}
