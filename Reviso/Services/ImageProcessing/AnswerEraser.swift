//
//  AnswerEraser.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import UIKit

enum AnswerEraserError: Error {
    case inpaintingFailed
}

protocol AnswerEraserProtocol {
    /// Remove handwritten answers from a worksheet image.
    func eraseAnswers(from image: UIImage) async throws -> UIImage
}

/// Sends the worksheet image to an AI model to erase handwritten answers.
final class AnswerEraser: AnswerEraserProtocol {
    private let inpainter: PoeInpainter?
    private let cleanImageClosure: ((UIImage) async throws -> UIImage)?

    init(inpainter: PoeInpainter) {
        self.inpainter = inpainter
        self.cleanImageClosure = nil
    }

    /// Testable initializer with a closure.
    init(cleanImage: @escaping (UIImage) async throws -> UIImage) {
        self.inpainter = nil
        self.cleanImageClosure = cleanImage
    }

    func eraseAnswers(from image: UIImage) async throws -> UIImage {
        if let inpainter {
            return try await inpainter.cleanWorksheet(image)
        }
        return try await cleanImageClosure!(image)
    }
}
