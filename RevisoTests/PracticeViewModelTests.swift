//
//  PracticeViewModelTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct PracticeViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    @Test func init_setsUpCorrectQuestionCount() {
        let vm = PracticeViewModel(questionCount: 5, subjectName: "Math", difficulty: .medium)
        #expect(vm.totalQuestions == 5)
        #expect(vm.results.count == 5)
        #expect(vm.results.allSatisfy { $0 == nil })
    }

    @Test func markQuestion_updatesResult() {
        let vm = PracticeViewModel(questionCount: 3, subjectName: "Math", difficulty: .easy)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)

        #expect(vm.results[0] == true)
        #expect(vm.results[1] == false)
        #expect(vm.results[2] == nil)
    }

    @Test func toggleQuestion_flipsResult() {
        let vm = PracticeViewModel(questionCount: 2, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        #expect(vm.results[0] == true)

        vm.markQuestion(1, isCorrect: false)
        #expect(vm.results[0] == false)
    }

    @Test func isComplete_trueWhenAllMarked() {
        let vm = PracticeViewModel(questionCount: 2, subjectName: "Math", difficulty: .hard)
        #expect(vm.isComplete == false)

        vm.markQuestion(1, isCorrect: true)
        #expect(vm.isComplete == false)

        vm.markQuestion(2, isCorrect: false)
        #expect(vm.isComplete == true)
    }

    @Test func correctCount_countsOnlyCorrect() {
        let vm = PracticeViewModel(questionCount: 3, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)
        vm.markQuestion(3, isCorrect: true)

        #expect(vm.correctCount == 2)
    }

    @Test func scorePercentage_calculatesCorrectly() {
        let vm = PracticeViewModel(questionCount: 4, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: true)
        vm.markQuestion(3, isCorrect: true)
        vm.markQuestion(4, isCorrect: false)

        #expect(vm.scorePercentage == 75)
    }

    @Test func saveSession_createsSessionWithResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let vm = PracticeViewModel(questionCount: 2, subjectName: "Science", subTopicName: "Physics", difficulty: .hard)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)

        vm.saveSession(context: context)

        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions[0].subjectName == "Science")
        #expect(sessions[0].subTopicName == "Physics")
        #expect(sessions[0].difficulty == .hard)
        #expect(sessions[0].totalQuestions == 2)
        #expect(sessions[0].questionResults.count == 2)
        #expect(sessions[0].correctCount == 1)
    }
}
