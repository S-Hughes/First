import UIKit

extension UIImage {
    func aspectFillThumbnail(size: CGSize) -> UIImage {
        let aspectWidth = size.width / self.size.width
        let aspectHeight = size.height / self.size.height
        let scale = max(aspectWidth, aspectHeight)
        let scaledSize = CGSize(width: self.size.width * scale, height: self.size.height * scale)
        let origin = CGPoint(x: (size.width - scaledSize.width) / 2,
                             y: (size.height - scaledSize.height) / 2)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: origin, size: scaledSize))
        }
    }
}
