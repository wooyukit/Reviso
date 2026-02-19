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
    let worksheet: Worksheet?
    let onRegenerate: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var revealedAnswers: Set<Int> = []
    @State private var savedPractice: GeneratedPractice?
    @State private var showSaveSuccess = false

    var body: some View {
        VStack(spacing: 0) {
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

            if savedPractice == nil {
                saveBar
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

                    if !viewModel.questions.isEmpty {
                        ShareLink(
                            item: shareText,
                            preview: SharePreview("Practice Questions")
                        ) {
                            Label("Share Questions", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Saved", isPresented: $showSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Practice saved. You can score your answers from the Worksheets tab.")
        }
    }

    private var saveBar: some View {
        VStack(spacing: 8) {
            Button {
                savePractice()
            } label: {
                Label("Save & Score Later", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var shareText: String {
        viewModel.questions.enumerated().map { i, q in
            "Q\(i + 1): \(q.question)"
        }.joined(separator: "\n\n")
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
            subjectName: worksheet?.subject ?? "General",
            subTopicName: worksheet?.subTopicName,
            questionsText: questionsText,
            answerKeyText: answerKeyText,
            questionCount: questions.count
        )
        practice.sourceWorksheet = worksheet
        modelContext.insert(practice)
        try? modelContext.save()

        savedPractice = practice
        showSaveSuccess = true
    }
}
