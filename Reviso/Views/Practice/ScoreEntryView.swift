//
//  ScoreEntryView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI
import SwiftData

struct ScoreEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PracticeViewModel
    let answerKeyText: String?
    let worksheet: Worksheet?
    let generatedPractice: GeneratedPractice?
    @State private var showAnswerKey = false
    @State private var showSummary = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showAnswerKey, let answerKeyText {
                    answerKeyBanner(answerKeyText)
                }

                List {
                    ForEach(1...viewModel.totalQuestions, id: \.self) { number in
                        questionRow(number: number)
                    }
                }

                submitBar
            }
            .navigationTitle("Score My Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if answerKeyText != nil {
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
            .sheet(isPresented: $showSummary) {
                ScoreSummaryView(
                    correctCount: viewModel.correctCount,
                    totalQuestions: viewModel.totalQuestions,
                    scorePercentage: viewModel.scorePercentage,
                    subjectName: viewModel.subjectName
                ) {
                    dismiss()
                }
            }
        }
    }

    private func answerKeyBanner(_ text: String) -> some View {
        ScrollView {
            Text(text)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 150)
        .background(.green.opacity(0.1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func questionRow(number: Int) -> some View {
        HStack {
            Text("Q\(number)")
                .font(.headline)
                .frame(width: 40)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.markQuestion(number, isCorrect: true)
                } label: {
                    Image(systemName: viewModel.results[number - 1] == true
                          ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.results[number - 1] == true ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.markQuestion(number, isCorrect: false)
                } label: {
                    Image(systemName: viewModel.results[number - 1] == false
                          ? "xmark.circle.fill" : "xmark.circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.results[number - 1] == false ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var submitBar: some View {
        VStack(spacing: 8) {
            let answered = viewModel.results.compactMap { $0 }.count
            Text("\(answered) of \(viewModel.totalQuestions) answered")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                viewModel.saveSession(
                    context: modelContext,
                    worksheet: worksheet,
                    generatedPractice: generatedPractice
                )
                showSummary = true
            } label: {
                Text("Submit Score")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isComplete)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
