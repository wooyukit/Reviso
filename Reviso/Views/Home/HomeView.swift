//
//  HomeView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worksheet.createdDate, order: .reverse) private var worksheets: [Worksheet]
    @State private var selectedWorksheet: Worksheet?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if worksheets.isEmpty {
                    emptyStateView
                } else {
                    worksheetGrid
                }
            }
            .navigationTitle("My Worksheets")
            .sheet(item: $selectedWorksheet) { worksheet in
                WorksheetDetailView(worksheet: worksheet)
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Worksheets Yet",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Scan a worksheet to get started. Tap the Scan tab to begin.")
        )
    }

    private var worksheetGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(worksheets) { worksheet in
                    WorksheetGridCell(worksheet: worksheet)
                        .onTapGesture {
                            selectedWorksheet = worksheet
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteWorksheet(worksheet)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }

    private func deleteWorksheet(_ worksheet: Worksheet) {
        withAnimation {
            modelContext.delete(worksheet)
            try? modelContext.save()
        }
    }
}

struct WorksheetGridCell: View {
    let worksheet: Worksheet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(height: 160)
                    .overlay {
                        Image(systemName: "doc.text")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(worksheet.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(worksheet.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(worksheet.createdDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(8)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Worksheet.self, inMemory: true)
}
