//
//  ScanViewModelTests.swift
//  RevisoTests
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Testing
import UIKit
import SwiftData
@testable import Reviso

@Suite(.serialized)
struct ScanViewModelTests {

    private func createTestImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

    private func makeViewModel(shouldThrow: Bool = false, delay: TimeInterval = 0) -> ScanViewModel {
        let eraser = AnswerEraser { image in
            if delay > 0 {
                try await Task.sleep(for: .milliseconds(Int(delay * 1000)))
            }
            if shouldThrow {
                throw AnswerEraserError.inpaintingFailed
            }
            return image
        }
        return ScanViewModel(eraser: eraser)
    }

    @Test func processImage_setsCleanedImage() async {
        let vm = makeViewModel()
        await vm.processImage(createTestImage())

        #expect(vm.cleanedImage != nil)
        #expect(vm.error == nil)
    }

    @Test func processImage_setsLoadingState() async {
        let vm = makeViewModel()

        #expect(!vm.isProcessing)
        await vm.processImage(createTestImage())
        #expect(!vm.isProcessing)
    }

    @Test func processImage_error_setsErrorMessage() async {
        let vm = makeViewModel(shouldThrow: true)
        await vm.processImage(createTestImage())

        #expect(vm.error != nil)
        #expect(vm.cleanedImage == nil)
    }

    @Test func processImage_doesNotBlockMainThread() async {
        let vm = makeViewModel(delay: 0.5)
        let image = createTestImage()

        let task = Task { await vm.processImage(image) }

        try? await Task.sleep(for: .milliseconds(50))

        await MainActor.run {
            #expect(vm.isProcessing, "isProcessing should be true while processing runs in background")
        }

        await task.value
        #expect(!vm.isProcessing)
        #expect(vm.cleanedImage != nil)
    }

    @Test func saveWorksheet_persistsToStore() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Worksheet.self, configurations: config)
        let context = ModelContext(container)

        let vm = makeViewModel()
        vm.originalImage = createTestImage()
        vm.cleanedImage = createTestImage()

        vm.saveWorksheet(name: "Test", subject: "Math", context: context)

        let descriptor = FetchDescriptor<Worksheet>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].name == "Test")
        #expect(results[0].subject == "Math")
    }

    @Test func saveWorksheet_returnsWorksheet() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Worksheet.self, configurations: config)
        let context = ModelContext(container)

        let vm = makeViewModel()
        vm.originalImage = createTestImage()

        let result = vm.saveWorksheet(
            name: "Test",
            subject: "Math",
            subTopicName: "Algebra",
            context: context
        )

        #expect(result != nil)
        #expect(result?.name == "Test")
        #expect(result?.subject == "Math")
        #expect(result?.subTopicName == "Algebra")
    }

    @Test func saveWorksheet_returnsNil_whenNoImage() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Worksheet.self, configurations: config)
        let context = ModelContext(container)

        let vm = makeViewModel()

        let result = vm.saveWorksheet(
            name: "Test",
            subject: "Math",
            context: context
        )

        #expect(result == nil)
    }
}
