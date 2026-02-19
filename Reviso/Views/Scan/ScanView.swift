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
    @State private var worksheetSubject = "General"
    @State private var worksheetSubTopic: String?
    @State private var settingsVM = SettingsViewModel()
    @State private var scannedImage: UIImage?

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
            ), onDismiss: {
                // Process after scanner sheet animation is fully complete
                if let image = scannedImage {
                    scannedImage = nil
                    Task { await viewModel?.processImage(image) }
                }
            }) {
                DocumentScannerView { images in
                    viewModel?.showScanner = false
                    if let first = images.first {
                        scannedImage = first
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
            Label("Poe API Key Required", systemImage: "key")
        } description: {
            Text("Add your Poe API key in Settings to enable AI handwriting erasure.")
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
                            let normalizer = VisionDocumentNormalizer()
                            let normalized = (try? await normalizer.normalize(image)) ?? image
                            await viewModel?.processImage(normalized)
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
                SubjectPicker(selectedSubject: $worksheetSubject, selectedSubTopic: $worksheetSubTopic)
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
                        viewModel?.saveWorksheet(name: name, subject: worksheetSubject, context: modelContext)
                        // Set subTopicName on the most recently saved worksheet
                        if worksheetSubTopic != nil {
                            var descriptor = FetchDescriptor<Worksheet>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
                            descriptor.fetchLimit = 1
                            if let saved = try? modelContext.fetch(descriptor).first {
                                saved.subTopicName = worksheetSubTopic
                                try? modelContext.save()
                            }
                        }
                        showSaveSheet = false
                        viewModel?.reset()
                        worksheetName = ""
                        worksheetSubject = "General"
                        worksheetSubTopic = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func setupEraser() {
        let keychain = KeychainService()

        guard let key = try? keychain.retrieve(for: .poe), !key.isEmpty else {
            print("[ScanView] No Poe key, showing noProviderView")
            viewModel = nil
            return
        }

        let inpainter = PoeInpainter(apiKey: key)
        let eraser = AnswerEraser(inpainter: inpainter)
        print("[ScanView] Using PoeInpainter (Grok-Imagine-Image)")
        viewModel = ScanViewModel(eraser: eraser)
    }
}

#Preview {
    ScanView()
        .modelContainer(for: Worksheet.self, inMemory: true)
}
