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
    @State private var viewModel = ScanViewModel(
        eraser: AnswerEraser(
            detector: CoreMLHandwritingDetector(),
            inpainter: CoreMLInpainter()
        )
    )
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showSaveSheet = false
    @State private var worksheetName = ""
    @State private var worksheetSubject = ""

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isProcessing {
                    ProcessingView()
                } else if viewModel.cleanedImage != nil {
                    resultView
                } else {
                    inputSelectionView
                }
            }
            .navigationTitle("Scan Worksheet")
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                Text(viewModel.error ?? "")
            }
            .sheet(isPresented: $viewModel.showScanner) {
                DocumentScannerView { images in
                    viewModel.showScanner = false
                    if let first = images.first {
                        Task { await viewModel.processImage(first) }
                    }
                } onCancel: {
                    viewModel.showScanner = false
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                saveWorksheetSheet
            }
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
                    viewModel.showScanner = true
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
                            await viewModel.processImage(image)
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
            originalImage: viewModel.originalImage,
            cleanedImage: viewModel.cleanedImage,
            onSave: { showSaveSheet = true },
            onRetry: { viewModel.reset() }
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
                        viewModel.saveWorksheet(name: name, subject: subject, context: modelContext)
                        showSaveSheet = false
                        viewModel.reset()
                        worksheetName = ""
                        worksheetSubject = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ScanView()
        .modelContainer(for: Worksheet.self, inMemory: true)
}
