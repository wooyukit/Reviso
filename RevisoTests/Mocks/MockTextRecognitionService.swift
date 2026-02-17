//
//  MockTextRecognitionService.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
@testable import Reviso

final class MockTextRecognitionService: TextRecognitionServiceProtocol {
    var mockText: String = ""
    var shouldThrowError = false
    var recognizeCallCount = 0

    func recognizeText(in image: UIImage) async throws -> String {
        recognizeCallCount += 1
        if shouldThrowError {
            throw TextRecognitionError.recognitionFailed
        }
        return mockText
    }
}
