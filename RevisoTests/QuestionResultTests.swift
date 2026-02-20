//
//  QuestionResultTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct QuestionResultTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    @Test func createResult_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let result = QuestionResult(questionNumber: 3, isCorrect: true)
        context.insert(result)
        try context.save()

        #expect(result.questionNumber == 3)
        #expect(result.isCorrect == true)
        #expect(result.session == nil)
    }

    @Test func createResult_incorrectAnswer() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let result = QuestionResult(questionNumber: 1, isCorrect: false)
        context.insert(result)
        try context.save()

        #expect(result.questionNumber == 1)
        #expect(result.isCorrect == false)
    }

    @Test func result_sessionRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .easy,
            subjectName: "Math",
            totalQuestions: 2
        )
        context.insert(session)

        let r1 = QuestionResult(questionNumber: 1, isCorrect: true)
        let r2 = QuestionResult(questionNumber: 2, isCorrect: false)
        r1.session = session
        r2.session = session
        context.insert(r1)
        context.insert(r2)
        try context.save()

        #expect(r1.session?.persistentModelID == session.persistentModelID)
        #expect(r2.session?.persistentModelID == session.persistentModelID)
        #expect(session.questionResults.count == 2)
    }

    @Test func multipleResults_correctCountComputation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .medium,
            subjectName: "Science",
            totalQuestions: 4
        )
        context.insert(session)

        let results = [
            QuestionResult(questionNumber: 1, isCorrect: true),
            QuestionResult(questionNumber: 2, isCorrect: true),
            QuestionResult(questionNumber: 3, isCorrect: false),
            QuestionResult(questionNumber: 4, isCorrect: true),
        ]
        for r in results {
            r.session = session
            context.insert(r)
        }
        try context.save()

        #expect(session.correctCount == 3)
        #expect(session.scorePercentage == 75)
    }
}
