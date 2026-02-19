//
//  GeneratedPracticeTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct GeneratedPracticeTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Worksheet.self, GeneratedPractice.self, configurations: config)
    }

    @Test func createGeneratedPractice_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let practice = GeneratedPractice(
            difficulty: .medium,
            subjectName: "Math",
            subTopicName: "Algebra",
            questionsText: "Q1: Solve x + 5 = 10\nQ2: Solve 2x = 8",
            answerKeyText: "A1: x = 5\nA2: x = 4",
            questionCount: 2
        )
        context.insert(practice)
        try context.save()

        #expect(practice.difficulty == .medium)
        #expect(practice.subjectName == "Math")
        #expect(practice.subTopicName == "Algebra")
        #expect(practice.questionsText.contains("Solve x + 5"))
        #expect(practice.answerKeyText.contains("x = 5"))
        #expect(practice.questionCount == 2)
        #expect(practice.sourceWorksheet == nil)
    }

    @Test func createGeneratedPractice_withSourceWorksheet() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let worksheet = Worksheet(name: "Math HW", subject: "Math", originalImage: Data("img".utf8))
        context.insert(worksheet)

        let practice = GeneratedPractice(
            difficulty: .easy,
            subjectName: "Math",
            questionsText: "Q1: 2 + 3 = ?",
            answerKeyText: "A1: 5",
            questionCount: 1
        )
        practice.sourceWorksheet = worksheet
        context.insert(practice)
        try context.save()

        #expect(practice.sourceWorksheet?.name == "Math HW")
    }
}
