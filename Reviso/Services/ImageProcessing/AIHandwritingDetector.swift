//
//  AIHandwritingDetector.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

/// Uses an AI vision provider to detect handwritten answer regions in a worksheet.
/// Returns a binary mask image where white = handwritten answers, black = keep.
final class AIHandwritingDetector: HandwritingDetectorProtocol {
    private let provider: AIProviderProtocol

    init(provider: AIProviderProtocol) {
        self.provider = provider
    }

    func detectHandwriting(in image: UIImage) async throws -> UIImage {
        let prompt = """
        Analyze this worksheet image. Identify all regions containing handwritten answers \
        (NOT printed text like questions, instructions, or labels).

        Return ONLY a valid JSON array of bounding boxes for each handwritten answer region. \
        Use normalized coordinates (0.0 to 1.0) relative to the image dimensions:

        [
            {"x": 0.1, "y": 0.2, "width": 0.3, "height": 0.05}
        ]

        Where x,y is the top-left corner. If no handwritten answers are found, return [].
        Return ONLY the JSON array, no other text.
        """

        let response = try await provider.send(prompt: prompt, image: image)
        let boxes = try parseBoundingBoxes(from: response)
        return renderMask(boxes: boxes, imageSize: image.size)
    }

    private func parseBoundingBoxes(from response: String) throws -> [CGRect] {
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw AnswerEraserError.detectionFailed
        }

        let decoded = try JSONDecoder().decode([BoundingBox].self, from: data)
        return decoded.map { box in
            CGRect(x: box.x, y: box.y, width: box.width, height: box.height)
        }
    }

    private func renderMask(boxes: [CGRect], imageSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // Black background (keep regions)
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            // White rectangles (erase regions)
            UIColor.white.setFill()
            for box in boxes {
                let rect = CGRect(
                    x: box.origin.x * imageSize.width,
                    y: box.origin.y * imageSize.height,
                    width: box.size.width * imageSize.width,
                    height: box.size.height * imageSize.height
                )
                // Add small padding around detected regions
                let padded = rect.insetBy(dx: -4, dy: -4)
                context.fill(padded)
            }
        }
    }
}

private struct BoundingBox: Decodable {
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}
