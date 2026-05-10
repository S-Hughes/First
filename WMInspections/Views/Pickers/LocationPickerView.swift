import SwiftUI
import SwiftData

struct LocationPickerView: View {
    @Binding var selection: String
    var previousSelection: String = ""
    var onSelect: ((_ changed: Bool) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CampusLocation.sortOrder)]) private var locations: [CampusLocation]
    @State private var searchText: String = ""

    private struct GroupedSection: Identifiable {
        let id: String
        let locations: [CampusLocation]
    }

    private var groupedSections: [GroupedSection] {
        let filtered: [CampusLocation]
        if searchText.isEmpty {
            filtered = locations
        } else {
            let query = searchText.lowercased()
            filtered = locations.filter {
                $0.name.lowercased().contains(query)
                    || $0.groupName.lowercased().contains(query)
            }
        }

        var bucket: [String: [CampusLocation]] = [:]
        var order: [String] = []
        for loc in filtered {
            if bucket[loc.groupName] == nil { order.append(loc.groupName) }
            bucket[loc.groupName, default: []].append(loc)
        }
        return order.map { GroupedSection(id: $0, locations: bucket[$0] ?? []) }
    }

    var body: some View {
        List {
            ForEach(groupedSections) { section in
                Section(section.id) {
                    ForEach(section.locations) { loc in
                        Button {
                            let changed = previousSelection != loc.name
                            selection = loc.name
                            onSelect?(changed)
                            dismiss()
                        } label: {
                            HStack {
                                Text(loc.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if loc.isUserCreated {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                if selection == loc.name {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose Location")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search locations")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
    }
}
