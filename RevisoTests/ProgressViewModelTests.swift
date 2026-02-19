//
//  ProgressViewModelTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct ProgressViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    private func createSession(
        context: ModelContext,
        subject: String,
        correct: Int,
        total: Int,
        difficulty: Difficulty = .medium
    ) {
        let session = PracticeSession(
            difficulty: difficulty,
            subjectName: subject,
            totalQuestions: total
        )
        context.insert(session)
        for i in 1...total {
            let result = QuestionResult(questionNumber: i, isCorrect: i <= correct)
            result.session = session
            context.insert(result)
        }
        try? context.save()
    }

    @Test func loadStats_withNoSessions_returnsZeros() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ProgressViewModel()

        vm.loadStats(context: context)

        #expect(vm.totalSessions == 0)
        #expect(vm.subjectStats.isEmpty)
    }

    @Test func loadStats_countsTotalSessions() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        createSession(context: context, subject: "Math", correct: 3, total: 5)
        createSession(context: context, subject: "Science", correct: 4, total: 5)

        let vm = ProgressViewModel()
        vm.loadStats(context: context)

        #expect(vm.totalSessions == 2)
    }

    @Test func loadStats_groupsBySubject() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        createSession(context: context, subject: "Math", correct: 4, total: 5)
        createSession(context: context, subject: "Math", correct: 3, total: 5)
        createSession(context: context, subject: "Science", correct: 5, total: 5)

        let vm = ProgressViewModel()
        vm.loadStats(context: context)

        #expect(vm.subjectStats.count == 2)
        let mathStat = vm.subjectStats.first { $0.subjectName == "Math" }
        #expect(mathStat?.sessionCount == 2)
        #expect(mathStat?.averageScore == 70) // (80 + 60) / 2
    }
}
