//
//  WorksheetTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import Foundation
import SwiftData
@testable import Reviso

struct WorksheetTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Worksheet.self, configurations: config)
    }

    @Test func createWorksheet_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let imageData = Data("fake-image".utf8)
        let worksheet = Worksheet(
            name: "Math Homework",
            subject: "Math",
            originalImage: imageData
        )
        context.insert(worksheet)
        try context.save()

        #expect(worksheet.name == "Math Homework")
        #expect(worksheet.subject == "Math")
        #expect(worksheet.originalImage == imageData)
        #expect(worksheet.cleanedImage == nil)
        #expect(worksheet.createdDate <= Date())
    }

    @Test func createWorksheet_withCleanedImage() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let original = Data("original".utf8)
        let cleaned = Data("cleaned".utf8)
        let worksheet = Worksheet(
            name: "Science Quiz",
            subject: "Science",
            originalImage: original
        )
        worksheet.cleanedImage = cleaned
        context.insert(worksheet)
        try context.save()

        #expect(worksheet.cleanedImage == cleaned)
    }

    @Test func fetchWorksheets_orderedByDate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let older = Worksheet(name: "Old", subject: "Math", originalImage: Data())
        older.createdDate = Date(timeIntervalSinceNow: -3600)
        let newer = Worksheet(name: "New", subject: "Math", originalImage: Data())
        newer.createdDate = Date()

        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<Worksheet>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        let results = try context.fetch(descriptor)

        #expect(results.count == 2)
        #expect(results[0].name == "New")
        #expect(results[1].name == "Old")
    }

    @Test func deleteWorksheet_removesFromStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let worksheet = Worksheet(name: "Delete Me", subject: "Art", originalImage: Data())
        context.insert(worksheet)
        try context.save()

        context.delete(worksheet)
        try context.save()

        let descriptor = FetchDescriptor<Worksheet>()
        let results = try context.fetch(descriptor)
        #expect(results.isEmpty)
    }
}
