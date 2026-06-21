import Foundation
import UIKit
import CoreText

enum PDFExporter {
    private static let pageSize = CGSize(width: 612, height: 792)
    private static let margin: CGFloat = 40
    private static let titleFont = UIFont.systemFont(ofSize: 20, weight: .bold)
    private static let sectionFont = UIFont.systemFont(ofSize: 13, weight: .semibold)
    private static let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)

    struct Attachment {
        let data: Data
        let mimeType: String
        let filename: String
    }

    static func buildSinglePDF(record: InspectionRecord) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "W&M Inspection – \(record.location)",
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
            cursor = drawTextPaginated(
                record.notes.isEmpty ? "—" : record.notes,
                startingAt: cursor,
                width: contentWidth,
                font: bodyFont,
                ctx: ctx
            )

            for (index, filename) in record.photoFilenames.enumerated() {
                guard let image = PhotoStorageService.loadFullImage(filename: filename) else { continue }
                let caption = "Photo \(index + 1)"
                let maxHeight = pageSize.height - margin * 2 - 24
                let aspectScale = contentWidth / max(image.size.width, 1)
                let widthScaledHeight = image.size.height * aspectScale
                let drawHeight = min(widthScaledHeight, maxHeight)
                let drawWidth = drawHeight * (image.size.width / max(image.size.height, 1))
                let needed = drawHeight + 24

                if cursor + needed > pageSize.height - margin {
                    ctx.beginPage()
                    cursor = margin
                }

                cursor = drawSection(caption, at: cursor, width: contentWidth)
                let rect = CGRect(
                    x: margin + (contentWidth - drawWidth) / 2,
                    y: cursor,
                    width: drawWidth,
                    height: drawHeight
                )
                image.draw(in: rect)
                cursor += drawHeight + 12
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
        let loc = sanitize(record.location, fallback: "inspection")
        let sub = sanitize(record.subLocation ?? "general", fallback: "general")
        let suffix = idSuffix(record.id)
        return "\(loc)-\(sub)_\(date)_\(suffix).pdf"
    }

    static func photoFilename(for record: InspectionRecord, photoIndex: Int) -> String {
        let date = filenameDate(record.timestamp)
        let loc = sanitize(record.location, fallback: "inspection")
        let sub = sanitize(record.subLocation ?? "general", fallback: "general")
        let suffix = idSuffix(record.id)
        return "\(loc)-\(sub)_\(date)_\(suffix)_photo\(photoIndex + 1).jpg"
    }

    private static func idSuffix(_ uuid: UUID) -> String {
        String(uuid.uuidString.prefix(8))
    }

    private static func filenameDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func sanitize(_ raw: String, fallback: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(scalars).replacingOccurrences(
            of: "-+",
            with: "-",
            options: .regularExpression
        )
        let trimmed = collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? fallback : trimmed
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

    private static func drawTextPaginated(
        _ text: String,
        startingAt startY: CGFloat,
        width: CGFloat,
        font: UIFont,
        ctx: UIGraphicsPDFRendererContext
    ) -> CGFloat {
        guard !text.isEmpty else { return startY }
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor.black]
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let framesetter = CTFramesetterCreateWithAttributedString(attributed)
        let totalLength = attributed.length

        var charLocation = 0
        var pageY = startY
        let cgContext = ctx.cgContext
        let minBlockHeight = font.lineHeight * 2

        while charLocation < totalLength {
            let availableHeight = (pageSize.height - margin) - pageY
            if availableHeight < minBlockHeight {
                ctx.beginPage()
                pageY = margin
                continue
            }

            let frameRect = CGRect(x: margin, y: pageY, width: width, height: availableHeight)
            let flippedRect = CGRect(
                x: frameRect.minX,
                y: pageSize.height - frameRect.maxY,
                width: frameRect.width,
                height: frameRect.height
            )
            let path = CGPath(rect: flippedRect, transform: nil)
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: charLocation, length: 0),
                path,
                nil
            )

            cgContext.saveGState()
            cgContext.textMatrix = .identity
            cgContext.translateBy(x: 0, y: pageSize.height)
            cgContext.scaleBy(x: 1, y: -1)
            CTFrameDraw(frame, cgContext)
            cgContext.restoreGState()

            let visibleRange = CTFrameGetVisibleStringRange(frame)
            guard visibleRange.length > 0 else { break }
            charLocation += visibleRange.length

            let consumedHeight = consumedHeight(in: frame, frameHeight: flippedRect.height)
            pageY += consumedHeight + 8

            if charLocation < totalLength {
                ctx.beginPage()
                pageY = margin
            }
        }
        return pageY
    }

    private static func consumedHeight(in frame: CTFrame, frameHeight: CGFloat) -> CGFloat {
        let linesCF = CTFrameGetLines(frame)
        let count = CFArrayGetCount(linesCF)
        guard count > 0 else { return 0 }

        var origins = [CGPoint](repeating: .zero, count: count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: count), &origins)

        guard let firstOrigin = origins.first, let lastOrigin = origins.last else { return 0 }
        let lastLine = unsafeBitCast(CFArrayGetValueAtIndex(linesCF, count - 1), to: CTLine.self)
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        _ = CTLineGetTypographicBounds(lastLine, &ascent, &descent, &leading)

        let topOfFirst = firstOrigin.y + ascent
        let bottomOfLast = lastOrigin.y - descent
        return max(0, topOfFirst - bottomOfLast)
    }
}
