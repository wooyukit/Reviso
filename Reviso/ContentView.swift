//
//  ContentView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                HomeView()
            }

            Tab("Practice", systemImage: "pencil.and.list.clipboard") {
                PracticeTabView()
            }

            Tab("Scan", systemImage: "camera") {
                ScanView()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Worksheet.self, GeneratedPractice.self, PracticeSession.self, QuestionResult.self], inMemory: true)
}
