import SwiftUI
import UIKit

struct ShareSheetView: UIViewControllerRepresentable {
    let itemURLs: [URL]
    var onFinish: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: itemURLs, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in
            onFinish?()
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
