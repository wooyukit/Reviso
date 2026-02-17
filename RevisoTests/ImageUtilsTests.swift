//
//  ImageUtilsTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import UIKit
@testable import Reviso

struct ImageUtilsTests {

    @Test func resizeImage_withinLimit_returnsOriginalSize() {
        let image = createTestImage(width: 800, height: 600)
        let resized = ImageUtils.resizeForProcessing(image, maxDimension: 1568)

        #expect(resized.size.width == 800)
        #expect(resized.size.height == 600)
    }

    @Test func resizeImage_exceedsLimit_scalesDown() {
        let image = createTestImage(width: 3000, height: 2000)
        let resized = ImageUtils.resizeForProcessing(image, maxDimension: 1568)

        #expect(resized.size.width <= 1568)
        #expect(resized.size.height <= 1568)
        // Aspect ratio preserved
        let originalRatio = 3000.0 / 2000.0
        let resizedRatio = resized.size.width / resized.size.height
        #expect(abs(originalRatio - resizedRatio) < 0.01)
    }

    @Test func resizeImage_tallImage_scalesCorrectly() {
        let image = createTestImage(width: 1000, height: 4000)
        let resized = ImageUtils.resizeForProcessing(image, maxDimension: 1568)

        #expect(resized.size.height <= 1568)
        #expect(resized.size.width < resized.size.height)
    }

    @Test func imageToBase64_producesValidString() {
        let image = createTestImage(width: 100, height: 100)
        let base64 = ImageUtils.toBase64JPEG(image, compressionQuality: 0.8)

        #expect(base64 != nil)
        #expect(!base64!.isEmpty)
        // Should be valid base64
        #expect(Data(base64Encoded: base64!) != nil)
    }

    @Test func normalizeOrientation_returnsImage() {
        let image = createTestImage(width: 200, height: 300)
        let normalized = ImageUtils.normalizeOrientation(image)

        #expect(normalized.size.width > 0)
        #expect(normalized.size.height > 0)
    }

    // MARK: - Helpers

    private func createTestImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
