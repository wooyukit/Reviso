//
//  PracticeTabView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI
import SwiftData

struct PracticeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GeneratedPractice.date, order: .reverse) private var practices: [GeneratedPractice]
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var progressVM = ProgressViewModel()
    @State private var selectedPractice: GeneratedPractice?
    @State private var scoreEntryPractice: GeneratedPractice?

    var body: some View {
        NavigationStack {
            List {
                if !sessions.isEmpty {
                    progressSection
                }

                if !practices.isEmpty {
                    practicesSection
                }

                if practices.isEmpty && sessions.isEmpty {
                    ContentUnavailableView(
                        "No Practice Yet",
                        systemImage: "pencil.and.list.clipboard",
                        description: Text("Generate practice questions from a worksheet to get started.")
                    )
                }
            }
            .navigationTitle("Practice")
            .onAppear {
                progressVM.loadStats(context: modelContext)
            }
            .sheet(item: $selectedPractice) { practice in
                GeneratedPracticeView(practice: practice)
            }
            .sheet(item: $scoreEntryPractice) { practice in
                ScoreEntryView(
                    viewModel: PracticeViewModel(
                        questionCount: practice.questionCount,
                        subjectName: practice.subjectName,
                        subTopicName: practice.subTopicName,
                        difficulty: practice.difficulty
                    ),
                    answerKeyText: practice.answerKeyText,
                    worksheet: practice.sourceWorksheet,
                    generatedPractice: practice
                )
            }
        }
    }

    private var progressSection: some View {
        Section("Progress") {
            LabeledContent("Total Sessions", value: "\(progressVM.totalSessions)")

            ForEach(progressVM.subjectStats) { stat in
                HStack {
                    Text(stat.subjectName)
                    Spacer()
                    Text("\(stat.sessionCount) sessions")
                        .foregroundStyle(.secondary)
                    Text("\(stat.averageScore)% avg")
                        .fontWeight(.medium)
                        .foregroundStyle(stat.averageScore >= 70 ? .green : .orange)
                }
            }
        }
    }

    private var practicesSection: some View {
        Section("Generated Practices") {
            ForEach(practices) { practice in
                Button {
                    selectedPractice = practice
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(practice.subjectName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            HStack(spacing: 8) {
                                Text("\(practice.questionCount) questions")
                                Text(practice.difficulty.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.tint.opacity(0.1))
                                    .foregroundStyle(.tint)
                                    .cornerRadius(4)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            Text(practice.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Button {
                            scoreEntryPractice = practice
                        } label: {
                            Label("Score", systemImage: "checkmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}
