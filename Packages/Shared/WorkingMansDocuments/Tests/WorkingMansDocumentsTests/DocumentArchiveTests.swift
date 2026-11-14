// SPDX-License-Identifier: Apache-2.0
import Foundation
import PDFKit
import Testing
@testable import WorkingMansDocuments

@MainActor
struct DocumentArchiveTests {
    private func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "ArchiveTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    }

    private func samplePDF(_ text: String = "Receipt") throws -> Data {
        try #require(RecordsPDF.textPDF(text).dataRepresentation())
    }

    @Test func ownersStaySeparate() throws {
        let archive = DocumentArchive(folder: temporaryFolder())
        try archive.add(ArchivedDocument(ownerID: "home", title: "Water heater warranty", date: .now), pdf: samplePDF())
        try archive.add(ArchivedDocument(ownerID: "vin-1FTFW3LDXRFB40317", title: "Oil change", date: .now, usage: 42_000),
                        pdf: samplePDF())
        #expect(archive.documents(for: "home").map(\.title) == ["Water heater warranty"])
        #expect(archive.documents(for: "vin-1FTFW3LDXRFB40317").map(\.title) == ["Oil change"])
    }

    @Test func reloadsFromDisk() throws {
        let folder = temporaryFolder()
        let document = ArchivedDocument(ownerID: "home", title: "Permit", date: .now)
        try DocumentArchive(folder: folder).add(document, pdf: samplePDF())
        let reopened = DocumentArchive(folder: folder)
        #expect(reopened.documents.map(\.id) == [document.id])
        #expect(FileManager.default.fileExists(atPath: reopened.url(for: document).path))
    }

    @Test func deleteRemovesRecordAndFile() throws {
        let archive = DocumentArchive(folder: temporaryFolder())
        let document = ArchivedDocument(ownerID: "home", title: "Inspection", date: .now)
        try archive.add(document, pdf: samplePDF())
        try archive.delete(document)
        #expect(archive.documents.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: archive.url(for: document).path))
    }

    @Test func rejectsNonPDF() {
        let archive = DocumentArchive(folder: temporaryFolder())
        #expect(throws: DocumentArchiveError.invalidPDF) {
            try archive.add(ArchivedDocument(ownerID: "home", title: "Bad", date: .now), pdf: Data("not a pdf".utf8))
        }
        #expect(archive.documents.isEmpty)
    }

    @Test func longTextSpansPages() throws {
        let pdf = try RecordsPDF.textPDF(String(repeating: "Line of notes\n", count: 200))
        #expect(pdf.pageCount > 1)
    }

    @Test func exportIncludesCoverDetailsAndOriginals() throws {
        let archive = DocumentArchive(folder: temporaryFolder())
        try archive.add(ArchivedDocument(ownerID: "home", title: "Roof invoice", date: .now), pdf: samplePDF())
        let url = try RecordsPDF.export(title: "Home Records", documents: archive.documents(for: "home"),
                                        documentURL: { archive.url(for: $0) })
        // Cover + details page + one original page.
        #expect(PDFDocument(url: url)?.pageCount == 3)
    }
}
