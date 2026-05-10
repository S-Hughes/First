import SwiftUI

struct SubLocationPickerView: View {
    let options: [String]
    @Binding var selection: String

    @Environment(\.dismiss) private var dismiss
    @State private var showingCustomEntry = false
    @State private var customValue: String = ""

    var body: some View {
        List {
            if !options.isEmpty {
                Section {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                            dismiss()
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selection == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    customValue = selection
                    showingCustomEntry = true
                } label: {
                    Label("Custom…", systemImage: "pencil.line")
                }
                if !selection.isEmpty {
                    Button(role: .destructive) {
                        selection = ""
                        dismiss()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .navigationTitle("Sub-location")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Enter sub-location", isPresented: $showingCustomEntry) {
            TextField("Sub-location", text: $customValue)
            Button("Save") {
                selection = customValue.trimmingCharacters(in: .whitespaces)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
}
