//
//  DifficultyTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import Testing
import Foundation
@testable import Reviso

struct DifficultyTests {

    @Test func difficulty_hasThreeCases() {
        let all = Difficulty.allCases
        #expect(all.count == 3)
        #expect(all.contains(.easy))
        #expect(all.contains(.medium))
        #expect(all.contains(.hard))
    }

    @Test func difficulty_displayNames() {
        #expect(Difficulty.easy.displayName == "Easy")
        #expect(Difficulty.medium.displayName == "Medium")
        #expect(Difficulty.hard.displayName == "Hard")
    }

    @Test func difficulty_promptDescriptions() {
        #expect(Difficulty.easy.promptDescription.contains("simpl"))
        #expect(Difficulty.medium.promptDescription.contains("same"))
        #expect(Difficulty.hard.promptDescription.contains("complex"))
    }

    @Test func difficulty_isCodable() throws {
        let encoded = try JSONEncoder().encode(Difficulty.medium)
        let decoded = try JSONDecoder().decode(Difficulty.self, from: encoded)
        #expect(decoded == .medium)
    }
}
