//
//  ProgressViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI
import SwiftData

struct SubjectStat: Identifiable {
    let id = UUID()
    let subjectName: String
    let sessionCount: Int
    let averageScore: Int
}

@Observable
final class ProgressViewModel {
    var totalSessions = 0
    var subjectStats: [SubjectStat] = []
    var recentSessions: [PracticeSession] = []

    func loadStats(context: ModelContext) {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sessions = try? context.fetch(descriptor) else { return }

        totalSessions = sessions.count
        recentSessions = Array(sessions.prefix(10))

        let grouped = Dictionary(grouping: sessions, by: \.subjectName)
        subjectStats = grouped.map { subject, sessions in
            let scores = sessions.map(\.scorePercentage)
            let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
            return SubjectStat(
                subjectName: subject,
                sessionCount: sessions.count,
                averageScore: avg
            )
        }.sorted { $0.sessionCount > $1.sessionCount }
    }
}
