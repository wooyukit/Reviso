//
//  LocalInpainter.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

/// Fills masked regions by sampling the surrounding background color.
/// Mask convention: white = regions to fill, black = keep original.
final class LocalInpainter: InpainterProtocol {

    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage {
        guard let cgImage = image.cgImage, let maskCG = mask.cgImage else {
            throw AnswerEraserError.inpaintingFailed
        }

        let width = cgImage.width
        let height = cgImage.height

        // Create bitmap contexts for reading pixel data
        guard let imageContext = createContext(for: cgImage, width: width, height: height),
              let maskContext = createContext(for: maskCG, width: width, height: height) else {
            throw AnswerEraserError.inpaintingFailed
        }

        imageContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        maskContext.draw(maskCG, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let imageData = imageContext.data,
              let maskData = maskContext.data else {
            throw AnswerEraserError.inpaintingFailed
        }

        let imagePixels = imageData.bindMemory(to: UInt8.self, capacity: width * height * 4)
        let maskPixels = maskData.bindMemory(to: UInt8.self, capacity: width * height * 4)

        // For each masked (white) region, sample surrounding background color and fill
        for y in 0..<height {
            for x in 0..<width {
                let idx = (y * width + x) * 4
                // Check if mask pixel is white (region to fill)
                let maskR = maskPixels[idx]
                if maskR > 128 {
                    // Sample background color from nearest non-masked pixel
                    let bg = sampleBackground(
                        imagePixels: imagePixels,
                        maskPixels: maskPixels,
                        x: x, y: y,
                        width: width, height: height
                    )
                    imagePixels[idx] = bg.r
                    imagePixels[idx + 1] = bg.g
                    imagePixels[idx + 2] = bg.b
                    // Keep alpha
                }
            }
        }

        guard let resultCG = imageContext.makeImage() else {
            throw AnswerEraserError.inpaintingFailed
        }

        return UIImage(cgImage: resultCG, scale: image.scale, orientation: image.imageOrientation)
    }

    private func createContext(for image: CGImage, width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    private struct PixelColor {
        let r: UInt8
        let g: UInt8
        let b: UInt8
    }

    /// Sample background color by looking outward from a masked pixel for the nearest non-masked pixel.
    private func sampleBackground(
        imagePixels: UnsafeMutablePointer<UInt8>,
        maskPixels: UnsafeMutablePointer<UInt8>,
        x: Int, y: Int,
        width: Int, height: Int
    ) -> PixelColor {
        // Search in expanding rings for non-masked pixels
        for radius in 1...50 {
            var totalR = 0, totalG = 0, totalB = 0, count = 0

            for dy in -radius...radius {
                for dx in -radius...radius {
                    // Only check the border of the ring
                    guard abs(dx) == radius || abs(dy) == radius else { continue }

                    let nx = x + dx
                    let ny = y + dy
                    guard nx >= 0, nx < width, ny >= 0, ny < height else { continue }

                    let nIdx = (ny * width + nx) * 4
                    if maskPixels[nIdx] <= 128 {
                        totalR += Int(imagePixels[nIdx])
                        totalG += Int(imagePixels[nIdx + 1])
                        totalB += Int(imagePixels[nIdx + 2])
                        count += 1
                    }
                }
            }

            if count > 0 {
                return PixelColor(
                    r: UInt8(totalR / count),
                    g: UInt8(totalG / count),
                    b: UInt8(totalB / count)
                )
            }
        }

        // Fallback: white background
        return PixelColor(r: 255, g: 255, b: 255)
    }
}
