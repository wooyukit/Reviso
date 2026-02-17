//
//  KeychainServiceTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct KeychainServiceTests {

    private let service = KeychainService(serviceName: "com.reviso.tests")

    @Test func saveAndRetrieveKey() throws {
        let key = "test-api-key-\(UUID().uuidString)"
        try service.save(key: key, for: .claude)
        let retrieved = try service.retrieve(for: .claude)
        #expect(retrieved == key)
        try service.delete(for: .claude)
    }

    @Test func deleteKey_removesFromKeychain() throws {
        let key = "delete-me-\(UUID().uuidString)"
        try service.save(key: key, for: .openAI)
        try service.delete(for: .openAI)

        #expect(throws: KeychainError.self) {
            try service.retrieve(for: .openAI)
        }
    }

    @Test func retrieveKey_notFound_throws() {
        #expect(throws: KeychainError.self) {
            try service.retrieve(for: .gemini)
        }
    }

    @Test func saveKey_overwritesExisting() throws {
        let first = "first-key-\(UUID().uuidString)"
        let second = "second-key-\(UUID().uuidString)"
        try service.save(key: first, for: .claude)
        try service.save(key: second, for: .claude)

        let retrieved = try service.retrieve(for: .claude)
        #expect(retrieved == second)
        try service.delete(for: .claude)
    }

    @Test func hasKey_returnsTrueWhenExists() throws {
        let key = "exists-\(UUID().uuidString)"
        try service.save(key: key, for: .openAI)
        #expect(service.hasKey(for: .openAI))
        try service.delete(for: .openAI)
    }

    @Test func hasKey_returnsFalseWhenMissing() {
        #expect(!service.hasKey(for: .gemini))
    }
}
