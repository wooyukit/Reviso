//
//  QuestionGeneratorViewModelTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct QuestionGeneratorViewModelTests {

    private func makeViewModel(response: String = "[]") -> QuestionGeneratorViewModel {
        let mockProvider = MockAIProvider()
        mockProvider.mockResponse = response
        let generator = QuestionGenerator(provider: mockProvider)
        return QuestionGeneratorViewModel(generator: generator)
    }

    @Test func generateQuestions_populatesQuestionsList() async {
        let response = """
        [{"question": "What is 5+5?", "type": "shortAnswer", "correctAnswer": "10"}]
        """
        let vm = makeViewModel(response: response)

        await vm.generateQuestions(from: "What is 2+2?")

        #expect(vm.questions.count == 1)
        #expect(vm.questions[0].question == "What is 5+5?")
    }

    @Test func generateQuestions_setsLoadingState() async {
        let vm = makeViewModel(response: "[]")

        #expect(!vm.isGenerating)
        await vm.generateQuestions(from: "Test")
        #expect(!vm.isGenerating)
    }

    @Test func generateQuestions_error_setsErrorMessage() async {
        let mockProvider = MockAIProvider()
        mockProvider.shouldThrowError = true
        let generator = QuestionGenerator(provider: mockProvider)
        let vm = QuestionGeneratorViewModel(generator: generator)

        await vm.generateQuestions(from: "Test")

        #expect(vm.error != nil)
        #expect(vm.questions.isEmpty)
    }

    @Test func generateQuestions_clearsOldResults() async {
        let response = """
        [{"question": "Q1", "type": "shortAnswer", "correctAnswer": "A1"}]
        """
        let vm = makeViewModel(response: response)

        await vm.generateQuestions(from: "First")
        #expect(vm.questions.count == 1)

        await vm.generateQuestions(from: "Second")
        #expect(vm.questions.count == 1)
    }
}
