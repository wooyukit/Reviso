//
//  SettingsView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                providerSection
                apiKeySection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadAPIKey()
            }
            .onChange(of: viewModel.selectedProvider) {
                viewModel.loadAPIKey()
                viewModel.apiKeyInput = ""
            }
        }
    }

    private var providerSection: some View {
        Section("AI Provider") {
            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(AIProviderType.allCases, id: \.self) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var apiKeySection: some View {
        Section {
            if viewModel.hasStoredKey {
                HStack {
                    Label("API Key Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Spacer()
                    Button("Remove", role: .destructive) {
                        viewModel.deleteAPIKey()
                    }
                    .buttonStyle(.borderless)
                }
            } else {
                SecureField("Enter API Key", text: $viewModel.apiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                Button("Save API Key") {
                    do {
                        try viewModel.saveAPIKey()
                    } catch {
                        viewModel.error = "Failed to save API key: \(error.localizedDescription)"
                    }
                }
                .disabled(viewModel.apiKeyInput.isEmpty)
            }

            if let error = viewModel.error {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        } header: {
            Text("\(viewModel.selectedProvider.displayName) API Key")
        } footer: {
            Text("Your API key is stored securely in the device Keychain and never sent to our servers.")
        }
    }

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            LabeledContent("App", value: "Reviso")
        }
    }
}

#Preview {
    SettingsView()
}
