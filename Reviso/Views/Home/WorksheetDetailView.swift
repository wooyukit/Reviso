//
//  WorksheetDetailView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

struct WorksheetDetailView: View {
    let worksheet: Worksheet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showOriginal = false
    @State private var showQuestionGenerator = false
    @State private var selectedPractice: GeneratedPractice?
    @State private var scoreEntryPractice: GeneratedPractice?

    @Query private var allPractices: [GeneratedPractice]
    @Query private var allSessions: [PracticeSession]

    private var practices: [GeneratedPractice] {
        allPractices.filter { $0.sourceWorksheet?.persistentModelID == worksheet.persistentModelID }
    }

    private var sessions: [PracticeSession] {
        allSessions.filter { $0.worksheet?.persistentModelID == worksheet.persistentModelID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    infoSection
                    actionButtons
                    if !practices.isEmpty {
                        practiceSection
                    }
                    if !sessions.isEmpty {
                        scoresSection
                    }
                }
                .padding()
            }
            .navigationTitle(worksheet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showQuestionGenerator) {
                QuestionGeneratorView(worksheet: worksheet)
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
                    worksheet: worksheet,
                    generatedPractice: practice
                )
            }
        }
    }

    private var imageSection: some View {
        VStack(spacing: 12) {
            let imageData = showOriginal
                ? worksheet.originalImage
                : (worksheet.cleanedImage ?? worksheet.originalImage)

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            }

            if worksheet.cleanedImage != nil {
                Picker("Version", selection: $showOriginal) {
                    Text("Cleaned").tag(false)
                    Text("Original").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Subject", value: worksheet.subject)
            if let subTopic = worksheet.subTopicName {
                LabeledContent("Topic", value: subTopic)
            }
            LabeledContent("Created", value: worksheet.createdDate, format: .dateTime.day().month().year())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showQuestionGenerator = true
            } label: {
                Label("Generate Practice Questions", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let practice = practices.first {
                Button {
                    selectedPractice = practice
                } label: {
                    Label("View Practice (\(practice.questionCount) qs)", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if let latestSession = sessions.first {
                    Button {
                        selectedPractice = practice
                    } label: {
                        Label("View Score: \(latestSession.correctCount)/\(latestSession.totalQuestions) (\(latestSession.scorePercentage)%)", systemImage: "chart.bar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        scoreEntryPractice = practice
                    } label: {
                        Label("Score Again", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                } else {
                    Button {
                        scoreEntryPractice = practice
                    } label: {
                        Label("Score My Answers", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }

            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                ShareLink(
                    item: Image(uiImage: uiImage),
                    preview: SharePreview(worksheet.name, image: Image(uiImage: uiImage))
                ) {
                    Label("Share Worksheet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Practice")
                .font(.headline)
            ForEach(practices) { practice in
                Button {
                    selectedPractice = practice
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(practice.questionCount) questions · \(practice.difficulty.displayName)")
                                .font(.subheadline)
                            Text(practice.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scores")
                .font(.headline)
            ForEach(sessions) { session in
                HStack {
                    Text("\(session.correctCount)/\(session.totalQuestions)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("(\(session.scorePercentage)%)")
                        .foregroundStyle(session.scorePercentage >= 70 ? .green : .orange)
                    Spacer()
                    Text(session.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
    }
}
