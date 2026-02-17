//
//  AnswerEraserTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import UIKit
@testable import Reviso

struct AnswerEraserTests {

    private func createTestImage(width: Int = 200, height: Int = 300) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createMaskWithRegions(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Black background (no handwriting)
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            // White region (detected handwriting)
            UIColor.white.setFill()
            context.fill(CGRect(x: 50, y: 50, width: 100, height: 30))
        }
    }

    @Test func eraseAnswers_callsDetectorAndInpainter() async throws {
        let detector = MockHandwritingDetector()
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)

        let image = createTestImage()
        let mask = createMaskWithRegions(size: image.size)
        detector.mockMask = mask

        _ = try await eraser.eraseAnswers(from: image)

        #expect(detector.detectCallCount == 1)
        #expect(inpainter.inpaintCallCount == 1)
    }

    @Test func eraseAnswers_returnsProcessedImage() async throws {
        let detector = MockHandwritingDetector()
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)

        let image = createTestImage()
        let expectedResult = createTestImage(width: 200, height: 300)
        inpainter.mockResult = expectedResult

        let result = try await eraser.eraseAnswers(from: image)

        #expect(result.size.width == expectedResult.size.width)
        #expect(result.size.height == expectedResult.size.height)
    }

    @Test func eraseAnswers_detectionError_throws() async {
        let detector = MockHandwritingDetector()
        detector.shouldThrowError = true
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)

        let image = createTestImage()

        await #expect(throws: AnswerEraserError.self) {
            try await eraser.eraseAnswers(from: image)
        }
        #expect(inpainter.inpaintCallCount == 0)
    }

    @Test func eraseAnswers_inpaintingError_throws() async {
        let detector = MockHandwritingDetector()
        let inpainter = MockInpainter()
        inpainter.shouldThrowError = true
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)

        let image = createTestImage()

        await #expect(throws: AnswerEraserError.self) {
            try await eraser.eraseAnswers(from: image)
        }
    }

    @Test func eraseAnswers_noHandwriting_returnsOriginal() async throws {
        let detector = MockHandwritingDetector()
        // Mock returns all-black mask (no handwriting detected)
        detector.mockMask = nil
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)

        let image = createTestImage()
        let result = try await eraser.eraseAnswers(from: image)

        #expect(result.size == image.size)
    }
}
