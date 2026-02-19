//
//  ResultView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct ResultView: View {
    let originalImage: UIImage?
    let cleanedImage: UIImage?
    let onSaveAndGenerate: () -> Void
    let onSaveToLibrary: () -> Void
    let onRetry: () -> Void

    @State private var showOriginal = false

    var body: some View {
        VStack(spacing: 16) {
            Picker("Version", selection: $showOriginal) {
                Text("Cleaned").tag(false)
                Text("Original").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                let image = showOriginal ? originalImage : cleanedImage
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }

            VStack(spacing: 12) {
                Button {
                    onSaveAndGenerate()
                } label: {
                    Label("Save & Generate Questions", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    onSaveToLibrary()
                } label: {
                    Label("Save to Library", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    onRetry()
                } label: {
                    Text("Retry")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    ResultView(
        originalImage: nil,
        cleanedImage: nil,
        onSaveAndGenerate: {},
        onSaveToLibrary: {},
        onRetry: {}
    )
}
