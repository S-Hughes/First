import Foundation

enum InspectionStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case inactive = "Inactive"

    var id: String { rawValue }

    var displayName: String { rawValue }
}
