//
//  MockAIProvider.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit
@testable import Reviso

final class MockAIProvider: AIProviderProtocol {
    var providerType: AIProviderType = .claude
    var mockResponse: String = ""
    var shouldThrowError = false
    var sendCallCount = 0
    var lastPrompt: String?
    var lastImage: UIImage?

    func send(prompt: String, image: UIImage?) async throws -> String {
        sendCallCount += 1
        lastPrompt = prompt
        lastImage = image
        if shouldThrowError {
            throw AIProviderError.requestFailed("Mock error")
        }
        return mockResponse
    }
}
