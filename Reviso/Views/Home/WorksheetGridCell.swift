//
//  WorksheetGridCell.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct WorksheetGridCell: View {
    let worksheet: Worksheet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                Color.clear
                    .frame(height: 160)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(worksheet.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(worksheet.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(worksheet.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
