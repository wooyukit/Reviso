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
    let onSave: () -> Void
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
                if let image, let uiImage = image as UIImage? {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }

            HStack(spacing: 16) {
                Button(role: .destructive) {
                    onRetry()
                } label: {
                    Label("Retry", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    onSave()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
        onSave: {},
        onRetry: {}
    )
}
