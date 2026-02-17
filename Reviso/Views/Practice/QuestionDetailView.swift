//
//  QuestionDetailView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct QuestionDetailView: View {
    let question: GeneratedQuestion
    let isRevealed: Bool
    let onToggleReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.question)
                .font(.body)

            questionTypeLabel

            if let options = question.options, question.type == .multipleChoice {
                ForEach(options, id: \.self) { option in
                    HStack {
                        Image(systemName: isRevealed && option == question.correctAnswer
                              ? "checkmark.circle.fill"
                              : "circle")
                        .foregroundStyle(isRevealed && option == question.correctAnswer ? .green : .primary)

                        Text(option)
                            .foregroundStyle(isRevealed && option == question.correctAnswer ? .green : .primary)
                    }
                }
            }

            Button {
                withAnimation { onToggleReveal() }
            } label: {
                Label(
                    isRevealed ? "Hide Answer" : "Show Answer",
                    systemImage: isRevealed ? "eye.slash" : "eye"
                )
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            if isRevealed {
                VStack(alignment: .leading, spacing: 8) {
                    if let answer = question.correctAnswer {
                        HStack(alignment: .top) {
                            Text("Answer:")
                                .fontWeight(.semibold)
                            Text(answer)
                        }
                        .foregroundStyle(.green)
                    }

                    if let explanation = question.explanation {
                        Text(explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var questionTypeLabel: some View {
        Text(typeDisplayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.tint.opacity(0.1))
            .foregroundStyle(.tint)
            .cornerRadius(6)
    }

    private var typeDisplayName: String {
        switch question.type {
        case .multipleChoice: "Multiple Choice"
        case .shortAnswer: "Short Answer"
        case .fillInBlank: "Fill in the Blank"
        }
    }
}
