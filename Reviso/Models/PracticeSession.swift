//
//  PracticeSession.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation
import SwiftData

@Model
final class PracticeSession {
    var date: Date
    var difficulty: Difficulty
    var subjectName: String
    var subTopicName: String?
    var totalQuestions: Int
    var worksheet: Worksheet?
    var generatedPractice: GeneratedPractice?
    @Relationship(deleteRule: .cascade, inverse: \QuestionResult.session)
    var questionResults: [QuestionResult] = []

    var correctCount: Int {
        questionResults.filter(\.isCorrect).count
    }

    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestions) * 100).rounded())
    }

    init(
        difficulty: Difficulty,
        subjectName: String,
        subTopicName: String? = nil,
        totalQuestions: Int
    ) {
        self.date = Date()
        self.difficulty = difficulty
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.totalQuestions = totalQuestions
    }
}
