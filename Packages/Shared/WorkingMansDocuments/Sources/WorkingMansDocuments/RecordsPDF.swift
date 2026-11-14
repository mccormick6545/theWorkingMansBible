// SPDX-License-Identifier: Apache-2.0
import Foundation
import CoreText
import PDFKit

/// Builds one shareable PDF: a cover page, then for each document a details page followed by all of its
/// original pages, so scans stay readable.
public enum RecordsPDF {
    public static func validate(_ data: Data) throws {
        guard let pdf = PDFDocument(data: data), !pdf.isLocked, pdf.pageCount > 0 else {
            throw DocumentArchiveError.invalidPDF
        }
    }

    /// - Parameters:
    ///   - title: e.g. "Home Records" or "2019 Ford F-150 Service History".
    ///   - summary: Optional extra cover-page lines, e.g. the latest odometer reading.
    ///   - usageUnit: Label for `ArchivedDocument.usage`, e.g. "mi" or "hrs".
    public static func export(title: String, summary: String = "", documents: [ArchivedDocument], usageUnit: String = "",
                              documentURL: (ArchivedDocument) -> URL) throws -> URL {
        let output = PDFDocument()
        var cover = "\(title)\n\nPrepared \(Date.now.formatted(date: .long, time: .shortened))\n\n"
        if !summary.isEmpty { cover += "\(summary)\n\n" }
        cover += "\(documents.count) documents\n\n"
        cover += "Owner-maintained records and attached documents. Dates, readings and notes are entered by the owner. This report does not certify condition or that any work met code or manufacturer specifications.\n\n"
        cover += "Each document has a cover page with its date and notes, followed by all original pages."
        try append(textPDF(cover), to: output)
        for record in documents.sorted(by: { $0.date < $1.date }) {
            var text = "\(title)\n\n\(record.title)\nDate: \(record.date.formatted(date: .long, time: .omitted))\n"
            if let usage = record.usage { text += "Reading: \(usage.formatted()) \(usageUnit)\n" }
            text += "\n\(record.notes)\n\nOriginal document follows."
            try append(textPDF(text), to: output)
            guard let pdf = PDFDocument(url: documentURL(record)), !pdf.isLocked, pdf.pageCount > 0 else {
                throw DocumentArchiveError.missingAttachment(record.title)
            }
            try append(pdf, to: output)
        }
        return try write(output, named: title)
    }

    static func append(_ source: PDFDocument, to output: PDFDocument) throws {
        for index in 0..<source.pageCount {
            guard let page = source.page(at: index)?.copy() as? PDFPage else { throw DocumentArchiveError.exportFailed }
            output.insert(page, at: output.pageCount)
        }
    }

    static func write(_ output: PDFDocument, named name: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appending(path: "RecordsExport-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeName = name.replacingOccurrences(of: "/", with: "-")
        let url = directory.appending(path: "\(safeName).pdf")
        guard let data = output.dataRepresentation() else { throw DocumentArchiveError.exportFailed }
        try data.write(to: url, options: .atomic)
        return url
    }

    /// US Letter text pages. Core Text advances by the visible character range so long notes are never clipped.
    public static func textPDF(_ text: String) throws -> PDFDocument {
        let bytes = NSMutableData()
        guard let consumer = CGDataConsumer(data: bytes as CFMutableData) else { throw DocumentArchiveError.exportFailed }
        var bounds = CGRect(x: 0, y: 0, width: 612, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &bounds, nil) else { throw DocumentArchiveError.exportFailed }
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): CTFontCreateWithName("Helvetica" as CFString, 12, nil)
        ]
        let string = NSAttributedString(string: text, attributes: attributes)
        let framesetter = CTFramesetterCreateWithAttributedString(string)
        let path = CGPath(rect: bounds.insetBy(dx: 42, dy: 48), transform: nil)
        var offset = 0
        while offset < string.length {
            context.beginPDFPage(nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRange(location: offset, length: 0), path, nil)
            CTFrameDraw(frame, context)
            let count = CTFrameGetVisibleStringRange(frame).length
            context.endPDFPage()
            guard count > 0 else { context.closePDF(); throw DocumentArchiveError.exportFailed }
            offset += count
        }
        context.closePDF()
        guard let pdf = PDFDocument(data: bytes as Data), pdf.pageCount > 0 else { throw DocumentArchiveError.exportFailed }
        return pdf
    }
}
