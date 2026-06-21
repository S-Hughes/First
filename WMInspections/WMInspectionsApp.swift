import SwiftUI
import SwiftData

@main
struct WMInspectionsApp: App {
    let container: ModelContainer
    @State private var settings = AppSettings()

    init() {
        AppSettings.registerDefaults()
        do {
            container = try ModelContainer(for: InspectionRecord.self, CampusLocation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        CampusLocationLoader.seedIfNeeded(context: container.mainContext)
        EmailComposer.sweepStaleTempExports()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(settings)
        }
        .modelContainer(container)
    }
}
