// SPDX-License-Identifier: Apache-2.0
import SwiftUI

/// One part: identification, specifications, where the record came from and its license, and linked files.
public struct PartDetailView: View {
    let part: CatalogPart
    let isFavorite: Bool
    let toggleFavorite: () -> Void

    public init(part: CatalogPart, isFavorite: Bool, toggleFavorite: @escaping () -> Void) {
        self.part = part
        self.isFavorite = isFavorite
        self.toggleFavorite = toggleFavorite
    }

    public var body: some View {
        Form {
            Section {
                Text(part.name).font(.title2.bold())
                if !part.description.isEmpty { Text(part.description) }
                LabeledContent("Category", value: part.category)
                if let manufacturer = part.manufacturer {
                    LabeledContent("Manufacturer", value: manufacturer)
                }
                if let number = part.manufacturerPartNumber {
                    LabeledContent("Part number") {
                        Text(number).font(.body.monospaced()).textSelection(.enabled)
                    }
                }
                LabeledContent("Catalog ID") {
                    Text(part.id).font(.caption.monospaced()).textSelection(.enabled)
                }
            }

            if !part.specifications.isEmpty {
                Section {
                    ForEach(part.specifications.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending },
                            id: \.key) { spec in
                        LabeledContent(spec.key, value: spec.value)
                    }
                } header: {
                    Text("Specifications")
                } footer: {
                    Text("Descriptive information from the source below – not an engineering certification. Confirm critical values with the manufacturer.")
                }
            }

            Section {
                LabeledContent("Publisher", value: part.source.publisher)
                LabeledContent("License", value: part.source.licenseIdentifier)
                if !part.source.attribution.isEmpty {
                    LabeledContent("Attribution", value: part.source.attribution)
                }
                LabeledContent("Redistribution", value: part.source.redistributionApproved ? "Approved" : "Not approved")
                if let verified = part.source.verifiedAt {
                    LabeledContent("License verified", value: verified.formatted(date: .abbreviated, time: .omitted))
                } else {
                    LabeledContent("License verified", value: "Not recorded")
                }
                SourceLinkRow(title: "Open Original Source", url: part.source.sourceURL)
            } header: {
                Text("Source & License")
            }

            if !part.assets.isEmpty {
                Section("Files") {
                    ForEach(part.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            SourceLinkRow(title: asset.kind.label, url: asset.url)
                            Text("\(asset.licenseIdentifier) · \(asset.attribution)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(part.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem {
                Button(isFavorite ? "Remove Favorite" : "Add Favorite",
                       systemImage: isFavorite ? "star.fill" : "star",
                       action: toggleFavorite)
            }
        }
    }
}

/// Opens web links in the browser; other addresses are shown as text.
private struct SourceLinkRow: View {
    let title: String
    let url: URL

    var body: some View {
        if url.scheme == "https" || url.scheme == "http" {
            Link(destination: url) {
                Label(title, systemImage: "arrow.up.right.square")
            }
        } else {
            LabeledContent(title, value: url.absoluteString)
        }
    }
}

extension PartAsset.Kind {
    var label: String {
        switch self {
        case .image: "Image"
        case .cad: "CAD Model"
        case .datasheet: "Datasheet"
        case .manual: "Manual"
        case .drawing: "Drawing"
        }
    }
}
