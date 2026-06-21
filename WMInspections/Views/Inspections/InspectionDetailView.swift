import SwiftUI

struct InspectionDetailView: View {
    @Bindable var record: InspectionRecord
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditor = false

    var body: some View {
        Form {
            Section("Location") {
                LabeledContent("Building / Area", value: record.location)
                LabeledContent("Sub-location", value: record.subLocation ?? "—")
            }

            Section("Inspection") {
                LabeledContent("Category", value: record.category.displayName)
                LabeledContent("Status", value: record.status.displayName)
                LabeledContent("Created", value: record.createdDate.mediumDateTimeString())
                LabeledContent("Last modified", value: record.lastModifiedDate.mediumDateTimeString())
                if let closed = record.closedDate {
                    LabeledContent("Closed", value: closed.mediumDateTimeString())
                }
            }

            Section("Notes") {
                if record.notes.isEmpty {
                    Text("No notes")
                        .foregroundStyle(.secondary)
                } else {
                    Text(record.notes)
                }
            }

            if !record.photoFilenames.isEmpty {
                Section("Photos (\(record.photoFilenames.count))") {
                    PhotoThumbnailGridView(
                        filenames: $record.photoFilenames,
                        allowsDeletion: false
                    )
                    .padding(.vertical, 4)
                }
            }

            Section {
                if record.status == .active {
                    Button {
                        record.close()
                        try? modelContext.save()
                    } label: {
                        Label("Close Inspection", systemImage: "checkmark.circle.fill")
                    }
                    .tint(.orange)
                } else {
                    Button {
                        record.reopen()
                        try? modelContext.save()
                    } label: {
                        Label("Reopen", systemImage: "arrow.uturn.backward.circle.fill")
                    }
                    .tint(.green)
                }
            }
        }
        .navigationTitle(record.location)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                InspectionEditorView(record: record)
            }
        }
    }
}
