//
//  GeneratedQuestionTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

struct GeneratedQuestionTests {

    @Test func decodeMultipleChoiceQuestion() throws {
        let json = """
        {
            "question": "What is 2 + 2?",
            "type": "multipleChoice",
            "options": ["3", "4", "5", "6"],
            "correctAnswer": "4",
            "explanation": "Basic addition"
        }
        """.data(using: .utf8)!

        let question = try JSONDecoder().decode(GeneratedQuestion.self, from: json)

        #expect(question.question == "What is 2 + 2?")
        #expect(question.type == .multipleChoice)
        #expect(question.options == ["3", "4", "5", "6"])
        #expect(question.correctAnswer == "4")
        #expect(question.explanation == "Basic addition")
    }

    @Test func decodeShortAnswerQuestion() throws {
        let json = """
        {
            "question": "Name the capital of France.",
            "type": "shortAnswer",
            "correctAnswer": "Paris",
            "explanation": "Paris is the capital city of France."
        }
        """.data(using: .utf8)!

        let question = try JSONDecoder().decode(GeneratedQuestion.self, from: json)

        #expect(question.question == "Name the capital of France.")
        #expect(question.type == .shortAnswer)
        #expect(question.options == nil)
        #expect(question.correctAnswer == "Paris")
    }

    @Test func decodeFillInBlankQuestion() throws {
        let json = """
        {
            "question": "The chemical formula for water is ___.",
            "type": "fillInBlank",
            "correctAnswer": "H2O"
        }
        """.data(using: .utf8)!

        let question = try JSONDecoder().decode(GeneratedQuestion.self, from: json)

        #expect(question.type == .fillInBlank)
        #expect(question.explanation == nil)
    }

    @Test func decodeArrayOfQuestions() throws {
        let json = """
        [
            {
                "question": "What is 3 x 4?",
                "type": "multipleChoice",
                "options": ["7", "10", "12", "15"],
                "correctAnswer": "12"
            },
            {
                "question": "Spell the word for the number 5.",
                "type": "shortAnswer",
                "correctAnswer": "five"
            }
        ]
        """.data(using: .utf8)!

        let questions = try JSONDecoder().decode([GeneratedQuestion].self, from: json)

        #expect(questions.count == 2)
        #expect(questions[0].type == .multipleChoice)
        #expect(questions[1].type == .shortAnswer)
    }

    @Test func encodeQuestion_roundTrips() throws {
        let original = GeneratedQuestion(
            question: "What is gravity?",
            type: .shortAnswer,
            options: nil,
            correctAnswer: "A force that attracts objects toward each other",
            explanation: "Gravity is a fundamental force."
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GeneratedQuestion.self, from: data)

        #expect(decoded.question == original.question)
        #expect(decoded.type == original.type)
        #expect(decoded.correctAnswer == original.correctAnswer)
        #expect(decoded.explanation == original.explanation)
    }

    @Test func questionType_allCases() {
        #expect(QuestionType.allCases.count == 3)
        #expect(QuestionType.allCases.contains(.multipleChoice))
        #expect(QuestionType.allCases.contains(.shortAnswer))
        #expect(QuestionType.allCases.contains(.fillInBlank))
    }

    @Test func aiProviderType_properties() {
        #expect(AIProviderType.claude.displayName == "Claude")
        #expect(AIProviderType.openAI.displayName == "OpenAI")
        #expect(AIProviderType.gemini.displayName == "Gemini")

        #expect(AIProviderType.allCases.count == 3)
    }
}
