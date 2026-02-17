//
//  OpenAIProvider.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

final class OpenAIProvider: AIProviderProtocol {
    let providerType: AIProviderType = .openAI
    private let apiKey: String
    private let session: URLSession
    private let model: String

    init(apiKey: String, session: URLSession = .shared, model: String = "gpt-4o") {
        self.apiKey = apiKey
        self.session = session
        self.model = model
    }

    func send(prompt: String, image: UIImage?) async throws -> String {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!

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
