//
//  WorksheetDetailView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct WorksheetDetailView: View {
    let worksheet: Worksheet
    @Environment(\.dismiss) private var dismiss
    @State private var showOriginal = false
    @State private var showQuestionGenerator = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    infoSection
                    actionButtons
                }
                .padding()
            }
            .navigationTitle(worksheet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showQuestionGenerator) {
                QuestionGeneratorView(worksheet: worksheet)
            }
        }
    }

    private var imageSection: some View {
        VStack(spacing: 12) {
            let imageData = showOriginal
                ? worksheet.originalImage
                : (worksheet.cleanedImage ?? worksheet.originalImage)

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            }

            if worksheet.cleanedImage != nil {
                Picker("Version", selection: $showOriginal) {
                    Text("Cleaned").tag(false)
                    Text("Original").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Subject", value: worksheet.subject)
            LabeledContent("Created", value: worksheet.createdDate, format: .dateTime.day().month().year())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showQuestionGenerator = true
            } label: {
                Label("Generate Practice Questions", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                ShareLink(
                    item: Image(uiImage: uiImage),
                    preview: SharePreview(worksheet.name, image: Image(uiImage: uiImage))
                ) {
                    Label("Share Worksheet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }
}
