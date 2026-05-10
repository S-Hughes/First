import SwiftUI
import PhotosUI

struct PhotoPickerCoordinator: UIViewControllerRepresentable {
    @Binding var photoFilenames: [String]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        let controller = PHPickerViewController(configuration: config)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerCoordinator

        init(_ parent: PhotoPickerCoordinator) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let providers = results.map(\.itemProvider)
            let group = DispatchGroup()
            var newFilenames: [String] = []
            let lock = NSLock()

            for provider in providers where provider.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    defer { group.leave() }
                    guard let image = object as? UIImage else { return }
                    if let filename = PhotoStorageService.save(image: image) {
                        lock.lock()
                        newFilenames.append(filename)
                        lock.unlock()
                    }
                }
            }

            group.notify(queue: .main) { [weak picker] in
                self.parent.photoFilenames.append(contentsOf: newFilenames)
                picker?.dismiss(animated: true)
            }
        }
    }
}
