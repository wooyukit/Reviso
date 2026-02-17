//
//  AIHandwritingDetector.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
import Vision

/// Combined approach: AI identifies rough handwritten regions,
/// then Vision provides precise text boundaries within those regions.
final class AIHandwritingDetector: HandwritingDetectorProtocol {
    private let provider: AIProviderProtocol

    init(provider: AIProviderProtocol) {
        self.provider = provider
    }

    func detectHandwriting(in image: UIImage) async throws -> UIImage {
        // Run AI detection and Vision detection in parallel
        async let aiBoxes = detectWithAI(image: image)
        async let visionBoxes = detectWithVision(image: image)

        let roughRegions = try await aiBoxes
        let preciseTexts = try await visionBoxes

        // Combine: keep Vision text boxes that overlap with AI-identified handwriting regions
        // Also keep the AI boxes for areas Vision might have missed
        var erasureBoxes: [CGRect] = []

        for visionBox in preciseTexts {
            for aiBox in roughRegions {
                if visionBox.intersects(aiBox) {
                    erasureBoxes.append(visionBox)
                    break
                }
            }
        }

        // Also add AI boxes that don't overlap with any Vision text
        // (catches handwriting that Vision couldn't OCR)
        for aiBox in roughRegions {
            let hasVisionOverlap = preciseTexts.contains { $0.intersects(aiBox) }
            if !hasVisionOverlap {
                erasureBoxes.append(aiBox)
            }
        }

        return renderMask(boxes: erasureBoxes, imageSize: image.size)
    }

    // MARK: - AI Detection (rough but semantically correct regions)

    private func detectWithAI(image: UIImage) async throws -> [CGRect] {
        let prompt = """
        Analyze this worksheet/homework image carefully. \
        Identify ALL regions containing HANDWRITTEN text written by a student.

        Handwritten text includes:
        - Student's name filled in by hand
        - Date written by hand
        - Class/grade number written by hand
        - Answers written on blank lines
        - Circled choices or tick marks
        - Any drawings or marks made by hand
        - ANY text that appears handwritten (different style from the clean printed text)

        Do NOT include:
        - Printed/typed questions, headings, instructions
        - Pre-printed form labels
        - Decorative borders or frames

        Return a JSON array of bounding boxes using normalized coordinates (0.0 to 1.0).
        Be very precise and return MANY small tight boxes (one per handwritten element), \
        not a few large boxes.

        Format: [{"x": 0.1, "y": 0.2, "w": 0.15, "h": 0.03}]
        Where x,y = top-left corner, w = width, h = height, all as fractions of image size.
        Return ONLY the JSON array.
        """

        let response = try await provider.send(prompt: prompt, image: image)
        return try parseAIBoxes(from: response, imageSize: image.size)
    }

    private func parseAIBoxes(from response: String, imageSize: CGSize) throws -> [CGRect] {
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
            return []
        }

        let decoded = (try? JSONDecoder().decode([AIBox].self, from: data)) ?? []
        return decoded.map { box in
            CGRect(
                x: box.x * imageSize.width,
                y: box.y * imageSize.height,
                width: box.w * imageSize.width,
                height: box.h * imageSize.height
            )
        }
    }

    // MARK: - Vision Detection (precise text bounding boxes)

    private func detectWithVision(image: UIImage) async throws -> [CGRect] {
        guard let cgImage = image.cgImage else { return [] }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let boxes = observations.map { obs -> CGRect in
                    let vb = obs.boundingBox
                    return CGRect(
                        x: vb.origin.x * imageSize.width,
                        y: (1.0 - vb.origin.y - vb.height) * imageSize.height,
                        width: vb.width * imageSize.width,
                        height: vb.height * imageSize.height
                    )
                }

                continuation.resume(returning: boxes)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Mask Rendering

    private func renderMask(boxes: [CGRect], imageSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            UIColor.white.setFill()
            for box in boxes {
                let padded = box.insetBy(dx: -8, dy: -6)
                context.fill(padded)
            }
        }
    }
}

private struct AIBox: Decodable {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
}
