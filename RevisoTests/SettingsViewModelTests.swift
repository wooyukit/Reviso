//
//  SettingsViewModelTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct SettingsViewModelTests {

    private let keychain = KeychainService(serviceName: "com.reviso.settings-tests")

    @Test func saveAPIKey_storesInKeychain() throws {
        let vm = SettingsViewModel(keychainService: keychain)
        vm.selectedProvider = .claude
        vm.apiKeyInput = "sk-test-key-123"

        try vm.saveAPIKey()

        let stored = try keychain.retrieve(for: .claude)
        #expect(stored == "sk-test-key-123")
        try keychain.delete(for: .claude)
    }

    @Test func loadProvider_restoresSelection() throws {
        try keychain.save(key: "test-key", for: .openAI)

        let vm = SettingsViewModel(keychainService: keychain)
        vm.selectedProvider = .openAI
        vm.loadAPIKey()

        #expect(vm.hasStoredKey)
        try keychain.delete(for: .openAI)
    }

    @Test func hasStoredKey_falseWhenNoKey() {
        let vm = SettingsViewModel(keychainService: keychain)
        vm.selectedProvider = .gemini
        vm.loadAPIKey()

        #expect(!vm.hasStoredKey)
    }

    @Test func deleteAPIKey_removesKey() throws {
        try keychain.save(key: "delete-me", for: .claude)

        let vm = SettingsViewModel(keychainService: keychain)
        vm.selectedProvider = .claude
        vm.deleteAPIKey()

        #expect(!keychain.hasKey(for: .claude))
    }
}
