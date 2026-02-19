//
//  Difficulty.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    var promptDescription: String {
        switch self {
        case .easy:
            "Generate simpler questions: use smaller numbers, fewer steps, and provide more hints. Make it easier than the original."
        case .medium:
            "Keep the same difficulty level as the original worksheet."
        case .hard:
            "Increase complexity, add multi-step problems, and provide less guidance. Make it harder than the original."
        }
    }
}
