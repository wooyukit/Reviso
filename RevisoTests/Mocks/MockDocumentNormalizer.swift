//
//  MockDocumentNormalizer.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 19/2/2026.
//

import UIKit
@testable import Reviso

final class MockDocumentNormalizer: DocumentNormalizerProtocol {
    var mockResult: UIImage?
    var shouldThrowError = false
    var normalizeCallCount = 0
    var lastImage: UIImage?

    func normalize(_ image: UIImage) async throws -> UIImage {
        normalizeCallCount += 1
        lastImage = image
        if shouldThrowError {
            throw DocumentNormalizerError.imageConversionFailed
        }
        return mockResult ?? image
    }
}
