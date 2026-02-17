//
//  ScanViewModel.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

@Observable
final class ScanViewModel {
    var originalImage: UIImage?
    var cleanedImage: UIImage?
    var isProcessing = false
    var error: String?
    var showScanner = false
    var showPhotoPicker = false

    private let eraser: AnswerEraser

    init(eraser: AnswerEraser) {
        self.eraser = eraser
    }

    @MainActor
    func processImage(_ image: UIImage) async {
        originalImage = image
        isProcessing = true
        error = nil

        do {
            let processed = ImageUtils.resizeForProcessing(image)
            cleanedImage = try await eraser.eraseAnswers(from: processed)
        } catch {
            self.error = "Failed to process worksheet: \(error.localizedDescription)"
            cleanedImage = nil
        }

        isProcessing = false
    }

    func saveWorksheet(name: String, subject: String, context: ModelContext) {
        guard let originalData = originalImage?.jpegData(compressionQuality: 0.8) else { return }

        let worksheet = Worksheet(
            name: name,
            subject: subject,
            originalImage: originalData
        )
        worksheet.cleanedImage = cleanedImage?.jpegData(compressionQuality: 0.8)

        context.insert(worksheet)
        try? context.save()
    }

    func reset() {
        originalImage = nil
        cleanedImage = nil
        error = nil
    }
}
