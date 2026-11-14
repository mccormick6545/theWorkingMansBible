// SPDX-License-Identifier: Apache-2.0
import Foundation

public enum CalculatorError: Error, Equatable {
    case invalidDimension
}

/// Geometric estimates only, not structural engineering designs.
public enum MaterialCalculators {
    public static func concreteCubicYards(lengthFeet: Double, widthFeet: Double, thicknessInches: Double) throws -> Double {
        guard lengthFeet.isFinite, widthFeet.isFinite, thicknessInches.isFinite,
              lengthFeet > 0, widthFeet > 0, thicknessInches > 0 else {
            throw CalculatorError.invalidDimension
        }
        return lengthFeet * widthFeet * (thicknessInches / 12.0) / 27.0
    }

    public static func rectangleAreaSquareFeet(lengthFeet: Double, widthFeet: Double) throws -> Double {
        guard lengthFeet.isFinite, widthFeet.isFinite,
              lengthFeet > 0, widthFeet > 0 else {
            throw CalculatorError.invalidDimension
        }
        return lengthFeet * widthFeet
    }
}

public enum TorqueUnits {
    public static func newtonMeters(fromFootPounds value: Double) -> Double {
        value * 1.3558179483314004
    }

    public static func footPounds(fromNewtonMeters value: Double) -> Double {
        value / 1.3558179483314004
    }

    public static func inchPounds(fromFootPounds value: Double) -> Double {
        value * 12
    }
}
