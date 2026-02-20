//
//  SettingsView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 21/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(LanguageManager.self) private var languageManager

    var body: some View {
        @Bindable var manager = languageManager
        NavigationStack {
            List {
                Section("Language") {
                    Picker("Language", selection: $manager.currentLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.versionDisplay)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
