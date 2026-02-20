//
//  RevisoApp.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI
import SwiftData

@main
struct RevisoApp: App {
    @State private var languageManager = LanguageManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Worksheet.self,
            GeneratedPractice.self,
            PracticeSession.self,
            QuestionResult.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(languageManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
