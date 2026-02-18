//
//  AnswerEraserTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import UIKit
@testable import Reviso

@Suite(.serialized)
struct AnswerEraserTests {

    @MainActor
    private func createTestImage(width: Int = 200, height: Int = 300) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    @Test @MainActor func eraseAnswers_callsCleanImage() async throws {
        let tracker = CallTracker()
        let eraser = AnswerEraser { image in
            await tracker.increment()
            return image
        }

        let image = createTestImage()
        _ = try await eraser.eraseAnswers(from: image)

        let count = await tracker.count
        #expect(count == 1)
    }

    @Test @MainActor func eraseAnswers_returnsProcessedImage() async throws {
        let expectedResult = createTestImage(width: 100, height: 100)
        let eraser = AnswerEraser { _ in
            return expectedResult
        }

        let image = createTestImage()
        let result = try await eraser.eraseAnswers(from: image)

        #expect(result.size.width == expectedResult.size.width)
        #expect(result.size.height == expectedResult.size.height)
    }

    @Test @MainActor func eraseAnswers_error_throws() async {
        let eraser = AnswerEraser { _ in
            throw AnswerEraserError.inpaintingFailed
        }

        let image = createTestImage()

        await #expect(throws: AnswerEraserError.self) {
            try await eraser.eraseAnswers(from: image)
        }
    }

}

// MARK: - Thread-safe helpers

private actor CallTracker {
    var count = 0
    func increment() { count += 1 }
}
