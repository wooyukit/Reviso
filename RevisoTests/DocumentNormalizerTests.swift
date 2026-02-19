//
//  DocumentNormalizerTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 19/2/2026.
//

import Testing
import UIKit
@testable import Reviso

struct DocumentNormalizerTests {

    // MARK: - VisionDocumentNormalizer Tests

    @Test func normalize_withBlankImage_returnsValidImage() async throws {
        let normalizer = VisionDocumentNormalizer()
        let image = createTestImage(width: 400, height: 600)

        let result = try await normalizer.normalize(image)

        #expect(result.size.width > 0)
        #expect(result.size.height > 0)
    }

    @Test func normalize_withDocumentImage_returnsImage() async throws {
        let normalizer = VisionDocumentNormalizer()
        let image = createImageWithRectangle()

        let result = try await normalizer.normalize(image)

        #expect(result.size.width > 0)
        #expect(result.size.height > 0)
    }

    // MARK: - Mock Tests

    @Test func mockNormalizer_returnsConfiguredImage() async throws {
        let mock = MockDocumentNormalizer()
        let expected = createTestImage(width: 100, height: 100)
        mock.mockResult = expected

        let input = createTestImage(width: 200, height: 300)
        let result = try await mock.normalize(input)

        #expect(result.size.width == 100)
        #expect(result.size.height == 100)
        #expect(mock.normalizeCallCount == 1)
    }

    @Test func mockNormalizer_throwsError() async {
        let mock = MockDocumentNormalizer()
        mock.shouldThrowError = true

        let image = createTestImage(width: 200, height: 200)

        await #expect(throws: DocumentNormalizerError.self) {
            try await mock.normalize(image)
        }
    }

    @Test func mockNormalizer_defaultReturnsInputImage() async throws {
        let mock = MockDocumentNormalizer()
        let input = createTestImage(width: 250, height: 350)

        let result = try await mock.normalize(input)

        #expect(result.size.width == 250)
        #expect(result.size.height == 350)
        #expect(mock.normalizeCallCount == 1)
    }

    // MARK: - Helpers

    private func createTestImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createImageWithRectangle() -> UIImage {
        let size = CGSize(width: 600, height: 800)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.darkGray.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            UIColor.white.setFill()
            context.fill(CGRect(x: 50, y: 80, width: 500, height: 640))
        }
    }
}
