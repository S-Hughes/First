import Foundation

enum InspectionCategory: String, Codable, CaseIterable, Identifiable {
    case safety = "Safety"
    case cleanliness = "Cleanliness"
    case maintenance = "Maintenance"
    case landscaping = "Landscaping"
    case accessibility = "Accessibility"
    case other = "Other"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var symbolName: String {
        switch self {
        case .safety: return "exclamationmark.shield.fill"
        case .cleanliness: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .landscaping: return "leaf.fill"
        case .accessibility: return "figure.roll"
        case .other: return "questionmark.circle"
        }
    }
}
