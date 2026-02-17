//
//  ImageUtils.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum ImageUtils {

    /// Resize image so neither dimension exceeds maxDimension, preserving aspect ratio.
    static func resizeForProcessing(_ image: UIImage, maxDimension: CGFloat = 1568) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Convert UIImage to base64-encoded JPEG string.
    static func toBase64JPEG(_ image: UIImage, compressionQuality: CGFloat = 0.8) -> String? {
        image.jpegData(compressionQuality: compressionQuality)?.base64EncodedString()
    }

    /// Normalize image orientation to `.up` to avoid rotated processing.
    static func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { _ in
            image.draw(at: .zero)
        }
    }
}
