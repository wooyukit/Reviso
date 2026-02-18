//
//  AIInpainterTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 18/2/2026.
//

import Testing
import UIKit
@testable import Reviso

@Suite(.serialized)
struct AIInpainterTests {

    // MARK: - Helpers

    private func createTestImage(color: UIColor = .white, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func createBase64PNG() -> String {
        let image = createTestImage(size: CGSize(width: 10, height: 10))
        return image.pngData()!.base64EncodedString()
    }

    // MARK: - PoeInpainter Tests

    @Test func poeInpainter_parsesBase64ImageResponse() async throws {
        let base64PNG = createBase64PNG()
        let responseJSON: [String: Any] = [
            "choices": [[
                "message": [
                    "content": "Here is the cleaned image:\n![result](data:image/png;base64,\(base64PNG))"
                ]
            ]]
        ]

        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = try JSONSerialization.data(withJSONObject: responseJSON)
        MockURLProtocol.mockStatusCode = 200

        let inpainter = PoeInpainter(apiKey: "test-poe-key", session: mockSession())
        let result = try await inpainter.cleanWorksheet(createTestImage())

        #expect(result.size.width > 0)
        #expect(result.size.height > 0)
    }

    @Test func poeInpainter_throwsOnHTTPError() async {
        MockURLProtocol.reset()
        MockURLProtocol.mockStatusCode = 401
        MockURLProtocol.mockResponseData = Data("unauthorized".utf8)

        let inpainter = PoeInpainter(apiKey: "bad-key", session: mockSession())

        await #expect(throws: AIProviderError.self) {
            try await inpainter.cleanWorksheet(createTestImage())
        }
    }
}
