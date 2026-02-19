// Reviso/Views/Worksheets/WorksheetsTabView.swift
import SwiftUI
import SwiftData

struct WorksheetsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worksheet.createdDate, order: .reverse) private var worksheets: [Worksheet]
    @Query(sort: \GeneratedPractice.date, order: .reverse) private var practices: [GeneratedPractice]
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var progressVM = ProgressViewModel()
    @State private var selectedWorksheet: Worksheet?
    @State private var selectedPractice: GeneratedPractice?
    @State private var scoreEntryPractice: GeneratedPractice?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if worksheets.isEmpty && practices.isEmpty {
                    emptyStateView
                } else {
                    contentScrollView
                }
            }
            .navigationTitle("My Worksheets")
            .onAppear {
                progressVM.loadStats(context: modelContext)
            }
            .sheet(item: $selectedWorksheet) { worksheet in
                WorksheetDetailView(worksheet: worksheet)
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

    // MARK: - Sections

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Worksheets Yet",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Scan a worksheet to get started. Tap the Scan tab to begin.")
        )
    }

    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !worksheets.isEmpty {
                    worksheetSection
                }
                if !practices.isEmpty {
                    practiceSection
                }
                if !sessions.isEmpty {
                    progressSection
                }
            }
            .padding()
        }
    }

    private var worksheetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(worksheets) { worksheet in
                    WorksheetGridCell(worksheet: worksheet)
                        .onTapGesture {
                            selectedWorksheet = worksheet
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteWorksheet(worksheet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Practice")
                .font(.headline)

            ForEach(practices) { practice in
                practiceRow(practice)
            }
        }
    }

    private func practiceRow(_ practice: GeneratedPractice) -> some View {
        Button {
            selectedPractice = practice
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(practice.subjectName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Text("\(practice.questionCount) questions")
                        Text(practice.difficulty.displayName)
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
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Total Sessions")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(progressVM.totalSessions)")
                        .fontWeight(.medium)
                }

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
            .font(.subheadline)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func deleteWorksheet(_ worksheet: Worksheet) {
        withAnimation {
            modelContext.delete(worksheet)
            try? modelContext.save()
        }
    }
}
