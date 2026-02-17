//
//  TextRecognitionServiceTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import UIKit
@testable import Reviso

struct TextRecognitionServiceTests {

    @Test func recognizeText_withTextImage_returnsText() async throws {
        let service = VisionTextRecognitionService()
        let image = createImageWithText("Hello World")

        let result = try await service.recognizeText(in: image)

        // Vision may not perfectly OCR rendered text in tests,
        // but should return a non-empty string for clear text
        #expect(!result.isEmpty)
    }

    @Test func recognizeText_withBlankImage_returnsEmpty() async throws {
        let service = VisionTextRecognitionService()
        let image = createBlankImage()

        let result = try await service.recognizeText(in: image)

        #expect(result.isEmpty)
    }

    @Test func mockService_returnsConfiguredText() async throws {
        let mock = MockTextRecognitionService()
        mock.mockText = "1. What is 2+2?\n2. What is 3+3?"

        let image = createBlankImage()
        let result = try await mock.recognizeText(in: image)

        #expect(result == "1. What is 2+2?\n2. What is 3+3?")
        #expect(mock.recognizeCallCount == 1)
    }

    @Test func mockService_throwsError() async {
        let mock = MockTextRecognitionService()
        mock.shouldThrowError = true

        let image = createBlankImage()

        await #expect(throws: TextRecognitionError.self) {
            try await mock.recognizeText(in: image)
        }
    }

    // MARK: - Helpers

    private func createImageWithText(_ text: String) -> UIImage {
        let size = CGSize(width: 400, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32),
                .foregroundColor: UIColor.black
            ]
            let nsText = text as NSString
            nsText.draw(at: CGPoint(x: 20, y: 80), withAttributes: attributes)
        }
    }

    private func createBlankImage() -> UIImage {
        let size = CGSize(width: 200, height: 200)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
