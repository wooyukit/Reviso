//
//  ImageUtils.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum ImageUtils {

    /// Resize image so neither dimension exceeds maxDimension, preserving aspect ratio.
    /// Uses Core Graphics directly so it is safe to call from any thread.
    static func resizeForProcessing(_ image: UIImage, maxDimension: CGFloat = 1568) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let pixelWidth = CGFloat(cgImage.width)
        let pixelHeight = CGFloat(cgImage.height)

        guard pixelWidth > maxDimension || pixelHeight > maxDimension else {
            return image
        }

        let scale = min(maxDimension / pixelWidth, maxDimension / pixelHeight)
        let newWidth = Int(pixelWidth * scale)
        let newHeight = Int(pixelHeight * scale)

        let colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        ) else {
            return image
        }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        guard let resizedCG = context.makeImage() else { return image }
        return UIImage(cgImage: resizedCG)
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
