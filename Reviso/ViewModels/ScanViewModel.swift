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
            let result = try await eraser.eraseAnswers(from: image)
            cleanedImage = result
        } catch {
            print("[ScanViewModel] Error type: \(type(of: error)), error: \(error)")
            if case AIProviderError.httpError(statusCode: 429) = error {
                self.error = "AI service is rate limited. Please wait a minute and try again."
            } else {
                self.error = "Failed to process worksheet: \(error.localizedDescription)"
            }
            cleanedImage = nil
        }

        isProcessing = false
    }

    @discardableResult
    func saveWorksheet(name: String, subject: String, subTopicName: String? = nil, context: ModelContext) -> Worksheet? {
        guard let originalData = originalImage?.jpegData(compressionQuality: 0.8) else { return nil }

        let worksheet = Worksheet(
            name: name,
            subject: subject,
            originalImage: originalData
        )
        worksheet.cleanedImage = cleanedImage?.jpegData(compressionQuality: 0.8)
        worksheet.subTopicName = subTopicName

        context.insert(worksheet)
        try? context.save()
        return worksheet
    }

    func reset() {
        originalImage = nil
        cleanedImage = nil
        error = nil
    }
}
