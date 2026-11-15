// SPDX-License-Identifier: Apache-2.0
import SwiftUI
import WorkingMansPartsCatalogUI

@main
struct WorkingMansBibleApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

struct RootView: View {
    @State private var showingAbout = false

    var body: some View {
        PartsCatalogView()
            .overlay(alignment: .bottomTrailing) {
                Button("About & Licenses", systemImage: "info.circle") { showingAbout = true }
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .padding()
            }
            .sheet(isPresented: $showingAbout) {
                NavigationStack {
                    AboutView()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showingAbout = false }
                            }
                        }
                }
            }
    }
}
