//
//  Worksheet.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import Foundation
import SwiftData

@Model
final class Worksheet {
    var name: String
    var subject: String
    @Attribute(.externalStorage) var originalImage: Data
    @Attribute(.externalStorage) var cleanedImage: Data?
    var createdDate: Date

    init(name: String, subject: String, originalImage: Data) {
        self.name = name
        self.subject = subject
        self.originalImage = originalImage
        self.cleanedImage = nil
        self.createdDate = Date()
    }
}
