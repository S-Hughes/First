import Foundation
import UIKit

enum PDFExporter {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 40
    private static let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    private static let sectionFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    private static let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
    private static let smallFont = UIFont.systemFont(ofSize: 10, weight: .regular)

    struct Attachment {
        let data: Data
        let mimeType: String
        let filename: String
    }

    static func buildSinglePDF(record: InspectionRecord) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "W&M Inspection \(record.id.uuidString)",
            kCGPDFContextCreator as String: "W&M Inspections iOS"
        ]
        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: pageSize),
            format: format
        )

        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var cursor: CGFloat = margin
            let contentWidth = pageSize.width - margin * 2

            cursor = drawTitle("William & Mary MBWA Inspection Report", at: cursor, width: contentWidth)
            cursor += 4
            drawDivider(y: cursor, width: contentWidth)
            cursor += 12

            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short

            cursor = drawKeyValue("Record ID", record.id.uuidString, at: cursor, width: contentWidth)
            cursor = drawKeyValue("Date / Time", formatter.string(from: record.timestamp), at: cursor, width: contentWidth)
            cursor = drawKeyValue("Status", record.status.displayName, at: cursor, width: contentWidth)
            cursor = drawKeyValue("Location", record.location, at: cursor, width: contentWidth)
            cursor = drawKeyValue("Sub-location", record.subLocation ?? "—", at: cursor, width: contentWidth)
            cursor = drawKeyValue("Category", record.category.displayName, at: cursor, width: contentWidth)
            if let closed = record.closedDate {
                cursor = drawKeyValue("Closed", formatter.string(from: closed), at: cursor, width: contentWidth)
            }

            cursor += 8
            cursor = drawSection("Notes", at: cursor, width: contentWidth)
            cursor = drawWrappedText(record.notes.isEmpty ? "—" : record.notes, at: cursor, width: contentWidth, font: bodyFont, ctx: ctx, cursorReset: { cursor in cursor })

            for (index, filename) in record.photoFilenames.enumerated() {
                guard let image = PhotoStorageService.loadFullImage(filename: filename) else { continue }
                let caption = "Photo \(index + 1)"
                let scaledHeight = image.size.height * (contentWidth / max(image.size.width, 1))
                let needed = scaledHeight + 24

                if cursor + needed > pageSize.height - margin {
                    ctx.beginPage()
                    cursor = margin
                }

                cursor = drawSection(caption, at: cursor, width: contentWidth)
                let rect = CGRect(x: margin, y: cursor, width: contentWidth, height: scaledHeight)
                image.draw(in: rect)
                cursor += scaledHeight + 12
            }
        }

        return data
    }

    static func buildAttachments(
        records: [InspectionRecord],
        includeOriginalPhotos: Bool
    ) -> [Attachment] {
        var attachments: [Attachment] = []

        for record in records {
            let pdfData = buildSinglePDF(record: record)
            attachments.append(Attachment(
                data: pdfData,
                mimeType: "application/pdf",
                filename: pdfFilename(for: record)
            ))

            if includeOriginalPhotos {
                for (index, filename) in record.photoFilenames.enumerated() {
                    let url = PhotoStorageService.fullImageURL(filename: filename)
                    if let data = try? Data(contentsOf: url) {
                        attachments.append(Attachment(
                            data: data,
                            mimeType: "image/jpeg",
                            filename: photoFilename(for: record, photoIndex: index)
                        ))
                    }
                }
            }
        }
        return attachments
    }

    static func pdfFilename(for record: InspectionRecord) -> String {
        let date = filenameDate(record.timestamp)
        let loc = sanitize(record.location)
        let sub = sanitize(record.subLocation ?? "general")
        return "\(loc)-\(sub)_\(date).pdf"
    }

    static func photoFilename(for record: InspectionRecord, photoIndex: Int) -> String {
        let date = filenameDate(record.timestamp)
        let loc = sanitize(record.location)
        let sub = sanitize(record.subLocation ?? "general")
        return "\(loc)-\(sub)_\(date)_photo\(photoIndex + 1).jpg"
    }

    private static func filenameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func sanitize(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(scalars).replacingOccurrences(
            of: "-+",
            with: "-",
            options: .regularExpression
        )
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    @discardableResult
    private static func drawTitle(_ text: String, at y: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
        let rect = CGRect(x: margin, y: y, width: width, height: 28)
        (text as NSString).draw(in: rect, withAttributes: attrs)
        return y + 26
    }

    private static func drawDivider(y: CGFloat, width: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: margin + width, y: y))
        UIColor.darkGray.setStroke()
        path.lineWidth = 0.5
        path.stroke()
    }

    @discardableResult
    private static func drawKeyValue(_ key: String, _ value: String, at y: CGFloat, width: CGFloat) -> CGFloat {
        let keyAttrs: [NSAttributedString.Key: Any] = [.font: sectionFont, .foregroundColor: UIColor.darkGray]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.black]
        let keyWidth: CGFloat = 110
        (key as NSString).draw(in: CGRect(x: margin, y: y, width: keyWidth, height: 16), withAttributes: keyAttrs)
        (value as NSString).draw(in: CGRect(x: margin + keyWidth, y: y, width: width - keyWidth, height: 16), withAttributes: valueAttrs)
        return y + 18
    }

    @discardableResult
    private static func drawSection(_ text: String, at y: CGFloat, width: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: sectionFont, .foregroundColor: UIColor.black]
        (text as NSString).draw(in: CGRect(x: margin, y: y, width: width, height: 18), withAttributes: attrs)
        return y + 18
    }

    private static func drawWrappedText(
        _ text: String,
        at y: CGFloat,
        width: CGFloat,
        font: UIFont,
        ctx: UIGraphicsPDFRendererContext,
        cursorReset: (CGFloat) -> CGFloat
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let bounding = attributed.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        var currentY = y
        if currentY + bounding.height > pageSize.height - margin {
            ctx.beginPage()
            currentY = margin
        }
        attributed.draw(in: CGRect(x: margin, y: currentY, width: width, height: bounding.height))
        return currentY + bounding.height + 8
    }
}
