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
    var isVerifying = false
    var isKeyValid: Bool?

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
        if let provider = createProvider() {
            return provider
        }
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
        isKeyValid = nil
        error = nil
    }

    func deleteAPIKey() {
        try? keychainService.delete(for: selectedProvider)
        hasStoredKey = false
        isKeyValid = nil
        error = nil
    }

    func createProvider() -> AIProviderProtocol? {
        guard let apiKey = try? keychainService.retrieve(for: selectedProvider) else {
            return nil
        }
        return createProviderFor(type: selectedProvider, apiKey: apiKey)
    }

    @MainActor
    func verifyAPIKey() async {
        guard let provider = createProvider() else {
            error = "No API key found."
            isKeyValid = false
            return
        }

        isVerifying = true
        error = nil
        isKeyValid = nil

        do {
            let _ = try await provider.send(prompt: "Reply with only the word: OK", image: nil)
            isKeyValid = true
        } catch let providerError as AIProviderError {
            isKeyValid = false
            switch providerError {
            case .httpError(let statusCode):
                if statusCode == 401 || statusCode == 403 {
                    error = "Invalid API key. Please check and try again."
                } else {
                    error = "API error (HTTP \(statusCode)). Please try again."
                }
            case .requestFailed(let message):
                error = "Request failed: \(message)"
            case .invalidResponse:
                error = "Unexpected response from provider."
            }
        } catch {
            isKeyValid = false
            self.error = "Connection failed: \(error.localizedDescription)"
        }

        isVerifying = false
    }
}
