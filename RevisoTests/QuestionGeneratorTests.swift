//
//  QuestionGeneratorTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

struct QuestionGeneratorTests {

    @Test func generateQuestions_returnsValidQuestions() async throws {
        let mockProvider = MockAIProvider()
        mockProvider.mockResponse = """
        [
            {
                "question": "What is 5 + 3?",
                "type": "multipleChoice",
                "options": ["6", "7", "8", "9"],
                "correctAnswer": "8",
                "explanation": "5 plus 3 equals 8"
            }
        ]
        """

        let generator = QuestionGenerator(provider: mockProvider)
        let questions = try await generator.generate(from: "What is 2 + 3?", count: 1)

        #expect(questions.count == 1)
        #expect(questions[0].question == "What is 5 + 3?")
        #expect(questions[0].type == .multipleChoice)
        #expect(questions[0].correctAnswer == "8")
    }

    @Test func generateQuestions_respectsCount() async throws {
        let mockProvider = MockAIProvider()
        mockProvider.mockResponse = """
        [
            {"question": "Q1", "type": "shortAnswer", "correctAnswer": "A1"},
            {"question": "Q2", "type": "shortAnswer", "correctAnswer": "A2"},
            {"question": "Q3", "type": "shortAnswer", "correctAnswer": "A3"}
        ]
        """

        let generator = QuestionGenerator(provider: mockProvider)
        let questions = try await generator.generate(from: "Test", count: 3)

        #expect(questions.count == 3)
        #expect(mockProvider.lastPrompt?.contains("3") == true)
    }

    @Test func generateQuestions_invalidJSON_throws() async {
        let mockProvider = MockAIProvider()
        mockProvider.mockResponse = "This is not JSON"

        let generator = QuestionGenerator(provider: mockProvider)

        await #expect(throws: QuestionGeneratorError.self) {
            try await generator.generate(from: "Test", count: 1)
        }
    }

    @Test func generateQuestions_providerError_throws() async {
        let mockProvider = MockAIProvider()
        mockProvider.shouldThrowError = true

        let generator = QuestionGenerator(provider: mockProvider)

        await #expect(throws: (any Error).self) {
            try await generator.generate(from: "Test", count: 1)
        }
    }

    @Test func generateQuestions_promptContainsWorksheetText() async throws {
        let mockProvider = MockAIProvider()
        mockProvider.mockResponse = """
        [{"question": "Q", "type": "shortAnswer", "correctAnswer": "A"}]
        """

        let generator = QuestionGenerator(provider: mockProvider)
        _ = try await generator.generate(from: "Solve x + 5 = 10", count: 1)

        #expect(mockProvider.lastPrompt?.contains("Solve x + 5 = 10") == true)
    }
}
