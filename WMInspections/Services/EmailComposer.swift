import Foundation
import MessageUI

struct PendingExport {
    let recipients: [String]
    let subject: String
    let body: String
    let attachments: [PDFExporter.Attachment]
}

enum EmailComposer {
    private static let tempPrefix = "wm-export-"

    static func canSendMail() -> Bool {
        MFMailComposeViewController.canSendMail()
    }

    static func writeAttachmentsToTempDirectory(_ attachments: [PDFExporter.Attachment]) -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(tempPrefix)\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(
                at: tempDir,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        } catch {
            return []
        }

        var urls: [URL] = []
        for attachment in attachments {
            let url = tempDir.appendingPathComponent(attachment.filename)
            do {
                try attachment.data.write(to: url, options: [.atomic, .completeFileProtection])
                urls.append(url)
            } catch {
                continue
            }
        }
        return urls
    }

    static func sweepStaleTempExports() {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        guard let entries = try? fm.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil) else { return }
        for entry in entries where entry.lastPathComponent.hasPrefix(tempPrefix) {
            try? fm.removeItem(at: entry)
        }
    }
}
