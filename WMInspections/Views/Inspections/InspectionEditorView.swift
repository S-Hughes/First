import SwiftUI
import SwiftData

struct InspectionEditorView: View {
    let record: InspectionRecord?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\CampusLocation.sortOrder)]) private var allLocations: [CampusLocation]

    @State private var location: String = ""
    @State private var subLocation: String = ""
    @State private var category: InspectionCategory = .other
    @State private var notes: String = ""
    @State private var photoFilenames: [String] = []
    @State private var originalPhotoFilenames: [String] = []

    @State private var showingLocationPicker = false
    @State private var showingSubLocationPicker = false
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var customSubLocation: String = ""
    @State private var showingCustomSubLocationAlert = false

    private var isNewRecord: Bool { record == nil }

    private var matchingCampusLocation: CampusLocation? {
        allLocations.first { $0.name == location }
    }

    private var availableSubLocations: [String] {
        matchingCampusLocation?.subLocations ?? []
    }

    private var canSave: Bool {
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Location") {
                Button {
                    showingLocationPicker = true
                } label: {
                    HStack {
                        Text("Building / Area")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(location.isEmpty ? "Choose…" : location)
                            .foregroundStyle(location.isEmpty ? .secondary : .primary)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }

                Button {
                    showingSubLocationPicker = true
                } label: {
                    HStack {
                        Text("Sub-location")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(subLocation.isEmpty ? "Optional" : subLocation)
                            .foregroundStyle(subLocation.isEmpty ? .secondary : .primary)
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
                .disabled(location.isEmpty && availableSubLocations.isEmpty)
            }

            Section("Category") {
                CategoryPicker(selection: $category)
            }

            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
            }

            Section("Photos (\(photoFilenames.count))") {
                PhotoThumbnailGridView(
                    filenames: $photoFilenames,
                    allowsDeletion: true
                )
                HStack(spacing: 16) {
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

                    Button {
                        showingPhotoLibrary = true
                    } label: {
                        Label("Add from Library", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .navigationTitle(isNewRecord ? "New Inspection" : "Edit Inspection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(!canSave)
            }
        }
        .onAppear(perform: load)
        .sheet(isPresented: $showingLocationPicker) {
            NavigationStack {
                LocationPickerView(selection: $location, previousSelection: location) { changed in
                    if changed {
                        subLocation = ""
                    }
                }
            }
        }
        .sheet(isPresented: $showingSubLocationPicker) {
            NavigationStack {
                SubLocationPickerView(
                    options: availableSubLocations,
                    selection: $subLocation
                )
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(photoFilenames: $photoFilenames)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showingPhotoLibrary) {
            PhotoPickerCoordinator(photoFilenames: $photoFilenames)
                .ignoresSafeArea()
        }
    }

    private func load() {
        guard let record else {
            originalPhotoFilenames = []
            return
        }
        location = record.location
        subLocation = record.subLocation ?? ""
        category = record.category
        notes = record.notes
        photoFilenames = record.photoFilenames
        originalPhotoFilenames = record.photoFilenames
    }

    private func cancel() {
        let originalSet = Set(originalPhotoFilenames)
        let addedThisSession = photoFilenames.filter { !originalSet.contains($0) }
        PhotoStorageService.deleteAll(filenames: addedThisSession)
        dismiss()
    }

    private func save() {
        let trimmedSubLocation = subLocation.trimmingCharacters(in: .whitespaces)
        let resolvedSubLocation = trimmedSubLocation.isEmpty ? nil : trimmedSubLocation
        let trimmedLocation = location.trimmingCharacters(in: .whitespaces)

        let currentSet = Set(photoFilenames)
        let removed = originalPhotoFilenames.filter { !currentSet.contains($0) }
        PhotoStorageService.deleteAll(filenames: removed)

        if let record {
            record.location = trimmedLocation
            record.subLocation = resolvedSubLocation
            record.category = category
            record.notes = notes
            record.photoFilenames = photoFilenames
            record.touch()
        } else {
            let newRecord = InspectionRecord(
                location: trimmedLocation,
                subLocation: resolvedSubLocation,
                category: category,
                notes: notes,
                photoFilenames: photoFilenames
            )
            modelContext.insert(newRecord)
        }
        try? modelContext.save()
        dismiss()
    }
}
