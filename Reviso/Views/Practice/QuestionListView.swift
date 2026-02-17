//
//  QuestionListView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct QuestionListView: View {
    let viewModel: QuestionGeneratorViewModel
    let onRegenerate: () -> Void

    @State private var revealedAnswers: Set<Int> = []

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
                Button {
                    revealedAnswers.removeAll()
                    onRegenerate()
                } label: {
                    Label("Regenerate", systemImage: "arrow.clockwise")
                }
            }
        }
    }
}
