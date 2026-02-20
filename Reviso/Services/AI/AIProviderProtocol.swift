//
//  AIProviderProtocol.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum AIProviderError: LocalizedError {
    case requestFailed(String)
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return "Request failed: \(message)"
        case .invalidResponse: return "Invalid response from AI provider"
        case .httpError(let code): return "HTTP error \(code) from AI provider"
        }
    }
}

protocol AIProviderProtocol {
    func send(prompt: String, image: UIImage?) async throws -> String
}
