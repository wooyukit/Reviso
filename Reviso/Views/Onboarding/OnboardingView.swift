//
//  OnboardingView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 20/2/2026.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var poeKeyInput = ""
    @State private var selectedProvider: AIProviderType = .claude
    @State private var aiKeyInput = ""
    @State private var poeKeySaved = false
    @State private var aiKeySaved = false
    @State private var error: String?
    let onComplete: () -> Void

    private let keychainService = KeychainService()

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            poeKeyPage.tag(1)
            aiProviderPage.tag(2)
            completionPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Welcome to Reviso")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Practice smarter by erasing answers, generating questions, and tracking your progress.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            nextButton
        }
        .padding()
    }

    private var poeKeyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "eraser")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("Answer Eraser Setup")
                .font(.title2)
                .fontWeight(.bold)
            Text("To erase handwritten answers from worksheets, enter your Poe API key.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                SecureField("Poe API Key", text: $poeKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)

                if poeKeySaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Save Key") {
                        savePoeKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(poeKeyInput.isEmpty)
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
            HStack {
                skipButton
                Spacer()
                nextButton
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var aiProviderPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("Question Generator Setup")
                .font(.title2)
                .fontWeight(.bold)
            Text("To generate practice questions, choose an AI provider and enter your API key.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                SecureField("\(selectedProvider.displayName) API Key", text: $aiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)

                if aiKeySaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Save Key") {
                        saveAIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(aiKeyInput.isEmpty)
                }
            }

            Spacer()
            HStack {
                skipButton
                Spacer()
                nextButton
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var completionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Start by scanning a worksheet or exploring the app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Get Started") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Helpers

    private var nextButton: some View {
        Button {
            withAnimation { currentPage += 1 }
        } label: {
            Label("Next", systemImage: "chevron.right")
        }
        .buttonStyle(.borderedProminent)
    }

    private var skipButton: some View {
        Button("Skip") {
            withAnimation { currentPage += 1 }
        }
        .foregroundStyle(.secondary)
    }

    private func savePoeKey() {
        do {
            try keychainService.save(key: poeKeyInput, for: .poe)
            poeKeySaved = true
            poeKeyInput = ""
            error = nil
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func saveAIKey() {
        do {
            try keychainService.save(key: aiKeyInput, for: selectedProvider)
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedAIProvider")
            aiKeySaved = true
            aiKeyInput = ""
            error = nil
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }
}
