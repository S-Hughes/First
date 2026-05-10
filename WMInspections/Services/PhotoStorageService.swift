import Foundation
import UIKit

enum PhotoStorageService {
    private static let photosFolderName = "Photos"
    private static let thumbsFolderName = "Thumbnails"
    private static let thumbnailSize = CGSize(width: 200, height: 200)
    private static let jpegQuality: CGFloat = 0.85

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    static func photosDirectory() -> URL {
        let url = documentsDirectory().appendingPathComponent(photosFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func thumbnailsDirectory() -> URL {
        let url = documentsDirectory().appendingPathComponent(thumbsFolderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @discardableResult
    static func save(image: UIImage) -> String? {
        let filename = "\(UUID().uuidString).jpg"
        let fullURL = photosDirectory().appendingPathComponent(filename)
        let thumbURL = thumbnailsDirectory().appendingPathComponent(filename)

        guard let fullData = image.jpegData(compressionQuality: jpegQuality) else { return nil }

        do {
            try fullData.write(to: fullURL, options: .atomic)
        } catch {
            return nil
        }

        let thumb = image.aspectFillThumbnail(size: thumbnailSize)
        if let thumbData = thumb.jpegData(compressionQuality: jpegQuality) {
            try? thumbData.write(to: thumbURL, options: .atomic)
        }

        return filename
    }

    static func loadFullImage(filename: String) -> UIImage? {
        let url = photosDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    static func loadThumbnail(filename: String) -> UIImage? {
        let url = thumbnailsDirectory().appendingPathComponent(filename)
        if let image = UIImage(contentsOfFile: url.path) {
            return image
        }
        return loadFullImage(filename: filename)
    }

    static func fullImageURL(filename: String) -> URL {
        photosDirectory().appendingPathComponent(filename)
    }

    static func delete(filename: String) {
        let fullURL = photosDirectory().appendingPathComponent(filename)
        let thumbURL = thumbnailsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fullURL)
        try? FileManager.default.removeItem(at: thumbURL)
    }

    static func deleteAll(filenames: [String]) {
        filenames.forEach { delete(filename: $0) }
    }
}
