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
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

    var body: some View {
        TabView(selection: $navigation.selectedTab) {
            Tab("Worksheets", systemImage: "doc.text", value: .worksheets) {
                WorksheetsTabView()
            }

            Tab("Scan", systemImage: "camera", value: .scan) {
                ScanView()
            }

            Tab("Settings", systemImage: "gear", value: .settings) {
                SettingsView()
            }
        }
        .environment(navigation)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                showOnboarding = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Worksheet.self, GeneratedPractice.self, PracticeSession.self, QuestionResult.self], inMemory: true)
}
