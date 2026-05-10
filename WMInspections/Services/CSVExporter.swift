import Foundation

enum CSVExporter {
    static func build(records: [InspectionRecord]) -> Data {
        let header = ["Status", "Date", "Location", "Sub-location", "Category", "Notes"]
        var rows: [[String]] = [header]

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withSpaceBetweenDateAndTime]

        for record in records {
            let truncatedNotes: String
            if record.notes.count > 100 {
                let index = record.notes.index(record.notes.startIndex, offsetBy: 100)
                truncatedNotes = String(record.notes[..<index]) + "…"
            } else {
                truncatedNotes = record.notes
            }
            rows.append([
                record.status.displayName,
                formatter.string(from: record.timestamp),
                record.location,
                record.subLocation ?? "",
                record.category.displayName,
                truncatedNotes
            ])
        }

        let csv = rows.map { row in
            row.map(escape).joined(separator: ",")
        }.joined(separator: "\r\n")

        let bom: [UInt8] = [0xEF, 0xBB, 0xBF]
        var data = Data(bom)
        data.append(csv.data(using: .utf8) ?? Data())
        return data
    }

    static func suggestedFilename(count: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "WM-Inspections-\(formatter.string(from: Date()))-\(count).csv"
    }

    private static func escape(_ field: String) -> String {
        let dangerous: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]
        var safe = field
        if let first = safe.first, dangerous.contains(first) {
            safe = "'" + safe
        }
        if safe.contains(",") || safe.contains("\"") || safe.contains("\n") || safe.contains("\r") {
            return "\"\(safe.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return safe
    }
}
