//
//  QuestionGeneratorViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

@Observable
final class QuestionGeneratorViewModel {
    var questions: [GeneratedQuestion] = []
    var isGenerating = false
    var error: String?
    var questionCount = 3

    private let generator: QuestionGenerator

    init(generator: QuestionGenerator) {
        self.generator = generator
    }

    @MainActor
    func generateQuestions(from text: String, image: UIImage? = nil) async {
        isGenerating = true
        error = nil
        questions = []

        do {
            questions = try await generator.generate(from: text, image: image, count: questionCount)
        } catch {
            self.error = "Failed to generate questions: \(error.localizedDescription)"
        }

        isGenerating = false
    }
}
