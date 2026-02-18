//
//  PoeInpainter.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 18/2/2026.
//

import UIKit

/// AI-powered worksheet cleaner using Poe's OpenAI-compatible API.
/// Sends the raw worksheet image and lets the AI model detect and remove handwritten text.
final class PoeInpainter {
    private let apiKey: String
    private let session: URLSession
    private let model: String

    /// Max dimension for images sent to the API.
    private static let maxAPIDimension: CGFloat = 1024

    private static let prompt = """
        This is a scanned worksheet with handwritten student answers. \
        Remove ALL handwritten text (pen, pencil, any handwriting). \
        Keep all printed text, tables, borders, lines, and formatting exactly as they are. \
        Also clean up the image: even out the paper color, remove shadows and creases. \
        The result should look like a clean, high-quality printed worksheet ready to be filled in again.
        """

    init(apiKey: String, session: URLSession = .shared, model: String = "Grok-Imagine-Image") {
        self.apiKey = apiKey
        self.session = session
        self.model = model
    }

    /// Clean a worksheet image by removing handwritten answers via AI.
    func cleanWorksheet(_ image: UIImage) async throws -> UIImage {
        let resized = ImageUtils.resizeForProcessing(image, maxDimension: Self.maxAPIDimension)

        guard let base64 = ImageUtils.toBase64JPEG(resized, compressionQuality: 0.7) else {
            throw AnswerEraserError.inpaintingFailed
        }
        print("[PoeInpainter] Sending image \(Int(resized.size.width))x\(Int(resized.size.height)), base64: \(base64.count) chars, model: \(model)")

        return try await sendRequest(base64: base64)
    }

    /// Max retries for 429 rate limit errors.
    private static let maxRetries = 5

    // MARK: - API Request

    private func sendRequest(base64: String) async throws -> UIImage {
        let url = URL(string: "https://api.poe.com/v1/chat/completions")!

        let body: [String: Any] = [
            "model": model,
            "stream": false,
            "messages": [
                ["role": "user", "content": [
                    [
                        "type": "image_url",
                        "image_url": ["url": "data:image/jpg;base64,\(base64)"]
                    ],
                    [
                        "type": "text",
                        "text": Self.prompt
                    ]
                ]]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Retry with exponential backoff on 429 (as recommended by Poe docs)
        var lastStatusCode = 0
        for attempt in 0..<Self.maxRetries {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AnswerEraserError.inpaintingFailed
            }

            if (200..<300).contains(httpResponse.statusCode) {
                print("[PoeInpainter] Got 200, parsing image...")
                return try await parseImageFromResponse(data)
            }

            lastStatusCode = httpResponse.statusCode

            // Retry on 429 or 503 with backoff
            if httpResponse.statusCode == 429 || httpResponse.statusCode == 503 {
                let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { Double($0) }
                let backoff = retryAfter ?? (2.0 * pow(2.0, Double(attempt))) // 2s, 4s, 8s, 16s, 32s
                let jitter = Double.random(in: 0...0.25)
                let delay = backoff + jitter

                print("[PoeInpainter] HTTP \(httpResponse.statusCode), retry \(attempt + 1)/\(Self.maxRetries) after \(String(format: "%.1f", delay))s")
                try await Task.sleep(for: .milliseconds(Int(delay * 1000)))
                continue
            }

            // Non-retryable error
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            print("[PoeInpainter] HTTP \(httpResponse.statusCode): \(bodyStr.prefix(500))")
            throw AIProviderError.httpError(statusCode: httpResponse.statusCode)
        }

        print("[PoeInpainter] All \(Self.maxRetries) retries exhausted (HTTP \(lastStatusCode))")
        throw AIProviderError.httpError(statusCode: lastStatusCode)
    }

    // MARK: - Response Parsing

    private func parseImageFromResponse(_ data: Data) async throws -> UIImage {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let choices = json?["choices"] as? [[String: Any]]
        let message = choices?.first?["message"] as? [String: Any]
        let content = message?["content"]

        if let textContent = content as? String {
            return try await extractImageFromText(textContent)
        }

        if let contentArray = content as? [[String: Any]] {
            for item in contentArray {
                let type = item["type"] as? String

                if type == "image_url",
                   let imageUrl = item["image_url"] as? [String: Any],
                   let urlString = imageUrl["url"] as? String {
                    return try await downloadImage(from: urlString)
                }

                if type == "text", let text = item["text"] as? String {
                    if let image = try? await extractImageFromText(text) {
                        return image
                    }
                }
            }
        }

        print("[PoeInpainter] No image found in response")
        throw AnswerEraserError.inpaintingFailed
    }

    private func extractImageFromText(_ text: String) async throws -> UIImage {
        if let range = text.range(of: #"!\[.*?\]\((https?://[^\)]+)\)"#, options: .regularExpression),
           let urlRange = text.range(of: #"https?://[^\)]+"#, options: .regularExpression, range: range) {
            return try await downloadImage(from: String(text[urlRange]))
        }

        if let range = text.range(of: #"https?://\S+"#, options: .regularExpression) {
            return try await downloadImage(from: String(text[range]))
        }

        if let range = text.range(of: #"data:image/[^;]+;base64,"#, options: .regularExpression) {
            let base64Start = text[range.upperBound...]
            if let end = base64Start.firstIndex(where: { $0.isWhitespace || $0 == "\"" || $0 == ")" }) {
                if let imageData = Data(base64Encoded: String(base64Start[..<end])),
                   let image = UIImage(data: imageData) {
                    return image
                }
            }
        }

        throw AnswerEraserError.inpaintingFailed
    }

    private func downloadImage(from urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw AnswerEraserError.inpaintingFailed
        }
        let (data, _) = try await session.data(from: url)
        guard let image = UIImage(data: data) else {
            throw AnswerEraserError.inpaintingFailed
        }
        return image
    }
}
