//
//  AIProviderProtocol.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum AIProviderError: Error {
    case requestFailed(String)
    case invalidResponse
    case httpError(statusCode: Int)
}

protocol AIProviderProtocol {
    var providerType: AIProviderType { get }
    func send(prompt: String, image: UIImage?) async throws -> String
}
