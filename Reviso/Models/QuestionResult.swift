//
//  QuestionResult.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation
import SwiftData

@Model
final class QuestionResult {
    var questionNumber: Int
    var isCorrect: Bool
    var session: PracticeSession?

    init(questionNumber: Int, isCorrect: Bool) {
        self.questionNumber = questionNumber
        self.isCorrect = isCorrect
    }
}
