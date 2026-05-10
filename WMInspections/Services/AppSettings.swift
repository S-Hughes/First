import Foundation
import Observation

@Observable
final class AppSettings {
    static let defaultEmailKey = "defaultEmail"
    static let attachOriginalPhotosKey = "attachOriginalPhotos"
    static let initialDefaultEmail = "schughes@wm.edu"

    var defaultEmail: String {
        didSet { UserDefaults.standard.set(defaultEmail, forKey: Self.defaultEmailKey) }
    }

    var attachOriginalPhotos: Bool {
        didSet { UserDefaults.standard.set(attachOriginalPhotos, forKey: Self.attachOriginalPhotosKey) }
    }

    init() {
        let defaults = UserDefaults.standard
        defaultEmail = defaults.string(forKey: Self.defaultEmailKey) ?? Self.initialDefaultEmail
        attachOriginalPhotos = defaults.bool(forKey: Self.attachOriginalPhotosKey)
    }

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            defaultEmailKey: initialDefaultEmail,
            attachOriginalPhotosKey: false
        ])
    }
}
