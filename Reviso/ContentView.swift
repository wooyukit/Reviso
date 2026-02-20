//
//  ContentView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigation = AppNavigation()

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Worksheets", systemImage: "doc.text", value: .worksheets) {
                WorksheetsTabView()
            }

            Tab("Scan", systemImage: "camera", value: .scan) {
                ScanView()
            }

            Tab("Settings", systemImage: "gearshape", value: .settings) {
                SettingsView()
            }
        }
        .environment(navigation)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Worksheet.self, GeneratedPractice.self, PracticeSession.self, QuestionResult.self], inMemory: true)
}
