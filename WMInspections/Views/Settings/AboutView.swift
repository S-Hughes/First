import SwiftUI

struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let short = info["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("App", value: "W&M Inspections")
                LabeledContent("Version", value: version)
            }
            Section("Purpose") {
                Text("Record \"Management By Walking Around\" inspections of the William & Mary campus. Data stays on this device and is shared via email.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
