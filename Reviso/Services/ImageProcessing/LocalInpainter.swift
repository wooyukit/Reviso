//
//  LocalInpainter.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
import CoreImage

/// Fills masked regions using CIBlendWithMask for fast, correct compositing.
/// Mask convention: white = regions to fill, black = keep original.
final class LocalInpainter: InpainterProtocol {

    private let ciContext = CIContext()

    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage {
        guard let ciOriginal = CIImage(image: image),
              let ciMask = CIImage(image: mask) else {
            throw AnswerEraserError.inpaintingFailed
        }

        // Create a white fill image matching the original size
        let whiteFill = CIImage(color: .white).cropped(to: ciOriginal.extent)

        // CIBlendWithMask:
        // - inputImage (foreground): shown where mask is WHITE
        // - inputBackgroundImage: shown where mask is BLACK
        // So: white fill where mask=white, original where mask=black
        guard let filter = CIFilter(name: "CIBlendWithMask") else {
            throw AnswerEraserError.inpaintingFailed
        }

        filter.setValue(whiteFill, forKey: kCIInputImageKey)
        filter.setValue(ciOriginal, forKey: kCIInputBackgroundImageKey)
        filter.setValue(ciMask, forKey: kCIInputMaskImageKey)

        guard let output = filter.outputImage,
              let cgResult = ciContext.createCGImage(output, from: ciOriginal.extent) else {
            throw AnswerEraserError.inpaintingFailed
        }

        return UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
    }
}
