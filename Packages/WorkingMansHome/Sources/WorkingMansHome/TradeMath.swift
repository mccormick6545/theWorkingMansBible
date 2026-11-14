// SPDX-License-Identifier: Apache-2.0
import Foundation

/// Formulas behind the home-trade calculators. Estimates only – not engineering designs. Every result must be
/// checked against the equipment instructions, the code edition your jurisdiction adopted, and local amendments.
public enum TradeMath {

    // MARK: Electrical

    public struct WireGauge: Identifiable, Hashable, Sendable {
        public var id: String { name }
        public let name: String
        /// Copper ampacity, 60 °C column of NEC Table 310.16 (the NM-B limit per NEC 334.80).
        public let ampacity: Double
        /// Conductor area in circular mils (NEC Chapter 9, Table 8).
        public let circularMils: Double
    }

    /// Copper conductors, NEC Table 310.16 (60 °C) and Chapter 9 Table 8. Assumes no more than three
    /// current-carrying conductors and 30 °C ambient – derating for bundling or heat is not applied.
    public static let copperGauges: [WireGauge] = [
        WireGauge(name: "14 AWG", ampacity: 15, circularMils: 4_110),
        WireGauge(name: "12 AWG", ampacity: 20, circularMils: 6_530),
        WireGauge(name: "10 AWG", ampacity: 30, circularMils: 10_380),
        WireGauge(name: "8 AWG", ampacity: 40, circularMils: 16_510),
        WireGauge(name: "6 AWG", ampacity: 55, circularMils: 26_240),
        WireGauge(name: "4 AWG", ampacity: 70, circularMils: 41_740),
        WireGauge(name: "3 AWG", ampacity: 85, circularMils: 52_620),
        WireGauge(name: "2 AWG", ampacity: 95, circularMils: 66_360),
        WireGauge(name: "1 AWG", ampacity: 110, circularMils: 83_690),
        WireGauge(name: "1/0 AWG", ampacity: 125, circularMils: 105_600),
        WireGauge(name: "2/0 AWG", ampacity: 145, circularMils: 133_100),
    ]

    /// Copper resistivity constant K (ohm·cmil/ft) for single-phase voltage drop.
    static let copperK = 12.9

    /// Single-phase voltage drop for a one-way run: VD = 2 × K × I × L / cmil.
    public static func voltageDrop(amps: Double, oneWayFeet: Double, gauge: WireGauge) -> Double {
        2 * copperK * amps * oneWayFeet / gauge.circularMils
    }

    public struct WireRecommendation: Sendable {
        public let gauge: WireGauge
        public let dropVolts: Double
        public let dropPercent: Double
        /// The ampacity-only size, when voltage drop forced a bigger wire.
        public let upsizedFrom: WireGauge?
    }

    /// Smallest copper wire that carries the load (×125% if continuous) and keeps voltage drop ≤ `maxDropPercent`.
    /// Returns `nil` for invalid input or when no listed size works.
    public static func recommendWire(amps: Double, oneWayFeet: Double, volts: Double, continuous: Bool,
                                     maxDropPercent: Double = 3) -> WireRecommendation? {
        guard amps > 0, oneWayFeet > 0, volts > 0, amps.isFinite, oneWayFeet.isFinite, volts.isFinite else { return nil }
        let required = continuous ? amps * 1.25 : amps
        guard let byAmpacity = copperGauges.first(where: { $0.ampacity >= required }) else { return nil }
        let start = copperGauges.firstIndex(of: byAmpacity) ?? 0
        for gauge in copperGauges[start...] {
            let drop = voltageDrop(amps: amps, oneWayFeet: oneWayFeet, gauge: gauge)
            if drop / volts * 100 <= maxDropPercent {
                return WireRecommendation(gauge: gauge, dropVolts: drop, dropPercent: drop / volts * 100,
                                          upsizedFrom: gauge == byAmpacity ? nil : byAmpacity)
            }
        }
        return nil
    }

