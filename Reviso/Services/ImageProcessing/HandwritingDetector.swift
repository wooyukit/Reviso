//
//  HandwritingDetector.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

protocol HandwritingDetectorProtocol {
    /// Detect handwritten regions in an image.
    /// Returns a binary mask where white = handwriting, black = background/printed text.
    func detectHandwriting(in image: UIImage) async throws -> UIImage
}

/// Core ML-based handwriting detector.
/// Uses a segmentation model to distinguish handwritten text from printed text.
/// The actual Core ML model will be plugged in when available.
final class CoreMLHandwritingDetector: HandwritingDetectorProtocol {

    func detectHandwriting(in image: UIImage) async throws -> UIImage {
        // TODO: Load and run Core ML segmentation model
        // 1. Preprocess image to model's expected input size
        // 2. Run inference with Core ML
        // 3. Post-process output to binary mask
        // 4. Resize mask back to original image dimensions
        throw AnswerEraserError.modelNotAvailable
    }
}
