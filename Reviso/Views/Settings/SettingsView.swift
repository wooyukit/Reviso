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
                keyStatusView
            } else {
                SecureField("Enter API Key", text: $viewModel.apiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()

                Button("Save API Key") {
                    do {
                        try viewModel.saveAPIKey()
                        Task { await viewModel.verifyAPIKey() }
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

    private var keyStatusView: some View {
        VStack(spacing: 0) {
            HStack {
                if viewModel.isVerifying {
                    ProgressView()
                        .controlSize(.small)
                    Text("Verifying API key...")
                        .foregroundStyle(.secondary)
                } else if viewModel.isKeyValid == true {
                    Label("API Key Valid", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if viewModel.isKeyValid == false {
                    Label("API Key Invalid", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Label("API Key Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                Spacer()

                Button("Remove", role: .destructive) {
                    viewModel.deleteAPIKey()
                }
                .buttonStyle(.borderless)
                .disabled(viewModel.isVerifying)
            }

            if viewModel.isKeyValid == nil && !viewModel.isVerifying {
                Button("Verify API Key") {
                    Task { await viewModel.verifyAPIKey() }
                }
                .font(.caption)
                .padding(.top, 8)
            }
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
