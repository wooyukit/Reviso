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

    private func makeViewModel() -> ScanViewModel {
        let detector = MockHandwritingDetector()
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)
        return ScanViewModel(eraser: eraser)
    }

    @Test func processImage_setsCleanedImage() async {
        let vm = makeViewModel()
        let image = createTestImage()

        await vm.processImage(image)

        #expect(vm.cleanedImage != nil)
        #expect(vm.error == nil)
    }

    @Test func processImage_setsLoadingState() async {
        let vm = makeViewModel()
        let image = createTestImage()

        #expect(!vm.isProcessing)
        await vm.processImage(image)
        #expect(!vm.isProcessing)
    }

    @Test func processImage_error_setsErrorMessage() async {
        let detector = MockHandwritingDetector()
        detector.shouldThrowError = true
        let inpainter = MockInpainter()
        let eraser = AnswerEraser(detector: detector, inpainter: inpainter)
        let vm = ScanViewModel(eraser: eraser)

        await vm.processImage(createTestImage())

        #expect(vm.error != nil)
        #expect(vm.cleanedImage == nil)
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
}
