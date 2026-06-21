import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                TextField("Default \"To\" address", text: $settings.defaultEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Email")
            } footer: {
                Text("This address is pre-filled in the mail composer when you export.")
            }

            Section {
                Toggle(
                    "Attach original photos separately",
                    isOn: $settings.attachOriginalPhotos
                )
            } header: {
                Text("Export")
            } footer: {
                Text("PDF reports always include scaled photos. When this is on, the original JPEGs are attached as additional files.")
            }

            Section("Campus Reference") {
                NavigationLink {
                    LocationEditorView()
                } label: {
                    Label("Locations", systemImage: "map")
                }
            }

            Section("About") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About this app", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
    }
}
