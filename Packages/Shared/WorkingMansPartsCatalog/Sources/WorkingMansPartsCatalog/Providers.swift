// SPDX-License-Identifier: Apache-2.0
import Foundation

/// Live provider results stay separate from redistributable offline records.
public struct LivePartResult: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String
    public let productURL: URL
    public let providerID: String

    public init(id: String, title: String, detail: String, productURL: URL, providerID: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.productURL = productURL
        self.providerID = providerID
    }
}

/// Implement adapters only after reviewing a supplier's public-app permission.
/// Never put API secrets into an open-source app bundle.
public protocol PartSearchProvider: Sendable {
    var providerID: String { get }
    func search(query: String) async throws -> [LivePartResult]
}

// Outbound links use `SourceLink` from WorkingMansCore.
