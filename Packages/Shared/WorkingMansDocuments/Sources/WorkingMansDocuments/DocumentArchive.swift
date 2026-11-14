// SPDX-License-Identifier: Apache-2.0
import Foundation
import Observation

/// One saved PDF – a receipt, warranty, permit, inspection report or service record.
public struct ArchivedDocument: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    /// Who the document belongs to, e.g. a vehicle ID or "home". Keeps each owner's records separate.
    public let ownerID: String
    public var title: String
    public var date: Date
    /// Odometer miles or engine hours at the time, for vehicles and equipment.
    public var usage: Int?
    public var notes: String
    public var fileName: String { "\(id.uuidString).pdf" }

    public init(id: UUID = UUID(), ownerID: String, title: String, date: Date, usage: Int? = nil, notes: String = "") {
        self.id = id
        self.ownerID = ownerID
        self.title = title
        self.date = date
        self.usage = usage
        self.notes = notes
    }
}

public enum DocumentArchiveError: LocalizedError, Equatable {
    case unavailable
    case invalidPDF
    case missingAttachment(String)
    case exportFailed

    public var errorDescription: String? {
        switch self {
        case .unavailable: "The document archive is unavailable. Existing files have been preserved."
        case .invalidPDF: "Choose an unlocked PDF with at least one page."
        case .missingAttachment(let name): "Could not read “\(name)”. The export was stopped so nothing would be shared with missing documents."
        case .exportFailed: "The PDF could not be created. Please try again."
        }
    }
}

/// Stores PDFs and an index in a folder on this device. Nothing is uploaded.
@MainActor
@Observable
public final class DocumentArchive {
    public private(set) var documents: [ArchivedDocument] = []
    /// Set when the saved index couldn't be read. Writes are refused so the existing files aren't overwritten.
    public private(set) var loadError: String?
    private let folder: URL

    public init(folder: URL = URL.applicationSupportDirectory.appending(path: "Documents", directoryHint: .isDirectory)) {
        self.folder = folder
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let index = folder.appending(path: "index.json")
            if FileManager.default.fileExists(atPath: index.path) {
                documents = try JSONDecoder().decode([ArchivedDocument].self, from: Data(contentsOf: index))
            }
        } catch {
            loadError = "Your saved documents could not be opened. \(error.localizedDescription)"
        }
    }

    /// One owner's documents, newest first.
    public func documents(for ownerID: String) -> [ArchivedDocument] {
        documents.filter { $0.ownerID == ownerID }.sorted { $0.date > $1.date }
    }

    public func url(for document: ArchivedDocument) -> URL {
        folder.appending(path: document.fileName)
    }

    public func add(_ document: ArchivedDocument, pdf: Data) throws {
        guard loadError == nil else { throw DocumentArchiveError.unavailable }
        try RecordsPDF.validate(pdf)
        let destination = url(for: document)
        try pdf.write(to: destination, options: .atomic)
        let updated = documents + [document]
        do {
            try persist(updated)
            documents = updated
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    public func delete(_ document: ArchivedDocument) throws {
        guard loadError == nil else { throw DocumentArchiveError.unavailable }
        let updated = documents.filter { $0.id != document.id }
        // Commit the index first; a failed save must leave the original record intact.
        try persist(updated)
        documents = updated
        try? FileManager.default.removeItem(at: url(for: document))
    }

    private func persist(_ updated: [ArchivedDocument]) throws {
        try JSONEncoder().encode(updated).write(to: folder.appending(path: "index.json"), options: .atomic)
    }
}
