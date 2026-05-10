import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let itemURLs: [URL]
    var onFinish: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemURLs, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            cleanup(urls: itemURLs)
            onFinish?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        guard let popover = uiViewController.popoverPresentationController else { return }
        if popover.sourceView == nil,
           let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) {
            popover.sourceView = window
            popover.sourceRect = CGRect(
                x: window.bounds.midX,
                y: window.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
    }

    private func cleanup(urls: [URL]) {
        var parents = Set<URL>()
        for url in urls {
            try? FileManager.default.removeItem(at: url)
            parents.insert(url.deletingLastPathComponent())
        }
        for parent in parents {
            try? FileManager.default.removeItem(at: parent)
        }
    }
}
