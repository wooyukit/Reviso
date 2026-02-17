//
//  QuestionGeneratorView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct QuestionGeneratorView: View {
    let worksheet: Worksheet
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: QuestionGeneratorViewModel?
    @State private var settingsVM = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if viewModel.isGenerating {
                        generatingView
                    } else if viewModel.questions.isEmpty && viewModel.error == nil {
                        setupView
                    } else {
                        QuestionListView(viewModel: viewModel) {
                            Task { await generateQuestions(viewModel: viewModel) }
                        }
                    }
                } else {
                    providerSetupView
                }
            }
            .navigationTitle("Practice Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                settingsVM.loadAPIKey()
                setupProvider()
            }
        }
    }

    private var providerSetupView: some View {
        ContentUnavailableView {
            Label("AI Provider Not Configured", systemImage: "key")
        } description: {
            Text("Set up an AI provider in Settings to generate practice questions.")
        } actions: {
            Button("Open Settings") {
                dismiss()
            }
        }
    }

    private var setupView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("Generate similar practice questions from this worksheet")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let viewModel {
                Stepper("Number of questions: \(viewModel.questionCount)",
                        value: Binding(
                            get: { viewModel.questionCount },
                            set: { viewModel.questionCount = $0 }
                        ),
                        in: 1...10)
                .padding(.horizontal, 32)
            }

            Button {
                guard let viewModel else { return }
                Task { await generateQuestions(viewModel: viewModel) }
            } label: {
                Label("Generate Questions", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var generatingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Generating questions...")
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func setupProvider() {
        if let provider = settingsVM.createAnyProvider() {
            let generator = QuestionGenerator(provider: provider)
            viewModel = QuestionGeneratorViewModel(generator: generator)
        }
    }

    private func generateQuestions(viewModel: QuestionGeneratorViewModel) async {
        let image = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage)
        let ocrService = VisionTextRecognitionService()
        let text: String
        if let image {
            text = (try? await ocrService.recognizeText(in: image)) ?? ""
        } else {
            text = ""
        }
        await viewModel.generateQuestions(from: text, image: image)
    }
}
