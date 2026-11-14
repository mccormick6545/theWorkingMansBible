// SPDX-License-Identifier: Apache-2.0
import Testing
@testable import WorkingMansHome

struct TradeMathTests {
    @Test func voltageDropMatchesFormula() {
        let twelve = TradeMath.copperGauges[1]
        // 2 × 12.9 × 16 A × 50 ft / 6,530 cmil
        #expect(abs(TradeMath.voltageDrop(amps: 16, oneWayFeet: 50, gauge: twelve) - 3.1608) < 0.001)
    }

    @Test func shortRunUsesAmpacitySize() throws {
        let result = try #require(TradeMath.recommendWire(amps: 15, oneWayFeet: 25, volts: 120, continuous: false))
        #expect(result.gauge.name == "14 AWG")
        #expect(result.upsizedFrom == nil)
    }

    @Test func continuousLoadAdds25Percent() throws {
        // 16 A continuous needs 20 A capacity → 12 AWG.
        let result = try #require(TradeMath.recommendWire(amps: 16, oneWayFeet: 10, volts: 120, continuous: true))
        #expect(result.gauge.name == "12 AWG")
    }

    @Test func longRunUpsizesForVoltageDrop() throws {
        let result = try #require(TradeMath.recommendWire(amps: 15, oneWayFeet: 150, volts: 120, continuous: false))
        #expect(result.dropPercent <= 3)
        #expect(result.upsizedFrom?.name == "14 AWG")
    }

    @Test func invalidWireInputReturnsNil() {
        #expect(TradeMath.recommendWire(amps: 0, oneWayFeet: 50, volts: 120, continuous: false) == nil)
        #expect(TradeMath.recommendWire(amps: 20, oneWayFeet: 50, volts: 0, continuous: false) == nil)
        #expect(TradeMath.recommendWire(amps: 500, oneWayFeet: 50, volts: 240, continuous: false) == nil)
    }

    @Test func slabConcrete() {
        let amount = TradeMath.slabConcrete(lengthFeet: 9, widthFeet: 9, depthInches: 4)
        #expect(abs(amount.cubicYards - 1) < 1e-9)
        #expect(amount.bags80 == 45)   // 27 cu ft ÷ 0.6
    }

    @Test func footingConcrete() {
        let amount = TradeMath.footingConcrete(count: 4, diameterInches: 12, depthInches: 36)
        #expect(abs(amount.cubicFeet - 4 * .pi * 0.25 * 3) < 1e-9)
    }

    @Test func blockWallIncludesWaste() {
        let amount = TradeMath.blocks(wallLengthFeet: 20, wallHeightFeet: 4)
        #expect(amount.units == 99)        // 90 blocks + 10%
        #expect(amount.mortarBags == 4)
    }

    @Test func stairsStayWithinIRCLimits() {
        let layout = TradeMath.stairs(totalRiseInches: 108)
        #expect(layout.risers == 14)
        #expect(layout.riserHeight <= 7.75)
        #expect(layout.treads == 13)
        #expect(layout.meetsCode)
        #expect(!TradeMath.stairs(totalRiseInches: 108, treadDepth: 9).meetsCode)
    }

    @Test func solarSizing() {
        let size = TradeMath.solarSize(monthlyKWh: 900, sunHours: 5, panelWatts: 400)
        // 900 × 12 / 365 ≈ 29.6 kWh/day ÷ (5 × 0.8) ≈ 7.4 kW → 19 panels
        #expect(size.panelCount == 19)
        #expect(abs(size.systemKW - 7.6) < 1e-9)
    }

    @Test func batteryBank() {
        let bank = TradeMath.batteryBank(dailyWh: 2_000, daysOfAutonomy: 2, sunHours: 5)
        #expect(bank.usableWh == 4_000)
        #expect(bank.batteries100Ah == 4)   // 5,000 Wh ÷ 12.8 V ≈ 391 Ah
    }
}
