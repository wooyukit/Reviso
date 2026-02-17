//
//  MockInpainter.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
@testable import Reviso

final class MockInpainter: InpainterProtocol {
    var mockResult: UIImage?
    var shouldThrowError = false
    var inpaintCallCount = 0

    func inpaint(image: UIImage, mask: UIImage) async throws -> UIImage {
        inpaintCallCount += 1
        if shouldThrowError {
            throw AnswerEraserError.inpaintingFailed
        }
        return mockResult ?? image
    }
}
