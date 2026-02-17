//
//  GeminiProvider.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

final class GeminiProvider: AIProviderProtocol {
    let providerType: AIProviderType = .gemini
    private let apiKey: String
    private let session: URLSession
    private let model: String

    init(apiKey: String, session: URLSession = .shared, model: String = "gemini-pro") {
        self.apiKey = apiKey
        self.session = session
        self.model = model
    }

    func send(prompt: String, image: UIImage?) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        let url = URL(string: urlString)!

        var parts: [[String: Any]] = [["text": prompt]]

        if let image, let base64 = ImageUtils.toBase64JPEG(image) {
            parts.append([
                "inlineData": [
                    "mimeType": "image/jpeg",
                    "data": base64
                ]
            ])
        }

        let body: [String: Any] = [
            "contents": [["parts": parts]]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AIProviderError.httpError(statusCode: httpResponse.statusCode)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let candidates = json?["candidates"] as? [[String: Any]]
        let content = candidates?.first?["content"] as? [String: Any]
        let contentParts = content?["parts"] as? [[String: Any]]
        let text = contentParts?.first?["text"] as? String

        guard let text else { throw AIProviderError.invalidResponse }
        return text
    }
}
