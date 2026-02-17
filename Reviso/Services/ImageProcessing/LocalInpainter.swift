//
//  LocalInpainter.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

/// Fills masked regions using fast Core Graphics compositing.
/// Mask convention: white = regions to fill, black = keep original.
final class LocalInpainter: InpainterProtocol {

    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage {
        guard let maskCG = mask.cgImage else {
            throw AnswerEraserError.inpaintingFailed
        }

        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)

        let result = renderer.image { context in
            let cgContext = context.cgContext
            let rect = CGRect(origin: .zero, size: size)

            // Draw the original image
            image.draw(in: rect)

            // Use the mask to clip: white areas in mask = where we draw the fill
            // CGContext.clip(to:mask:) treats white as opaque, black as transparent
            cgContext.saveGState()
            cgContext.clip(to: rect, mask: maskCG)

            // Fill masked areas with white (matches typical worksheet paper)
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(rect)

            cgContext.restoreGState()
        }

        return result
    }
}
