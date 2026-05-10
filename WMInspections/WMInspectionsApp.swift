import SwiftUI
import SwiftData

@main
struct WMInspectionsApp: App {
    let container: ModelContainer
    @StateObject private var settings = AppSettings()

    init() {
        AppSettings.registerDefaults()
        do {
            container = try ModelContainer(for: InspectionRecord.self, CampusLocation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        CampusLocationLoader.seedIfNeeded(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settings)
        }
        .modelContainer(container)
    }
}
