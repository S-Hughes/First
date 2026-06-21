import SwiftUI

struct InspectionRowView: View {
    let record: InspectionRecord

    private var notesPreview: String {
        let trimmed = record.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "No notes" }
        if trimmed.count > 80 {
            let index = trimmed.index(trimmed.startIndex, offsetBy: 80)
            return String(trimmed[..<index]) + "…"
        }
        return trimmed
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: record.category.symbolName)
                        .foregroundStyle(.tint)
                    Text(headerText)
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(notesPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(record.category.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.15), in: Capsule())
                    Spacer()
                    Text(record.timestamp.shortRelativeString())
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var headerText: String {
        if let sub = record.subLocation, !sub.isEmpty {
            return "\(record.location) — \(sub)"
        }
        return record.location
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let firstPhoto = record.photoFilenames.first,
           let uiImage = PhotoStorageService.loadThumbnail(filename: firstPhoto) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
