import Foundation
import SwiftData

enum CampusLocationLoader {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<CampusLocation>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let seed = loadSeed() else { return }

        var order = 0
        for group in seed.groups {
            for entry in group.locations {
                let row = CampusLocation(
                    groupName: group.name,
                    name: entry.name,
                    subLocations: entry.subLocations,
                    isUserCreated: false,
                    sortOrder: order
                )
                context.insert(row)
                order += 1
            }
        }

        try? context.save()
    }

    static func loadSeed() -> CampusLocationSeed? {
        guard let url = Bundle.main.url(forResource: "CampusLocations", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(CampusLocationSeed.self, from: data)
        } catch {
            return nil
        }
    }
}
