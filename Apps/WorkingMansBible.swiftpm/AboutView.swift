// SPDX-License-Identifier: Apache-2.0
import SwiftUI

/// App license, data rights and source attribution.
struct AboutView: View {
    private let repository = URL(string: "https://github.com/mccormick6545/theWorkingMansBible")

    var body: some View {
        Form {
            Section {
                Text("The Working Man's Bible").font(.title2.bold())
                Text("A free, open-source, offline-first reference and project toolkit for the people who build, maintain and repair things.")
                if let repository {
                    Link("Source Code on GitHub", destination: repository)
                }
            }
            Section("License") {
                Text("Original code is licensed under the Apache License 2.0.")
                Text("Third-party data keeps its own license. Each part in the catalog shows its publisher, license, attribution and whether redistribution is approved.")
            }
            Section("Data") {
                Text("No third-party catalogs, manuals or diagrams are bundled with the app. Catalogs you import are stored only on this device.")
                Text("Specifications are descriptive information from each record's source – not engineering certifications. Confirm critical values with the manufacturer.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("About & Licenses")
    }
}