    /// Standard breaker sizes.
    public static let breakerSizes: [Double] = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100]

    // MARK: Solar

    public struct SolarSize: Sendable {
        public let systemKW: Double
        public let panelCount: Int
        public let roofAreaSqFt: Double
        public let yearlyKWh: Double
    }

    /// Grid-tie sizing: offset `offsetPercent` of monthly usage with `sunHours` peak sun hours per day.
    /// Assumes 80% system efficiency and about 21.5 sq ft of roof per panel. For a site-specific estimate use
    /// NREL PVWatts.
    public static func solarSize(monthlyKWh: Double, sunHours: Double, panelWatts: Double,
                                 offsetPercent: Double = 100, systemEfficiency: Double = 0.8) -> SolarSize {
        let dailyKWh = monthlyKWh * 12 / 365 * offsetPercent / 100
        let systemKW = dailyKWh / (sunHours * systemEfficiency)
        let panels = Int((systemKW * 1000 / panelWatts).rounded(.up))
        let actualKW = Double(panels) * panelWatts / 1000
        return SolarSize(systemKW: actualKW, panelCount: panels,
                         roofAreaSqFt: Double(panels) * 21.5,          // ~ 1.1 × 1.8 m panel + spacing
                         yearlyKWh: actualKW * sunHours * systemEfficiency * 365)
    }

    public struct BatteryBank: Sendable {
        public let usableWh: Double
        public let amphours12V: Double
        public let batteries100Ah: Int
        public let panelWatts: Double
    }

    /// Off-grid: daily watt-hours, days of backup, LiFePO4 at 12.8 V nominal with 80% usable,
    /// recharged in one day of sun at 75% charging efficiency.
    public static func batteryBank(dailyWh: Double, daysOfAutonomy: Double, sunHours: Double) -> BatteryBank {
        let usable = dailyWh * daysOfAutonomy
        let total = usable / 0.8
        let ah = total / 12.8
        return BatteryBank(usableWh: usable, amphours12V: ah,
                           batteries100Ah: max(1, Int((ah / 100).rounded(.up))),
                           panelWatts: dailyWh / (sunHours * 0.75))
    }

    // MARK: Concrete & masonry

    public struct ConcreteAmount: Sendable {
        public let cubicFeet: Double
        public var cubicYards: Double { cubicFeet / 27 }
        /// Bag yields: 80 lb ≈ 0.60 cu ft, 60 lb ≈ 0.45 cu ft (typical bag labels). No waste allowance added.
        public var bags80: Int { Int((cubicFeet / 0.6).rounded(.up)) }
        public var bags60: Int { Int((cubicFeet / 0.45).rounded(.up)) }
    }

    public static func slabConcrete(lengthFeet: Double, widthFeet: Double, depthInches: Double) -> ConcreteAmount {
        ConcreteAmount(cubicFeet: lengthFeet * widthFeet * depthInches / 12)
    }

    /// Round holes (post footings, sonotubes).
    public static func footingConcrete(count: Int, diameterInches: Double, depthInches: Double) -> ConcreteAmount {
        let radiusFeet = diameterInches / 24
        return ConcreteAmount(cubicFeet: Double(count) * .pi * radiusFeet * radiusFeet * depthInches / 12)
    }

    public struct MasonryAmount: Sendable {
        public let units: Int
        public let mortarBags: Int
    }

    /// 8×8×16 in block: 1.125 per sq ft; about 1 bag (80 lb) of mortar per 30 blocks; +10% waste.
    public static func blocks(wallLengthFeet: Double, wallHeightFeet: Double) -> MasonryAmount {
        let units = wallLengthFeet * wallHeightFeet * 1.125
        return MasonryAmount(units: roundUp(units * 1.1), mortarBags: roundUp(units / 30 * 1.1))
    }

    /// Modular brick with 3/8 in joints: about 6.75 per sq ft; 1 bag of mortar per ~40 bricks; +10% waste.
    public static func bricks(wallLengthFeet: Double, wallHeightFeet: Double) -> MasonryAmount {
        let units = wallLengthFeet * wallHeightFeet * 6.75
        return MasonryAmount(units: roundUp(units * 1.1), mortarBags: roundUp(units / 40 * 1.1))
    }

    /// Rounds up to whole units, ignoring floating-point noise (90 × 1.1 is 99.00000000000001, not 100).
    static func roundUp(_ value: Double) -> Int {
        Int((value - 1e-9).rounded(.up))
    }

    // MARK: Stairs

    public struct StairLayout: Sendable {
        public let risers: Int
        public let riserHeight: Double
        public let treads: Int
        public let treadDepth: Double
        public let totalRun: Double
        public let stringerLength: Double
        /// Checks only the riser/tread limits below – not headroom, width, nosing, handrails or guards.
        public let meetsCode: Bool
    }

    /// IRC R311.7.5 (residential): risers ≤ 7-3/4 in, treads ≥ 10 in. Local codes may differ.
    public static func stairs(totalRiseInches: Double, treadDepth: Double = 10.5) -> StairLayout {
        let risers = max(1, Int((totalRiseInches / 7.75).rounded(.up)))
        let riserHeight = totalRiseInches / Double(risers)
        let treads = risers - 1
        let run = Double(treads) * treadDepth
        return StairLayout(risers: risers, riserHeight: riserHeight, treads: treads, treadDepth: treadDepth,
                           totalRun: run, stringerLength: (run * run + totalRiseInches * totalRiseInches).squareRoot(),
                           meetsCode: riserHeight <= 7.75 && treadDepth >= 10)
    }
}
