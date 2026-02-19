//
//  PracticeSessionTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct PracticeSessionTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    @Test func createSession_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .hard,
            subjectName: "Science",
            subTopicName: "Physics",
            totalQuestions: 5
        )
        context.insert(session)
        try context.save()

        #expect(session.difficulty == .hard)
        #expect(session.subjectName == "Science")
        #expect(session.subTopicName == "Physics")
        #expect(session.totalQuestions == 5)
        #expect(session.questionResults.isEmpty)
    }

    @Test func session_correctCount_computedFromResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .medium,
            subjectName: "Math",
            totalQuestions: 3
        )
        context.insert(session)

        let r1 = QuestionResult(questionNumber: 1, isCorrect: true)
        let r2 = QuestionResult(questionNumber: 2, isCorrect: false)
        let r3 = QuestionResult(questionNumber: 3, isCorrect: true)
        r1.session = session
        r2.session = session
        r3.session = session
        context.insert(r1)
        context.insert(r2)
        context.insert(r3)
        try context.save()

        #expect(session.correctCount == 2)
        #expect(session.scorePercentage == 67) // 2/3 * 100 rounded
    }

    @Test func session_withWorksheetRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let worksheet = Worksheet(name: "Test", subject: "Math", originalImage: Data())
        context.insert(worksheet)

        let session = PracticeSession(
            difficulty: .easy,
            subjectName: "Math",
            totalQuestions: 1
        )
        session.worksheet = worksheet
        context.insert(session)
        try context.save()

        #expect(session.worksheet?.name == "Test")
    }

    @Test func session_withGeneratedPracticeRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let practice = GeneratedPractice(
            difficulty: .medium,
            subjectName: "Math",
            questionsText: "Q1",
            answerKeyText: "A1",
            questionCount: 1
        )
        context.insert(practice)

        let session = PracticeSession(
            difficulty: .medium,
            subjectName: "Math",
            totalQuestions: 1
        )
        session.generatedPractice = practice
        context.insert(session)
        try context.save()

        #expect(session.generatedPractice != nil)
    }
}
