//
//  MockHandwritingDetector.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
@testable import Reviso

final class MockHandwritingDetector: HandwritingDetectorProtocol {
    var mockMask: UIImage?
    var shouldThrowError = false
    var detectCallCount = 0

    func detectHandwriting(in image: UIImage) async throws -> UIImage {
        detectCallCount += 1
        if shouldThrowError {
            throw AnswerEraserError.detectionFailed
        }
        return mockMask ?? createEmptyMask(size: image.size)
    }

    private func createEmptyMask(size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
