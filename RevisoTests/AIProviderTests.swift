//
//  AIProviderTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct AIProviderTests {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - Claude Provider

    @Test func claudeProvider_sendsCorrectRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = claudeResponseJSON()

        let provider = ClaudeProvider(apiKey: "test-key", session: makeSession())
        _ = try await provider.send(prompt: "Hello", image: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.url?.absoluteString == "https://api.anthropic.com/v1/messages")
        #expect(request?.value(forHTTPHeaderField: "x-api-key") == "test-key")
        #expect(request?.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(request?.httpMethod == "POST")
    }

    @Test func claudeProvider_parsesResponse() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = claudeResponseJSON()

        let provider = ClaudeProvider(apiKey: "test-key", session: makeSession())
        let result = try await provider.send(prompt: "Hello", image: nil)

        #expect(result == "Test response from Claude")
    }

    @Test func claudeProvider_httpError_throws() async {
        MockURLProtocol.reset()
        MockURLProtocol.mockStatusCode = 401
        MockURLProtocol.mockResponseData = Data("{}".utf8)

        let provider = ClaudeProvider(apiKey: "bad-key", session: makeSession())

        await #expect(throws: AIProviderError.self) {
            try await provider.send(prompt: "Hello", image: nil)
        }
    }

    // MARK: - OpenAI Provider

    @Test func openAIProvider_sendsCorrectRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = openAIResponseJSON()

        let provider = OpenAIProvider(apiKey: "test-key", session: makeSession())
        _ = try await provider.send(prompt: "Hello", image: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.url?.absoluteString == "https://api.openai.com/v1/chat/completions")
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test func openAIProvider_parsesResponse() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = openAIResponseJSON()

        let provider = OpenAIProvider(apiKey: "test-key", session: makeSession())
        let result = try await provider.send(prompt: "Hello", image: nil)

        #expect(result == "Test response from OpenAI")
    }

    // MARK: - Gemini Provider

    @Test func geminiProvider_sendsCorrectRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = geminiResponseJSON()

        let provider = GeminiProvider(apiKey: "test-key", session: makeSession())
        _ = try await provider.send(prompt: "Hello", image: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.url?.absoluteString.contains("generativelanguage.googleapis.com") == true)
        #expect(request?.url?.absoluteString.contains("key=test-key") == true)
    }

    @Test func geminiProvider_parsesResponse() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = geminiResponseJSON()

        let provider = GeminiProvider(apiKey: "test-key", session: makeSession())
        let result = try await provider.send(prompt: "Hello", image: nil)

        #expect(result == "Test response from Gemini")
    }

    // MARK: - Poe Provider

    @Test func poeProvider_sendsCorrectRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession())
        _ = try await provider.send(prompt: "Hello", image: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.url?.absoluteString == "https://api.poe.com/v1/chat/completions")
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request?.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(request?.httpMethod == "POST")
    }

    @Test func poeProvider_parsesResponse() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession())
        let result = try await provider.send(prompt: "Hello", image: nil)

        #expect(result == "Test response from Poe")
    }

    @Test func poeProvider_httpError_throws() async {
        MockURLProtocol.reset()
        MockURLProtocol.mockStatusCode = 401
        MockURLProtocol.mockResponseData = Data("{}".utf8)

        let provider = PoeProvider(apiKey: "bad-key", session: makeSession())

        await #expect(throws: AIProviderError.self) {
            try await provider.send(prompt: "Hello", image: nil)
        }
    }

    @Test func poeProvider_usesCorrectModel() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession(), model: "Claude-3.5-Sonnet")
        _ = try await provider.send(prompt: "Hello", image: nil)

        let bodyData = MockURLProtocol.lastRequestBody ?? Data()
        let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        #expect(body?["model"] as? String == "Claude-3.5-Sonnet")
    }

    // MARK: - JSON Helpers

    private func claudeResponseJSON() -> Data {
        """
        {
            "id": "msg_test",
            "type": "message",
            "role": "assistant",
            "content": [{"type": "text", "text": "Test response from Claude"}],
            "model": "claude-3-5-sonnet-20241022",
            "stop_reason": "end_turn",
            "usage": {"input_tokens": 10, "output_tokens": 5}
        }
        """.data(using: .utf8)!
    }

    private func openAIResponseJSON() -> Data {
        """
        {
            "id": "chatcmpl-test",
            "object": "chat.completion",
            "created": 1234567890,
            "model": "gpt-4o",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "Test response from OpenAI"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}
        }
        """.data(using: .utf8)!
    }

    private func geminiResponseJSON() -> Data {
        """
        {
            "candidates": [{
                "content": {
                    "parts": [{"text": "Test response from Gemini"}],
                    "role": "model"
                },
                "finishReason": "STOP"
            }]
        }
        """.data(using: .utf8)!
    }

    private func poeResponseJSON() -> Data {
        """
        {
            "id": "chatcmpl-poe-test",
            "object": "chat.completion",
            "created": 1234567890,
            "model": "GPT-4o",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "Test response from Poe"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}
        }
        """.data(using: .utf8)!
    }
}
