import Foundation
import SwiftData

@Model
final class InspectionRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var location: String
    var subLocation: String?
    var categoryRaw: String
    var notes: String
    var statusRaw: String
    var photoFilenames: [String]
    var createdDate: Date
    var lastModifiedDate: Date
    var closedDate: Date?

    init(
        location: String,
        subLocation: String? = nil,
        category: InspectionCategory = .other,
        notes: String = "",
        photoFilenames: [String] = []
    ) {
        let now = Date()
        self.id = UUID()
        self.timestamp = now
        self.location = location
        self.subLocation = subLocation
        self.categoryRaw = category.rawValue
        self.notes = notes
        self.statusRaw = InspectionStatus.active.rawValue
        self.photoFilenames = photoFilenames
        self.createdDate = now
        self.lastModifiedDate = now
        self.closedDate = nil
    }

    var category: InspectionCategory {
        get { InspectionCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var status: InspectionStatus {
        get { InspectionStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    func close() {
        status = .inactive
        closedDate = Date()
        lastModifiedDate = Date()
    }

    func reopen() {
        status = .active
        closedDate = nil
        lastModifiedDate = Date()
    }

    func touch() {
        lastModifiedDate = Date()
    }
}
