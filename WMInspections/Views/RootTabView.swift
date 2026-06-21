import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                InspectionListView(statusFilter: .active)
            }
            .tabItem {
                Label("Active", systemImage: "checklist")
            }

            NavigationStack {
                InspectionListView(statusFilter: .inactive)
            }
            .tabItem {
                Label("Inactive", systemImage: "archivebox")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}
