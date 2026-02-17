//
//  AIHandwritingDetector.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
import Vision

/// Hybrid handwriting detector: uses Apple Vision for precise text bounding boxes,
/// then an AI provider to classify which text blocks are handwritten answers.
final class AIHandwritingDetector: HandwritingDetectorProtocol {
    private let provider: AIProviderProtocol

    init(provider: AIProviderProtocol) {
        self.provider = provider
    }

    func detectHandwriting(in image: UIImage) async throws -> UIImage {
        // Step 1: Use Vision to find all text regions with precise bounding boxes
        let textBlocks = try await detectTextBlocks(in: image)

        guard !textBlocks.isEmpty else {
            // No text found - return empty mask (all black = keep everything)
            return renderMask(boxes: [], imageSize: image.size)
        }

        // Step 2: Ask AI which text blocks are handwritten answers
        let handwrittenIndices = try await classifyHandwriting(
            textBlocks: textBlocks,
            image: image
        )

        // Step 3: Build mask from the bounding boxes of handwritten text
        let handwrittenBoxes = handwrittenIndices.compactMap { index -> CGRect? in
            guard index >= 0 && index < textBlocks.count else { return nil }
            return textBlocks[index].bounds
        }

        return renderMask(boxes: handwrittenBoxes, imageSize: image.size)
    }

    // MARK: - Vision Text Detection

    private struct TextBlock {
        let index: Int
        let text: String
        let bounds: CGRect // In image coordinates (top-left origin)
    }

    private func detectTextBlocks(in image: UIImage) async throws -> [TextBlock] {
        guard let cgImage = image.cgImage else {
            throw AnswerEraserError.detectionFailed
        }

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

                let imageSize = CGSize(
                    width: cgImage.width,
                    height: cgImage.height
                )

                let blocks = observations.enumerated().compactMap { index, obs -> TextBlock? in
                    guard let candidate = obs.topCandidates(1).first else { return nil }

                    // Convert Vision coordinates (bottom-left, normalized) to image coordinates (top-left, pixels)
                    let visionBox = obs.boundingBox
                    let bounds = CGRect(
                        x: visionBox.origin.x * imageSize.width,
                        y: (1.0 - visionBox.origin.y - visionBox.height) * imageSize.height,
                        width: visionBox.width * imageSize.width,
                        height: visionBox.height * imageSize.height
                    )

                    return TextBlock(index: index, text: candidate.string, bounds: bounds)
                }

                continuation.resume(returning: blocks)
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

    // MARK: - AI Classification

    private func classifyHandwriting(textBlocks: [TextBlock], image: UIImage) async throws -> [Int] {
        let textList = textBlocks.map { "[\($0.index)] \"\($0.text)\"" }.joined(separator: "\n")

        let prompt = """
        This is a worksheet image. Below is a numbered list of all text detected in the image.
        Identify which ones are HANDWRITTEN ANSWERS written by a student \
        (NOT printed text like questions, instructions, labels, or headings).

        Handwritten answers typically include:
        - Student's name, date, class number filled in by hand
        - Written answers on blank lines
        - Circled or marked choices
        - Any text that looks handwritten rather than printed/typed

        TEXT BLOCKS:
        \(textList)

        Return ONLY a JSON array of the INDEX numbers of handwritten answers.
        Example: [0, 3, 5]
        If no handwritten answers found, return [].
        Return ONLY the JSON array, no other text.
        """

        let response = try await provider.send(prompt: prompt, image: image)
        return try parseIndices(from: response)
    }

    private func parseIndices(from response: String) throws -> [Int] {
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

        return (try? JSONDecoder().decode([Int].self, from: data)) ?? []
    }

    // MARK: - Mask Rendering

    private func renderMask(boxes: [CGRect], imageSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: imageSize)
        return renderer.image { context in
            // Black background (keep regions)
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: imageSize))

            // White rectangles (erase regions)
            UIColor.white.setFill()
            for box in boxes {
                // Add padding around detected text for cleaner erasure
                let padded = box.insetBy(dx: -6, dy: -4)
                context.fill(padded)
            }
        }
    }
}
