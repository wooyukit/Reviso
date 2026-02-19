//
//  ScoreSummaryView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI

struct ScoreSummaryView: View {
    let correctCount: Int
    let totalQuestions: Int
    let scorePercentage: Int
    let subjectName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            scoreCircle

            Text("\(correctCount) out of \(totalQuestions) correct")
                .font(.title2)
                .fontWeight(.semibold)

            Text(encouragementText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subjectName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.tint.opacity(0.1))
                .foregroundStyle(.tint)
                .cornerRadius(8)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom)
        }
    }

    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: Double(scorePercentage) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: scorePercentage)
            Text("\(scorePercentage)%")
                .font(.system(size: 36, weight: .bold))
        }
        .frame(width: 150, height: 150)
    }

    private var scoreColor: Color {
        switch scorePercentage {
        case 80...100: .green
        case 60..<80: .orange
        default: .red
        }
    }

    private var encouragementText: String {
        switch scorePercentage {
        case 90...100: "Excellent work! You've mastered this!"
        case 80..<90: "Great job! Almost perfect!"
        case 70..<80: "Good effort! Keep practicing!"
        case 60..<70: "Not bad! A bit more practice will help."
        default: "Keep going! Practice makes perfect."
        }
    }
}
