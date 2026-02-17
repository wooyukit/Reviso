//
//  ScanView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ScanView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ScanViewModel?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSaveSheet = false
    @State private var worksheetName = ""
    @State private var worksheetSubject = ""
    @State private var settingsVM = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    if viewModel.isProcessing {
                        ProcessingView()
                    } else if viewModel.cleanedImage != nil {
                        resultView
                    } else {
                        inputSelectionView
                    }
                } else {
                    noProviderView
                }
            }
            .navigationTitle("Scan Worksheet")
            .onAppear {
                setupEraser()
            }
            .alert("Error", isPresented: .init(
                get: { viewModel?.error != nil },
                set: { if !$0 { viewModel?.error = nil } }
            )) {
                Button("OK") { viewModel?.error = nil }
            } message: {
                Text(viewModel?.error ?? "")
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showScanner ?? false },
                set: { viewModel?.showScanner = $0 }
            )) {
                DocumentScannerView { images in
                    viewModel?.showScanner = false
                    if let first = images.first {
                        Task { await viewModel?.processImage(first) }
                    }
                } onCancel: {
                    viewModel?.showScanner = false
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                saveWorksheetSheet
            }
        }
    }

    private var noProviderView: some View {
        ContentUnavailableView {
            Label("AI Provider Not Configured", systemImage: "key")
        } description: {
            Text("Set up an AI provider in Settings to enable worksheet scanning and answer erasing.")
        }
    }

    private var inputSelectionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.viewfinder")
                .font(.system(size: 80))
                .foregroundStyle(.tint)

            Text("Scan or pick a worksheet to erase handwritten answers")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 16) {
                Button {
                    viewModel?.showScanner = true
                } label: {
                    Label("Scan Document", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images
                ) {
                    Label("Choose from Library", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    Task {
                        if let data = try? await newItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await viewModel?.processImage(image)
                        }
                        selectedPhotoItem = nil
                    }
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    private var resultView: some View {
        ResultView(
            originalImage: viewModel?.originalImage,
            cleanedImage: viewModel?.cleanedImage,
            onSave: { showSaveSheet = true },
            onRetry: { viewModel?.reset() }
        )
    }

    private var saveWorksheetSheet: some View {
        NavigationStack {
            Form {
                TextField("Worksheet Name", text: $worksheetName)
                TextField("Subject", text: $worksheetSubject)
            }
            .navigationTitle("Save Worksheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSaveSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = worksheetName.isEmpty ? "Worksheet" : worksheetName
                        let subject = worksheetSubject.isEmpty ? "General" : worksheetSubject
                        viewModel?.saveWorksheet(name: name, subject: subject, context: modelContext)
                        showSaveSheet = false
                        viewModel?.reset()
                        worksheetName = ""
                        worksheetSubject = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func setupEraser() {
        if let provider = settingsVM.createAnyProvider() {
            let detector = AIHandwritingDetector(provider: provider)
            let inpainter = LocalInpainter()
            let eraser = AnswerEraser(detector: detector, inpainter: inpainter)
            viewModel = ScanViewModel(eraser: eraser)
        } else {
            viewModel = nil
        }
    }
}

#Preview {
    ScanView()
        .modelContainer(for: Worksheet.self, inMemory: true)
}
