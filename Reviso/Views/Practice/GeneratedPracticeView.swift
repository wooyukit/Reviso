//
//  GeneratedPracticeView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI
import SwiftData

struct GeneratedPracticeView: View {
    let practice: GeneratedPractice
    @Environment(\.dismiss) private var dismiss
    @State private var showAnswerKey = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    questionsSection
                    if showAnswerKey {
                        answerKeySection
                    }
                }
                .padding()
            }
            .navigationTitle("Practice Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation { showAnswerKey.toggle() }
                    } label: {
                        Label(
                            showAnswerKey ? "Hide Answers" : "Show Answers",
                            systemImage: showAnswerKey ? "eye.slash" : "eye"
                        )
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Label(practice.subjectName, systemImage: "book")
            Spacer()
            Text(practice.difficulty.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.tint.opacity(0.1))
                .foregroundStyle(.tint)
                .cornerRadius(6)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Questions")
                .font(.headline)
            Text(practice.questionsText)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var answerKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Answer Key")
                .font(.headline)
                .foregroundStyle(.green)
            Text(practice.answerKeyText)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
