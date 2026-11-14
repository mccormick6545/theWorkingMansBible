// SPDX-License-Identifier: Apache-2.0
import Foundation
import Testing
@testable import WorkingMansHome

struct ApplianceLookupTests {
    @Test(arguments: [
        ("RHEEM MANUFACTURING CO\nMODEL NO. XG40T06EC36U1\nSERIAL NO. Q081234567", "Rheem", "XG40T06EC36U1"),
        ("Whirlpool\nMODEL / MODÈLE\nWED4815EW1\nSERIAL W12345678", "Whirlpool", "WED4815EW1"),
        ("Bradford White\nModel Number RG240T6N\n", "Bradford White", "RG240T6N"),
        ("Carrier\nMODEL:\n59SC5A080S17\n120VAC 60HZ", "Carrier", "59SC5A080S17"),
    ])
    func readsRatingPlates(text: String, brand: String, model: String) {
        #expect(ApplianceLookup.brand(in: text) == brand)
        #expect(ApplianceLookup.modelNumber(in: text) == model)
    }

    @Test func skipsElectricalRatings() {
        // A model name with no digits must not fall through to "120V" on the next line.
        #expect(ApplianceLookup.modelNumber(in: "InSinkErator Model: Badger 5 Series 1\n120V 60Hz") == nil)
    }

    @Test func linksAreFreeLookupsThenSearch() {
        let links = ApplianceLookup.links(brand: "Rheem", model: "XG40T06EC36U1")
        #expect(links.count == 4)
        #expect(links[0].url.absoluteString == "https://www.repairclinic.com/Shop-For-Parts?query=XG40T06EC36U1")
        #expect(links[1].url.absoluteString == "https://www.partselect.com/Models/XG40T06EC36U1/")
        #expect(links.allSatisfy { !$0.isOfficial })
        #expect(ApplianceLookup.links(brand: "", model: "  ").isEmpty)
    }

    @Test func decodesRecalls() throws {
        let json = #"[{"RecallID":123,"RecallNumber":"24001","Title":"Heater Recall","URL":"https://www.cpsc.gov/x","Products":[{"Name":"Heater","Model":"ABC1234"}],"Hazards":[{"Name":"Fire"}],"Remedies":[{"Name":"Repair"}]}]"#
        let recalls = try ApplianceLookup.decodeRecalls(Data(json.utf8))
        #expect(recalls.first?.recallID == 123)
        #expect(recalls.first?.products?.first?.Model == "ABC1234")
    }

    @Test func serviceErrorRecordThrows() {
        let json = #"[{"RecallID":0,"Title":"Error retrieving Recalls"}]"#
        #expect(throws: (any Error).self) { try ApplianceLookup.decodeRecalls(Data(json.utf8)) }
    }
}
