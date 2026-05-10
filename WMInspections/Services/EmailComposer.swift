import Foundation
import MessageUI

struct PendingExport {
    let recipients: [String]
    let subject: String
    let body: String
    let attachments: [PDFExporter.Attachment]
}

enum EmailComposer {
    static func canSendMail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }

    static func writeAttachmentsToTempDirectory(_ attachments: [PDFExporter.Attachment]) -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("export-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        var urls: [URL] = []
        for attachment in attachments {
            let url = tempDir.appendingPathComponent(attachment.filename)
            do {
                try attachment.data.write(to: url, options: .atomic)
                urls.append(url)
            } catch {
                continue
            }
        }
        return urls
    }
}
