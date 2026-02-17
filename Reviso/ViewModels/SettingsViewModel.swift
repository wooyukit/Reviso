//
//  SettingsViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation

@Observable
final class SettingsViewModel {
    var selectedProvider: AIProviderType = .claude
    var apiKeyInput: String = ""
    var hasStoredKey = false
    var error: String?

    private let keychainService: KeychainService

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }

    func saveAPIKey() throws {
        guard !apiKeyInput.isEmpty else { return }
        try keychainService.save(key: apiKeyInput, for: selectedProvider)
        apiKeyInput = ""
        hasStoredKey = true
    }

    func loadAPIKey() {
        hasStoredKey = keychainService.hasKey(for: selectedProvider)
    }

    func deleteAPIKey() {
        try? keychainService.delete(for: selectedProvider)
        hasStoredKey = false
    }

    func createProvider() -> AIProviderProtocol? {
        guard let apiKey = try? keychainService.retrieve(for: selectedProvider) else {
            return nil
        }

        switch selectedProvider {
        case .claude:
            return ClaudeProvider(apiKey: apiKey)
        case .openAI:
            return OpenAIProvider(apiKey: apiKey)
        case .gemini:
            return GeminiProvider(apiKey: apiKey)
        }
    }
}
