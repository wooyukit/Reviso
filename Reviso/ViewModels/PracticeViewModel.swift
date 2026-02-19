//
//  PracticeViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI
import SwiftData

@Observable
final class PracticeViewModel {
    let totalQuestions: Int
    let subjectName: String
    let subTopicName: String?
    let difficulty: Difficulty
    var results: [Bool?]
    var showAnswerKey = false

    var isComplete: Bool {
        results.allSatisfy { $0 != nil }
    }

    var correctCount: Int {
        results.compactMap { $0 }.filter { $0 }.count
    }

    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestions) * 100).rounded())
    }

    init(questionCount: Int, subjectName: String, subTopicName: String? = nil, difficulty: Difficulty) {
        self.totalQuestions = questionCount
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.difficulty = difficulty
        self.results = Array(repeating: nil, count: questionCount)
    }

    func markQuestion(_ number: Int, isCorrect: Bool) {
        guard number >= 1, number <= totalQuestions else { return }
        results[number - 1] = isCorrect
    }

    func saveSession(context: ModelContext, worksheet: Worksheet? = nil, generatedPractice: GeneratedPractice? = nil) {
        let session = PracticeSession(
            difficulty: difficulty,
            subjectName: subjectName,
            subTopicName: subTopicName,
            totalQuestions: totalQuestions
        )
        session.worksheet = worksheet
        session.generatedPractice = generatedPractice
        context.insert(session)

        for (index, result) in results.enumerated() {
            guard let isCorrect = result else { continue }
            let questionResult = QuestionResult(questionNumber: index + 1, isCorrect: isCorrect)
            questionResult.session = session
            context.insert(questionResult)
        }

        try? context.save()
    }
}
