import SwiftUI
import SwiftData

struct LocationEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\CampusLocation.sortOrder)]) private var locations: [CampusLocation]
    @State private var showingAdd = false

    private struct GroupedSection: Identifiable {
        let id: String
        let locations: [CampusLocation]
    }

    private var groupedSections: [GroupedSection] {
        var bucket: [String: [CampusLocation]] = [:]
        var order: [String] = []
        for loc in locations {
            if bucket[loc.groupName] == nil { order.append(loc.groupName) }
            bucket[loc.groupName, default: []].append(loc)
        }
        return order.map { GroupedSection(id: $0, locations: bucket[$0] ?? []) }
    }

    var body: some View {
        List {
            ForEach(groupedSections) { section in
                Section(section.id) {
                    ForEach(section.locations) { location in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(location.name)
                                if location.isUserCreated {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                            }
                            if !location.subLocations.isEmpty {
                                Text(location.subLocations.joined(separator: " • "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .onDelete { offsets in
                        delete(from: section.locations, at: offsets)
                    }
                }
            }
        }
        .navigationTitle("Campus Locations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddCustomLocationView(existingGroups: existingGroupNames)
            }
        }
    }

    private var existingGroupNames: [String] {
        var seen: Set<String> = []
        var result: [String] = []
        for loc in locations where !seen.contains(loc.groupName) {
            seen.insert(loc.groupName)
            result.append(loc.groupName)
        }
        return result
    }

    private func delete(from sectionLocations: [CampusLocation], at offsets: IndexSet) {
        for index in offsets {
            let target = sectionLocations[index]
            modelContext.delete(target)
        }
        try? modelContext.save()
    }
}

private struct AddCustomLocationView: View {
    let existingGroups: [String]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGroup: String = ""
    @State private var name: String = ""
    @State private var subLocationsRaw: String = ""

    private var canSave: Bool {
        !selectedGroup.isEmpty && !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Group") {
                Picker("Group", selection: $selectedGroup) {
                    Text("Choose…").tag("")
                    ForEach(existingGroups, id: \.self) { group in
                        Text(group).tag(group)
                    }
                }
            }

            Section("Name") {
                TextField("Location name", text: $name)
            }

            Section("Sub-locations") {
                TextField("Comma-separated (optional)", text: $subLocationsRaw, axis: .vertical)
                    .lineLimit(3...6)
            } footer: {
                Text("Example: Main Lobby, Restroom, Stairwell")
            }
        }
        .navigationTitle("Add Location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .onAppear {
            if selectedGroup.isEmpty, let first = existingGroups.first {
                selectedGroup = first
            }
        }
    }

    private func save() {
        let subs = subLocationsRaw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let maxOrder = (try? modelContext.fetch(
            FetchDescriptor<CampusLocation>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        ).first?.sortOrder) ?? 0

        let location = CampusLocation(
            groupName: selectedGroup,
            name: name.trimmingCharacters(in: .whitespaces),
            subLocations: subs,
            isUserCreated: true,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(location)
        try? modelContext.save()
        dismiss()
    }
}
