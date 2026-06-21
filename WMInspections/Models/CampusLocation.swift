import Foundation
import SwiftData

@Model
final class CampusLocation {
    @Attribute(.unique) var id: UUID
    var groupName: String
    var name: String
    var subLocations: [String]
    var isUserCreated: Bool
    var sortOrder: Int

    init(
        groupName: String,
        name: String,
        subLocations: [String] = [],
        isUserCreated: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.groupName = groupName
        self.name = name
        self.subLocations = subLocations
        self.isUserCreated = isUserCreated
        self.sortOrder = sortOrder
    }
}

struct CampusLocationSeed: Codable {
    struct Group: Codable {
        let name: String
        let locations: [Entry]
    }
    struct Entry: Codable {
        let name: String
        let subLocations: [String]
    }
    let groups: [Group]
}
