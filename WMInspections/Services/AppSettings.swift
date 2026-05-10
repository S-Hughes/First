import Foundation
import SwiftUI

final class AppSettings: ObservableObject {
    static let defaultEmailKey = "defaultEmail"
    static let attachOriginalPhotosKey = "attachOriginalPhotos"
    static let initialDefaultEmail = "schughes@wm.edu"

    @AppStorage(defaultEmailKey) var defaultEmail: String = initialDefaultEmail
    @AppStorage(attachOriginalPhotosKey) var attachOriginalPhotos: Bool = false

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            defaultEmailKey: initialDefaultEmail,
            attachOriginalPhotosKey: false
        ])
    }
}
