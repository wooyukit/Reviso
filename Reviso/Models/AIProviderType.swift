//
//  AIProviderType.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation

enum AIProviderType: String, Codable, CaseIterable {
    case claude
    case openAI
    case gemini
    case poe

    var displayName: String {
        switch self {
        case .claude: "Claude"
        case .openAI: "OpenAI"
        case .gemini: "Gemini"
        case .poe: "Poe"
        }
    }

    var endpoint: String {
        switch self {
        case .claude: "https://api.anthropic.com/v1/messages"
        case .openAI: "https://api.openai.com/v1/chat/completions"
        case .gemini: "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
        case .poe: "https://api.poe.com/v1/chat/completions"
        }
    }
}
