//
//  ClaudeProvider.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

final class ClaudeProvider: AIProviderProtocol {
    let providerType: AIProviderType = .claude
    private let apiKey: String
    private let session: URLSession
    private let model: String

    init(apiKey: String, session: URLSession = .shared, model: String = "claude-sonnet-4-5-20250929") {
        self.apiKey = apiKey
        self.session = session
        self.model = model
    }

    func send(prompt: String, image: UIImage?) async throws -> String {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!

        var content: [[String: Any]] = []

        if let image, let base64 = ImageUtils.toBase64JPEG(image) {
            content.append([
                "type": "image",
                "source": [
                    "type": "base64",
                    "media_type": "image/jpeg",
                    "data": base64
                ]
            ])
        }

        content.append(["type": "text", "text": prompt])

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "messages": [["role": "user", "content": content]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIProviderError.httpError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let contentArray = json?["content"] as? [[String: Any]]
        let text = contentArray?.first?["text"] as? String

        guard let text else { throw AIProviderError.invalidResponse }
        return text
    }
}
