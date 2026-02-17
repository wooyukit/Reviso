//
//  QuestionGenerator.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum QuestionGeneratorError: Error {
    case invalidResponse
    case parsingFailed
}

final class QuestionGenerator {
    private let provider: AIProviderProtocol

    init(provider: AIProviderProtocol) {
        self.provider = provider
    }

    func generate(from worksheetText: String, image: UIImage? = nil, count: Int = 3) async throws -> [GeneratedQuestion] {
        let prompt = buildPrompt(worksheetText: worksheetText, count: count)
        let response = try await provider.send(prompt: prompt, image: image)
        return try parseQuestions(from: response)
    }

    private func buildPrompt(worksheetText: String, count: Int) -> String {
        """
        Analyze the following worksheet content and generate \(count) similar practice questions.

        WORKSHEET CONTENT:
        \(worksheetText)

        Return ONLY a valid JSON array with no additional text. Use this exact schema:
        [
            {
                "question": "question text",
                "type": "multipleChoice" or "shortAnswer" or "fillInBlank",
                "options": ["A", "B", "C", "D"],
                "correctAnswer": "the correct answer",
                "explanation": "brief explanation"
            }
        ]

        Notes:
        - "options" is only required for "multipleChoice" type
        - Generate questions at a similar difficulty level
        - Vary the question types when appropriate
        """
    }

    private func parseQuestions(from response: String) throws -> [GeneratedQuestion] {
        // Extract JSON array from response (handle potential markdown wrapping)
        let jsonString = extractJSON(from: response)

        guard let data = jsonString.data(using: .utf8) else {
            throw QuestionGeneratorError.invalidResponse
        }

        do {
            return try JSONDecoder().decode([GeneratedQuestion].self, from: data)
        } catch {
            throw QuestionGeneratorError.parsingFailed
        }
    }

    private func extractJSON(from response: String) -> String {
        // Handle responses wrapped in markdown code blocks
        var cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
