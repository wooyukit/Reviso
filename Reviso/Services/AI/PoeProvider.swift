//
//  PoeProvider.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

/// Poe API client using the OpenAI-compatible endpoint.
/// API key from https://poe.com/api_key
final class PoeProvider: AIProviderProtocol {
    let providerType: AIProviderType = .poe
    private let apiKey: String
    private let session: URLSession
    private let model: String

    init(apiKey: String, session: URLSession = .shared, model: String = "Claude-3.5-Sonnet") {
        self.apiKey = apiKey
        self.session = session
        self.model = model
    }

    func send(prompt: String, image: UIImage?) async throws -> String {
        let url = URL(string: "https://api.poe.com/v1/chat/completions")!

        var content: [[String: Any]] = [["type": "text", "text": prompt]]

        if let image, let base64 = ImageUtils.toBase64JPEG(image) {
            content.append([
                "type": "image_url",
                "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
            ])
        }

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 2048,
            "stream": false,
            "messages": [["role": "user", "content": content]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIProviderError.httpError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let text = message?["content"] as? String

        guard let text else { throw AIProviderError.invalidResponse }
        return text
    }
}
