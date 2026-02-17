//
//  AnswerEraser.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum AnswerEraserError: Error {
    case detectionFailed
    case inpaintingFailed
    case modelNotAvailable
}

protocol InpainterProtocol {
    /// Fill masked regions of an image naturally.
    /// Mask: white = regions to fill, black = keep original.
    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage
}

/// LaMa-based inpainter using Core ML.
/// The actual Core ML model will be plugged in when available.
final class CoreMLInpainter: InpainterProtocol {

    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage {
        // TODO: Load and run LaMa Core ML model
        // 1. Resize image and mask to model's expected input
        // 2. Run inference
        // 3. Resize result back to original dimensions
        throw AnswerEraserError.modelNotAvailable
    }
}

/// Orchestrates the answer erasing pipeline: detect handwriting → inpaint.
final class AnswerEraser {
    private let detector: HandwritingDetectorProtocol
    private let inpainter: InpainterProtocol

    init(detector: HandwritingDetectorProtocol, inpainter: InpainterProtocol) {
        self.detector = detector
        self.inpainter = inpainter
    }

    /// Erase handwritten answers from a worksheet image.
    /// Returns the cleaned image with answers removed.
    func eraseAnswers(from image: UIImage) async throws -> UIImage {
        let mask = try await detector.detectHandwriting(in: image)
        let result = try await inpainter.inpaint(image: image, mask: mask)
        return result
    }
}
