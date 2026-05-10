import SwiftUI

struct PhotoThumbnailGridView: View {
    @Binding var filenames: [String]
    let allowsDeletion: Bool

    @State private var fullScreenFilename: String?

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]

    var body: some View {
        if filenames.isEmpty {
            Text("No photos yet")
                .foregroundStyle(.secondary)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filenames, id: \.self) { filename in
                    cell(for: filename)
                }
            }
            .fullScreenCover(item: Binding<IdentifiableString?>(
                get: { fullScreenFilename.map(IdentifiableString.init) },
                set: { fullScreenFilename = $0?.value }
            )) { wrapped in
                FullScreenPhotoView(
                    filename: wrapped.value,
                    onDelete: allowsDeletion ? { delete(filename: wrapped.value) } : nil
                )
            }
        }
    }

    @ViewBuilder
    private func cell(for filename: String) -> some View {
        let image = PhotoStorageService.loadThumbnail(filename: filename)
        ZStack(alignment: .topTrailing) {
            Button {
                fullScreenFilename = filename
            } label: {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemFill))
                        .frame(width: 90, height: 90)
                        .overlay(Image(systemName: "photo").foregroundStyle(.secondary))
                }
            }
            .buttonStyle(.plain)

            if allowsDeletion {
                Button(role: .destructive) {
                    delete(filename: filename)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .black.opacity(0.7))
                        .font(.title3)
                }
                .padding(4)
            }
        }
    }

    private func delete(filename: String) {
        PhotoStorageService.delete(filename: filename)
        filenames.removeAll { $0 == filename }
        if fullScreenFilename == filename {
            fullScreenFilename = nil
        }
    }
}

private struct IdentifiableString: Identifiable {
    let value: String
    var id: String { value }
}
