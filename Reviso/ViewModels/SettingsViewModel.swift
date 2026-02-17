//
//  SettingsViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation

@Observable
final class SettingsViewModel {
    var selectedProvider: AIProviderType {
        didSet {
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedAIProvider")
        }
    }
    var apiKeyInput: String = ""
    var hasStoredKey = false
    var error: String?

    private let keychainService: KeychainService

    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
        if let saved = UserDefaults.standard.string(forKey: "selectedAIProvider"),
           let provider = AIProviderType(rawValue: saved) {
            self.selectedProvider = provider
        } else {
            self.selectedProvider = .claude
        }
    }

    /// Try to create a provider from any stored API key.
    /// Checks the selected provider first, then falls back to any provider with a key.
    func createAnyProvider() -> AIProviderProtocol? {
        // Try the selected provider first
        if let provider = createProvider() {
            return provider
        }
        // Fall back: try all providers
        for type in AIProviderType.allCases {
            if let apiKey = try? keychainService.retrieve(for: type) {
                selectedProvider = type
                return createProviderFor(type: type, apiKey: apiKey)
            }
        }
        return nil
    }

    private func createProviderFor(type: AIProviderType, apiKey: String) -> AIProviderProtocol {
        switch type {
        case .claude: return ClaudeProvider(apiKey: apiKey)
        case .openAI: return OpenAIProvider(apiKey: apiKey)
        case .gemini: return GeminiProvider(apiKey: apiKey)
        case .poe: return PoeProvider(apiKey: apiKey)
        }
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
        case .poe:
            return PoeProvider(apiKey: apiKey)
        }
    }
}
