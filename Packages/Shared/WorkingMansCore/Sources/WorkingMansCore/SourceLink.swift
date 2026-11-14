// SPDX-License-Identifier: Apache-2.0
import Foundation

/// A link out to a manual, parts diagram, recall notice or search. The app opens these in the browser –
/// it never copies or embeds the linked material, which usually belongs to the manufacturer.
public struct SourceLink: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        /// Published by the manufacturer, a dealer, or a government agency.
        case official
        /// A free third-party site that shows factory diagrams or part numbers – not the manufacturer.
        case freeLookup
        /// A general web search. Results are not verified.
        case search
    }

    public var id: URL { url }
    public let title: String
    public let publisher: String
    public let kind: Kind
    public let url: URL

    public init(title: String, publisher: String, kind: Kind, url: URL) {
        self.title = title
        self.publisher = publisher
        self.kind = kind
        self.url = url
    }

    /// Builds a link, or `nil` when the address isn't a valid URL.
    public init?(title: String, publisher: String, kind: Kind, address: String) {
        guard let url = URL(string: address) else { return nil }
        self.init(title: title, publisher: publisher, kind: kind, url: url)
    }

    public var isOfficial: Bool { kind == .official }
}
