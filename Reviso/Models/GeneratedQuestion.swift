//
//  GeneratedQuestion.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation

enum QuestionType: String, Codable, CaseIterable {
    case multipleChoice
    case shortAnswer
    case fillInBlank
}

struct GeneratedQuestion: Codable, Equatable {
    let question: String
    let type: QuestionType
    let options: [String]?
    let correctAnswer: String?
    let explanation: String?
}
