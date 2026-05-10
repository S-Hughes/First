import SwiftUI
import SwiftData

struct InspectionListView: View {
    let statusFilter: InspectionStatus

    @Environment(\.modelContext) private var modelContext
    @Query private var records: [InspectionRecord]

    @State private var searchText: String = ""
    @State private var selection: Set<UUID> = []
    @State private var editMode: EditMode = .inactive
    @State private var showingEditor: Bool = false
    @State private var showingExport: Bool = false
    @State private var pendingDelete: InspectionRecord?
    @State private var pendingBulkDelete: Bool = false

    init(statusFilter: InspectionStatus) {
        self.statusFilter = statusFilter
        let raw = statusFilter.rawValue
        let predicate = #Predicate<InspectionRecord> { $0.statusRaw == raw }
        _records = Query(filter: predicate, sort: [SortDescriptor(\.timestamp, order: .reverse)])
    }

    private var filteredRecords: [InspectionRecord] {
        guard !searchText.isEmpty else { return records }
        let query = searchText.lowercased()
        return records.filter { record in
            record.location.lowercased().contains(query)
                || (record.subLocation?.lowercased().contains(query) ?? false)
                || record.notes.lowercased().contains(query)
        }
    }

    private var selectedRecords: [InspectionRecord] {
        records.filter { selection.contains($0.id) }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            content
            if editMode == .inactive {
                addButton
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle(statusFilter == .active ? "Active" : "Inactive")
        .toolbar { toolbarContent }
        .searchable(text: $searchText, prompt: "Search location or notes")
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                InspectionEditorView(record: nil)
            }
        }
        .sheet(isPresented: $showingExport) {
            NavigationStack {
                ExportOptionsView(records: selectedRecords) {
                    showingExport = false
                    editMode = .inactive
                    selection.removeAll()
                }
            }
        }
        .alert("Delete this inspection?", isPresented: Binding(
            get: { pendingDelete != nil },
            set: { if !$0 { pendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let record = pendingDelete {
                    delete(record)
                }
                pendingDelete = nil
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        }
        .alert("Delete \(selection.count) inspections?", isPresented: $pendingBulkDelete) {
            Button("Delete", role: .destructive) {
                deleteSelected()
                pendingBulkDelete = false
            }
            Button("Cancel", role: .cancel) { pendingBulkDelete = false }
        }
    }

    @ViewBuilder
    private var content: some View {
        if filteredRecords.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(filteredRecords) { record in
                NavigationLink(value: record.id) {
                    InspectionRowView(record: record)
                }
                .tag(record.id)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        pendingDelete = record
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    if record.status == .active {
                        Button {
                            close(record)
                        } label: {
                            Label("Close", systemImage: "checkmark.circle")
                        }
                        .tint(.orange)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if record.status == .inactive {
                        Button {
                            reopen(record)
                        } label: {
                            Label("Reopen", systemImage: "arrow.uturn.backward.circle")
                        }
                        .tint(.green)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(for: UUID.self) { id in
            if let record = records.first(where: { $0.id == id }) {
                InspectionDetailView(record: record)
            }
        }
        .refreshable {
            // SwiftData @Query auto-refreshes; this enables the pull-to-refresh affordance.
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: statusFilter == .active ? "checklist" : "archivebox")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text(statusFilter == .active
                 ? "No active inspections yet"
                 : "No closed inspections")
                .font(.headline)
                .foregroundStyle(.secondary)
            if statusFilter == .active {
                Text("Tap the + button to start one.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private var addButton: some View {
        Button {
            showingEditor = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(radius: 4, y: 2)
        }
        .accessibilityLabel("New Inspection")
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !records.isEmpty {
                EditButton()
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if editMode == .active && !selection.isEmpty {
                Button {
                    showingExport = true
                } label: {
                    Label("Export (\(selection.count))", systemImage: "square.and.arrow.up")
                }
                Button(role: .destructive) {
                    pendingBulkDelete = true
                } label: {
                    Label("Delete (\(selection.count))", systemImage: "trash")
                }
            }
        }
    }

    private func close(_ record: InspectionRecord) {
        record.close()
        try? modelContext.save()
    }

    private func reopen(_ record: InspectionRecord) {
        record.reopen()
        try? modelContext.save()
    }

    private func delete(_ record: InspectionRecord) {
        PhotoStorageService.deleteAll(filenames: record.photoFilenames)
        modelContext.delete(record)
        try? modelContext.save()
    }

    private func deleteSelected() {
        for record in selectedRecords {
            PhotoStorageService.deleteAll(filenames: record.photoFilenames)
            modelContext.delete(record)
        }
        try? modelContext.save()
        selection.removeAll()
        editMode = .inactive
    }
}
