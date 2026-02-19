//
//  DocumentNormalizer.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 19/2/2026.
//

import UIKit
import Vision
import CoreImage

enum DocumentNormalizerError: Error {
    case imageConversionFailed
}

protocol DocumentNormalizerProtocol {
    func normalize(_ image: UIImage) async throws -> UIImage
}

final class VisionDocumentNormalizer: DocumentNormalizerProtocol {
    private let ciContext = CIContext()

    func normalize(_ image: UIImage) async throws -> UIImage {
        let oriented = ImageUtils.normalizeOrientation(image)
        guard let cgImage = oriented.cgImage else {
            throw DocumentNormalizerError.imageConversionFailed
        }

        guard let observation = try detectDocument(in: cgImage) else {
            return oriented
        }

        return applyPerspectiveCorrection(to: oriented, using: observation)
    }

    private func detectDocument(in cgImage: CGImage) throws -> VNRectangleObservation? {
        let request = VNDetectDocumentSegmentationRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        return request.results?.first as? VNRectangleObservation
    }

    private func applyPerspectiveCorrection(
        to image: UIImage,
        using observation: VNRectangleObservation
    ) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let ciImage = CIImage(cgImage: cgImage)
        let width = ciImage.extent.width
        let height = ciImage.extent.height

        let topLeft = CIVector(x: observation.topLeft.x * width,
                               y: observation.topLeft.y * height)
        let topRight = CIVector(x: observation.topRight.x * width,
                                y: observation.topRight.y * height)
        let bottomLeft = CIVector(x: observation.bottomLeft.x * width,
                                  y: observation.bottomLeft.y * height)
        let bottomRight = CIVector(x: observation.bottomRight.x * width,
                                   y: observation.bottomRight.y * height)

        guard let filter = CIFilter(name: "CIPerspectiveCorrection") else {
            return image
        }
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(topLeft, forKey: "inputTopLeft")
        filter.setValue(topRight, forKey: "inputTopRight")
        filter.setValue(bottomLeft, forKey: "inputBottomLeft")
        filter.setValue(bottomRight, forKey: "inputBottomRight")

        guard let outputCIImage = filter.outputImage,
              let outputCGImage = ciContext.createCGImage(outputCIImage, from: outputCIImage.extent)
        else {
            return image
        }

        return UIImage(cgImage: outputCGImage)
    }
}
