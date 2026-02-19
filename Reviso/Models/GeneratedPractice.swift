//
//  GeneratedPractice.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation
import SwiftData

@Model
final class GeneratedPractice {
    var date: Date
    var difficulty: Difficulty
    var subjectName: String
    var subTopicName: String?
    var questionsText: String
    var answerKeyText: String
    var questionCount: Int
    var sourceWorksheet: Worksheet?

    init(
        difficulty: Difficulty,
        subjectName: String,
        subTopicName: String? = nil,
        questionsText: String,
        answerKeyText: String,
        questionCount: Int
    ) {
        self.date = Date()
        self.difficulty = difficulty
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.questionsText = questionsText
        self.answerKeyText = answerKeyText
        self.questionCount = questionCount
        self.sourceWorksheet = nil
    }
}
