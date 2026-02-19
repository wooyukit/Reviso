//
//  QuestionListView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

struct QuestionListView: View {
    let viewModel: QuestionGeneratorViewModel
    let onRegenerate: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var revealedAnswers: Set<Int> = []
    @State private var savedPractice: GeneratedPractice?
    @State private var showSaveSuccess = false

    var body: some View {
        List {
            if let error = viewModel.error {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                Section("Question \(index + 1)") {
                    QuestionDetailView(
                        question: question,
                        isRevealed: revealedAnswers.contains(index),
                        onToggleReveal: {
                            if revealedAnswers.contains(index) {
                                revealedAnswers.remove(index)
                            } else {
                                revealedAnswers.insert(index)
                            }
                        }
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        revealedAnswers.removeAll()
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    if savedPractice == nil {
                        Button {
                            savePractice()
                        } label: {
                            Label("Save Practice", systemImage: "square.and.arrow.down")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Saved", isPresented: $showSaveSuccess) {
            Button("OK") {}
        } message: {
            Text("Practice questions saved. You can find them in the Practice tab.")
        }
    }

    private func savePractice() {
        let questions = viewModel.questions
        let questionsText = questions.enumerated().map { i, q in
            "Q\(i + 1): \(q.question)"
        }.joined(separator: "\n\n")

        let answerKeyText = questions.enumerated().map { i, q in
            "A\(i + 1): \(q.correctAnswer ?? "N/A")\(q.explanation.map { " — \($0)" } ?? "")"
        }.joined(separator: "\n\n")

        let practice = GeneratedPractice(
            difficulty: viewModel.selectedDifficulty,
            subjectName: "General",
            questionsText: questionsText,
            answerKeyText: answerKeyText,
            questionCount: questions.count
        )
        modelContext.insert(practice)
        try? modelContext.save()

        savedPractice = practice
        showSaveSuccess = true
    }
}
