# UX Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure Reviso's navigation into 3 tabs (Worksheets/Scan/Settings), add flow continuations after each action, fix dead-end screens, and add first-launch onboarding.

**Architecture:** Shared `AppNavigation` observable enables programmatic tab switching. `WorksheetsTabView` merges Home + Practice tabs. Flow continuations chain scan → generate → score via sheet presentations with `onDismiss` handoffs. Onboarding uses a full-screen cover on first launch.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing, `@Observable`, Keychain

---

### Task 1: AppNavigation Shared State

Create a shared observable that holds the selected tab, allowing any view to programmatically switch tabs (e.g., dead-end screens can navigate to Settings).

**Files:**
- Create: `Reviso/Models/AppNavigation.swift`
- Test: `RevisoTests/AppNavigationTests.swift`

**Step 1: Write the failing test**

```swift
// RevisoTests/AppNavigationTests.swift
import Testing
@testable import Reviso

struct AppNavigationTests {

    @Test func defaultTab_isWorksheets() {
        let nav = AppNavigation()
        #expect(nav.selectedTab == .worksheets)
    }

    @Test func tabCases_areThree() {
        let cases = AppTab.allCases
        #expect(cases.count == 3)
        #expect(cases.contains(.worksheets))
        #expect(cases.contains(.scan))
        #expect(cases.contains(.settings))
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/AppNavigationTests 2>&1 | tail -20`
Expected: FAIL — `AppNavigation` and `AppTab` not found

**Step 3: Write minimal implementation**

```swift
// Reviso/Models/AppNavigation.swift
import Foundation

enum AppTab: Int, CaseIterable {
    case worksheets
    case scan
    case settings
}

@Observable
final class AppNavigation {
    var selectedTab: AppTab = .worksheets
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/AppNavigationTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add Reviso/Models/AppNavigation.swift RevisoTests/AppNavigationTests.swift
git commit -m "feat: add AppNavigation shared state for tab switching"
```

---

### Task 2: ScanViewModel Returns Saved Worksheet

Currently `ScanViewModel.saveWorksheet()` returns `Void`. We need it to return the saved `Worksheet` so the "Save & Generate" flow can pass it to `QuestionGeneratorView`. Also consolidate the `subTopicName` save (currently done via a separate fetch in `ScanView`).

**Files:**
- Modify: `Reviso/ViewModels/ScanViewModel.swift:48-59`
- Test: `RevisoTests/ScanViewModelTests.swift` (create if not exists)

**Step 1: Write the failing test**

```swift
// RevisoTests/ScanViewModelTests.swift
import Testing
import SwiftData
import UIKit
@testable import Reviso

struct ScanViewModelTests {

    @Test func saveWorksheet_returnsWorksheet() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Worksheet.self, configurations: config)
        let context = ModelContext(container)

        // Create a mock eraser (we won't use it for save)
        let vm = ScanViewModel(eraser: AnswerEraser(inpainter: MockInpainter()))
        // Set a small test image
        vm.originalImage = UIImage(systemName: "star")

        let result = vm.saveWorksheet(
            name: "Test",
            subject: "Math",
            subTopicName: "Algebra",
            context: context
        )

        #expect(result != nil)
        #expect(result?.name == "Test")
        #expect(result?.subject == "Math")
        #expect(result?.subTopicName == "Algebra")
    }

    @Test func saveWorksheet_returnsNil_whenNoImage() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Worksheet.self, configurations: config)
        let context = ModelContext(container)

        let vm = ScanViewModel(eraser: AnswerEraser(inpainter: MockInpainter()))
        // No image set

        let result = vm.saveWorksheet(
            name: "Test",
            subject: "Math",
            context: context
        )

        #expect(result == nil)
    }
}

// Minimal mock for AnswerEraser dependency
private struct MockInpainter: AIInpainterProtocol {
    func inpaint(image: UIImage) async throws -> UIImage {
        return image
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/ScanViewModelTests 2>&1 | tail -20`
Expected: FAIL — `saveWorksheet` signature doesn't match (no return, no subTopicName param)

**Step 3: Modify ScanViewModel**

Replace the `saveWorksheet` method in `Reviso/ViewModels/ScanViewModel.swift:48-59` with:

```swift
    @discardableResult
    func saveWorksheet(name: String, subject: String, subTopicName: String? = nil, context: ModelContext) -> Worksheet? {
        guard let originalData = originalImage?.jpegData(compressionQuality: 0.8) else { return nil }

        let worksheet = Worksheet(
            name: name,
            subject: subject,
            originalImage: originalData
        )
        worksheet.cleanedImage = cleanedImage?.jpegData(compressionQuality: 0.8)
        worksheet.subTopicName = subTopicName

        context.insert(worksheet)
        try? context.save()
        return worksheet
    }
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/ScanViewModelTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add Reviso/ViewModels/ScanViewModel.swift RevisoTests/ScanViewModelTests.swift
git commit -m "feat: ScanViewModel.saveWorksheet returns saved Worksheet"
```

---

### Task 3: OnboardingView

Create a multi-page onboarding flow shown on first launch. Pages: Welcome → Poe API Key → AI Provider → Done.

**Files:**
- Create: `Reviso/Views/Onboarding/OnboardingView.swift`

**Step 1: Write OnboardingView**

```swift
// Reviso/Views/Onboarding/OnboardingView.swift
import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var poeKeyInput = ""
    @State private var selectedProvider: AIProviderType = .claude
    @State private var aiKeyInput = ""
    @State private var poeKeySaved = false
    @State private var aiKeySaved = false
    @State private var error: String?
    let onComplete: () -> Void

    private let keychainService = KeychainService()

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            poeKeyPage.tag(1)
            aiProviderPage.tag(2)
            completionPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }

    // MARK: - Pages

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "pencil.and.list.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(.tint)
            Text("Welcome to Reviso")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Practice smarter by erasing answers, generating questions, and tracking your progress.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            nextButton
        }
        .padding()
    }

    private var poeKeyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "eraser")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("Answer Eraser Setup")
                .font(.title2)
                .fontWeight(.bold)
            Text("To erase handwritten answers from worksheets, enter your Poe API key.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                SecureField("Poe API Key", text: $poeKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)

                if poeKeySaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Save Key") {
                        savePoeKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(poeKeyInput.isEmpty)
                }
            }

            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
            HStack {
                skipButton
                Spacer()
                nextButton
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var aiProviderPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.tint)
            Text("Question Generator Setup")
                .font(.title2)
                .fontWeight(.bold)
            Text("To generate practice questions, choose an AI provider and enter your API key.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Picker("Provider", selection: $selectedProvider) {
                    ForEach(AIProviderType.allCases, id: \.self) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 32)

                SecureField("\(selectedProvider.displayName) API Key", text: $aiKeyInput)
                    .textContentType(.password)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 32)

                if aiKeySaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Button("Save Key") {
                        saveAIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(aiKeyInput.isEmpty)
                }
            }

            Spacer()
            HStack {
                skipButton
                Spacer()
                nextButton
            }
            .padding(.horizontal)
        }
        .padding()
    }

    private var completionPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.circle")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Start by scanning a worksheet or exploring the app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button("Get Started") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }

    // MARK: - Helpers

    private var nextButton: some View {
        Button {
            withAnimation { currentPage += 1 }
        } label: {
            Label("Next", systemImage: "chevron.right")
        }
        .buttonStyle(.borderedProminent)
    }

    private var skipButton: some View {
        Button("Skip") {
            withAnimation { currentPage += 1 }
        }
        .foregroundStyle(.secondary)
    }

    private func savePoeKey() {
        do {
            try keychainService.save(key: poeKeyInput, for: .poe)
            poeKeySaved = true
            poeKeyInput = ""
            error = nil
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func saveAIKey() {
        do {
            try keychainService.save(key: aiKeyInput, for: selectedProvider)
            UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedAIProvider")
            aiKeySaved = true
            aiKeyInput = ""
            error = nil
        } catch {
            self.error = "Failed to save: \(error.localizedDescription)"
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Onboarding/OnboardingView.swift
git commit -m "feat: add OnboardingView for first-launch API key setup"
```

---

### Task 4: WorksheetsTabView (Merge Home + Practice)

Create a single tab view that shows the worksheet grid, recent practice sessions, and progress stats.

**Files:**
- Create: `Reviso/Views/Worksheets/WorksheetsTabView.swift`

**Step 1: Write WorksheetsTabView**

```swift
// Reviso/Views/Worksheets/WorksheetsTabView.swift
import SwiftUI
import SwiftData

struct WorksheetsTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Worksheet.createdDate, order: .reverse) private var worksheets: [Worksheet]
    @Query(sort: \GeneratedPractice.date, order: .reverse) private var practices: [GeneratedPractice]
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var progressVM = ProgressViewModel()
    @State private var selectedWorksheet: Worksheet?
    @State private var selectedPractice: GeneratedPractice?
    @State private var scoreEntryPractice: GeneratedPractice?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if worksheets.isEmpty && practices.isEmpty {
                    emptyStateView
                } else {
                    contentScrollView
                }
            }
            .navigationTitle("My Worksheets")
            .onAppear {
                progressVM.loadStats(context: modelContext)
            }
            .sheet(item: $selectedWorksheet) { worksheet in
                WorksheetDetailView(worksheet: worksheet)
            }
            .sheet(item: $selectedPractice) { practice in
                GeneratedPracticeView(practice: practice)
            }
            .sheet(item: $scoreEntryPractice) { practice in
                ScoreEntryView(
                    viewModel: PracticeViewModel(
                        questionCount: practice.questionCount,
                        subjectName: practice.subjectName,
                        subTopicName: practice.subTopicName,
                        difficulty: practice.difficulty
                    ),
                    answerKeyText: practice.answerKeyText,
                    worksheet: practice.sourceWorksheet,
                    generatedPractice: practice
                )
            }
        }
    }

    // MARK: - Sections

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Worksheets Yet",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Scan a worksheet to get started. Tap the Scan tab to begin.")
        )
    }

    private var contentScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !worksheets.isEmpty {
                    worksheetSection
                }
                if !practices.isEmpty {
                    practiceSection
                }
                if !sessions.isEmpty {
                    progressSection
                }
            }
            .padding()
        }
    }

    private var worksheetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
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
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Practice")
                .font(.headline)

            ForEach(practices) { practice in
                practiceRow(practice)
            }
        }
    }

    private func practiceRow(_ practice: GeneratedPractice) -> some View {
        Button {
            selectedPractice = practice
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(practice.subjectName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        Text("\(practice.questionCount) questions")
                        Text(practice.difficulty.displayName)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.1))
                            .foregroundStyle(.tint)
                            .cornerRadius(4)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    Text(practice.date, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button {
                    scoreEntryPractice = practice
                } label: {
                    Label("Score", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Total Sessions")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(progressVM.totalSessions)")
                        .fontWeight(.medium)
                }

                ForEach(progressVM.subjectStats) { stat in
                    HStack {
                        Text(stat.subjectName)
                        Spacer()
                        Text("\(stat.sessionCount) sessions")
                            .foregroundStyle(.secondary)
                        Text("\(stat.averageScore)% avg")
                            .fontWeight(.medium)
                            .foregroundStyle(stat.averageScore >= 70 ? .green : .orange)
                    }
                }
            }
            .font(.subheadline)
            .padding(12)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func deleteWorksheet(_ worksheet: Worksheet) {
        withAnimation {
            modelContext.delete(worksheet)
            try? modelContext.save()
        }
    }
}
```

Note: `WorksheetGridCell` is already defined in `Reviso/Views/Home/HomeView.swift:74-119`. We reuse it as-is.

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Worksheets/WorksheetsTabView.swift
git commit -m "feat: add WorksheetsTabView merging Home and Practice content"
```

---

### Task 5: ContentView — 3 Tabs + Onboarding

Update ContentView to use 3 tabs (Worksheets, Scan, Settings), shared `AppNavigation`, and show onboarding on first launch.

**Files:**
- Modify: `Reviso/ContentView.swift`
- Modify: `Reviso/RevisoApp.swift` (no changes needed if onboarding is in ContentView)

**Step 1: Rewrite ContentView**

Replace the entire body of `Reviso/ContentView.swift` with:

```swift
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
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/ContentView.swift
git commit -m "feat: update ContentView to 3 tabs with onboarding"
```

---

### Task 6: ResultView + ScanView — "Save & Generate" Flow

Update ResultView to show three buttons (Save & Generate, Save to Library, Retry). Update ScanView to handle the "Save & Generate" flow by navigating to QuestionGeneratorView after saving.

**Files:**
- Modify: `Reviso/Views/Scan/ResultView.swift`
- Modify: `Reviso/Views/Scan/ScanView.swift`

**Step 1: Update ResultView**

Replace the entire content of `Reviso/Views/Scan/ResultView.swift` with:

```swift
import SwiftUI

struct ResultView: View {
    let originalImage: UIImage?
    let cleanedImage: UIImage?
    let onSaveAndGenerate: () -> Void
    let onSaveToLibrary: () -> Void
    let onRetry: () -> Void

    @State private var showOriginal = false

    var body: some View {
        VStack(spacing: 16) {
            Picker("Version", selection: $showOriginal) {
                Text("Cleaned").tag(false)
                Text("Original").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                let image = showOriginal ? originalImage : cleanedImage
                if let uiImage = image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
            }

            VStack(spacing: 12) {
                Button {
                    onSaveAndGenerate()
                } label: {
                    Label("Save & Generate Questions", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    onSaveToLibrary()
                } label: {
                    Label("Save to Library", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(role: .destructive) {
                    onRetry()
                } label: {
                    Text("Retry")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    ResultView(
        originalImage: nil,
        cleanedImage: nil,
        onSaveAndGenerate: {},
        onSaveToLibrary: {},
        onRetry: {}
    )
}
```

**Step 2: Update ScanView**

Replace the entire content of `Reviso/Views/Scan/ScanView.swift` with:

```swift
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
    @State private var generateAfterSave = false
    @State private var pendingWorksheetForGenerator: Worksheet?
    @State private var worksheetForQuestionGenerator: Worksheet?
    @Environment(AppNavigation.self) private var navigation: AppNavigation?

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
            .sheet(isPresented: $showSaveSheet, onDismiss: {
                if let worksheet = pendingWorksheetForGenerator {
                    pendingWorksheetForGenerator = nil
                    worksheetForQuestionGenerator = worksheet
                }
            }) {
                saveWorksheetSheet
            }
            .sheet(item: $worksheetForQuestionGenerator) { worksheet in
                QuestionGeneratorView(worksheet: worksheet)
            }
        }
    }

    private var noProviderView: some View {
        ContentUnavailableView {
            Label("Poe API Key Required", systemImage: "key")
        } description: {
            Text("Add your Poe API key in Settings to enable AI handwriting erasure.")
        } actions: {
            Button("Go to Settings") {
                navigation?.selectedTab = .settings
            }
            .buttonStyle(.borderedProminent)
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
            onSaveAndGenerate: {
                generateAfterSave = true
                showSaveSheet = true
            },
            onSaveToLibrary: {
                generateAfterSave = false
                showSaveSheet = true
            },
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
                    Button("Cancel") {
                        showSaveSheet = false
                        generateAfterSave = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let name = worksheetName.isEmpty ? "Worksheet" : worksheetName
                        let worksheet = viewModel?.saveWorksheet(
                            name: name,
                            subject: worksheetSubject,
                            subTopicName: worksheetSubTopic,
                            context: modelContext
                        )
                        if generateAfterSave, let worksheet {
                            pendingWorksheetForGenerator = worksheet
                        }
                        showSaveSheet = false
                        viewModel?.reset()
                        worksheetName = ""
                        worksheetSubject = "General"
                        worksheetSubTopic = nil
                        generateAfterSave = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func setupEraser() {
        let keychain = KeychainService()

        guard let key = try? keychain.retrieve(for: .poe), !key.isEmpty else {
            viewModel = nil
            return
        }

        let inpainter = PoeInpainter(apiKey: key)
        let eraser = AnswerEraser(inpainter: inpainter)
        viewModel = ScanViewModel(eraser: eraser)
    }
}

#Preview {
    ScanView()
        .modelContainer(for: Worksheet.self, inMemory: true)
        .environment(AppNavigation())
}
```

**Step 3: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Reviso/Views/Scan/ResultView.swift Reviso/Views/Scan/ScanView.swift
git commit -m "feat: add Save & Generate flow continuation to scan result"
```

---

### Task 7: QuestionListView — "Save & Score Later" + Subject Passthrough

Add a prominent "Save & Score Later" button and pass the worksheet's subject/subTopic when saving (currently hardcoded to "General").

**Files:**
- Modify: `Reviso/Views/Practice/QuestionListView.swift`

**Step 1: Update QuestionListView**

Replace the entire content of `Reviso/Views/Practice/QuestionListView.swift` with:

```swift
import SwiftUI
import SwiftData

struct QuestionListView: View {
    let viewModel: QuestionGeneratorViewModel
    let worksheet: Worksheet?
    let onRegenerate: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var revealedAnswers: Set<Int> = []
    @State private var savedPractice: GeneratedPractice?
    @State private var showSaveSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            List {
                if let error = viewModel.error {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.red)
                    }
                }

                ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                    Section("Question \(index + 1)") {
                        QuestionDetailView(
                            question: question,
                            isRevealed: revealedAnswers.contains(index),
                            onToggleReveal: {
                                if revealedAnswers.contains(index) {
                                    revealedAnswers.remove(index)
                                } else {
                                    revealedAnswers.insert(index)
                                }
                            }
                        )
                    }
                }
            }

            if savedPractice == nil {
                saveBar
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        revealedAnswers.removeAll()
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }

                    if let questions = viewModel.questions.first,
                       !viewModel.questions.isEmpty {
                        ShareLink(
                            item: shareText,
                            preview: SharePreview("Practice Questions")
                        ) {
                            Label("Share Questions", systemImage: "square.and.arrow.up")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Saved", isPresented: $showSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Practice saved. You can score your answers from the Worksheets tab.")
        }
    }

    private var saveBar: some View {
        VStack(spacing: 8) {
            Button {
                savePractice()
            } label: {
                Label("Save & Score Later", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var shareText: String {
        viewModel.questions.enumerated().map { i, q in
            "Q\(i + 1): \(q.question)"
        }.joined(separator: "\n\n")
    }

    private func savePractice() {
        let questions = viewModel.questions
        let questionsText = questions.enumerated().map { i, q in
            "Q\(i + 1): \(q.question)"
        }.joined(separator: "\n\n")

        let answerKeyText = questions.enumerated().map { i, q in
            "A\(i + 1): \(q.correctAnswer ?? "N/A")\(q.explanation.map { " — \($0)" } ?? "")"
        }.joined(separator: "\n\n")

        let practice = GeneratedPractice(
            difficulty: viewModel.selectedDifficulty,
            subjectName: worksheet?.subject ?? "General",
            subTopicName: worksheet?.subTopicName,
            questionsText: questionsText,
            answerKeyText: answerKeyText,
            questionCount: questions.count
        )
        practice.sourceWorksheet = worksheet
        modelContext.insert(practice)
        try? modelContext.save()

        savedPractice = practice
        showSaveSuccess = true
    }
}
```

**Step 2: Update QuestionGeneratorView to pass worksheet**

In `Reviso/Views/Practice/QuestionGeneratorView.swift:25`, update the `QuestionListView` call to pass the worksheet:

Replace:
```swift
                        QuestionListView(viewModel: viewModel) {
                            Task { await generateQuestions(viewModel: viewModel) }
                        }
```

With:
```swift
                        QuestionListView(viewModel: viewModel, worksheet: worksheet) {
                            Task { await generateQuestions(viewModel: viewModel) }
                        }
```

**Step 3: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Reviso/Views/Practice/QuestionListView.swift Reviso/Views/Practice/QuestionGeneratorView.swift
git commit -m "feat: add Save & Score Later button and pass worksheet subject"
```

---

### Task 8: QuestionGeneratorView Dead-End Fix

When no AI provider is configured, the current "Open Settings" button just dismisses the sheet. Fix it to also switch to the Settings tab.

**Files:**
- Modify: `Reviso/Views/Practice/QuestionGeneratorView.swift`

**Step 1: Update QuestionGeneratorView**

Add environment access and update the providerSetupView. In `Reviso/Views/Practice/QuestionGeneratorView.swift`:

Add after line 13 (`@State private var settingsVM = SettingsViewModel()`):
```swift
    @Environment(AppNavigation.self) private var navigation: AppNavigation?
```

Replace the `providerSetupView` computed property (lines 47-57) with:
```swift
    private var providerSetupView: some View {
        ContentUnavailableView {
            Label("AI Provider Not Configured", systemImage: "key")
        } description: {
            Text("Set up an AI provider in Settings to generate practice questions.")
        } actions: {
            Button("Go to Settings") {
                dismiss()
                navigation?.selectedTab = .settings
            }
            .buttonStyle(.borderedProminent)
        }
    }
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Practice/QuestionGeneratorView.swift
git commit -m "fix: QuestionGeneratorView navigates to Settings tab when no provider"
```

---

### Task 9: WorksheetDetailView — Contextual Actions

Enhance the worksheet detail view to show different actions depending on whether the worksheet has generated practice, scored sessions, etc.

**Files:**
- Modify: `Reviso/Views/Home/WorksheetDetailView.swift`

**Step 1: Rewrite WorksheetDetailView**

Replace the entire content of `Reviso/Views/Home/WorksheetDetailView.swift` with:

```swift
import SwiftUI
import SwiftData

struct WorksheetDetailView: View {
    let worksheet: Worksheet
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showOriginal = false
    @State private var showQuestionGenerator = false
    @State private var selectedPractice: GeneratedPractice?
    @State private var scoreEntryPractice: GeneratedPractice?

    @Query private var allPractices: [GeneratedPractice]
    @Query private var allSessions: [PracticeSession]

    private var practices: [GeneratedPractice] {
        allPractices.filter { $0.sourceWorksheet?.persistentModelID == worksheet.persistentModelID }
    }

    private var sessions: [PracticeSession] {
        allSessions.filter { $0.worksheet?.persistentModelID == worksheet.persistentModelID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageSection
                    infoSection
                    actionButtons
                    if !practices.isEmpty {
                        practiceSection
                    }
                    if !sessions.isEmpty {
                        scoresSection
                    }
                }
                .padding()
            }
            .navigationTitle(worksheet.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showQuestionGenerator) {
                QuestionGeneratorView(worksheet: worksheet)
            }
            .sheet(item: $selectedPractice) { practice in
                GeneratedPracticeView(practice: practice)
            }
            .sheet(item: $scoreEntryPractice) { practice in
                ScoreEntryView(
                    viewModel: PracticeViewModel(
                        questionCount: practice.questionCount,
                        subjectName: practice.subjectName,
                        subTopicName: practice.subTopicName,
                        difficulty: practice.difficulty
                    ),
                    answerKeyText: practice.answerKeyText,
                    worksheet: worksheet,
                    generatedPractice: practice
                )
            }
        }
    }

    private var imageSection: some View {
        VStack(spacing: 12) {
            let imageData = showOriginal
                ? worksheet.originalImage
                : (worksheet.cleanedImage ?? worksheet.originalImage)

            if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(12)
            }

            if worksheet.cleanedImage != nil {
                Picker("Version", selection: $showOriginal) {
                    Text("Cleaned").tag(false)
                    Text("Original").tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Subject", value: worksheet.subject)
            if let subTopic = worksheet.subTopicName {
                LabeledContent("Topic", value: subTopic)
            }
            LabeledContent("Created", value: worksheet.createdDate, format: .dateTime.day().month().year())
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showQuestionGenerator = true
            } label: {
                Label("Generate Practice Questions", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            if let practice = practices.first {
                Button {
                    selectedPractice = practice
                } label: {
                    Label("View Practice (\(practice.questionCount) qs)", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button {
                    scoreEntryPractice = practice
                } label: {
                    Label("Score My Answers", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                ShareLink(
                    item: Image(uiImage: uiImage),
                    preview: SharePreview(worksheet.name, image: Image(uiImage: uiImage))
                ) {
                    Label("Share Worksheet", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Practice")
                .font(.headline)
            ForEach(practices) { practice in
                Button {
                    selectedPractice = practice
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(practice.questionCount) questions · \(practice.difficulty.displayName)")
                                .font(.subheadline)
                            Text(practice.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var scoresSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scores")
                .font(.headline)
            ForEach(sessions) { session in
                HStack {
                    Text("\(session.correctCount)/\(session.totalQuestions)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("(\(session.scorePercentage)%)")
                        .foregroundStyle(session.scorePercentage >= 70 ? .green : .orange)
                    Spacer()
                    Text(session.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(12)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Home/WorksheetDetailView.swift
git commit -m "feat: WorksheetDetailView shows contextual actions based on state"
```

---

### Task 10: Cleanup — Remove Old HomeView Usage

HomeView and PracticeTabView content has been moved to WorksheetsTabView. HomeView still defines `WorksheetGridCell` which is reused. Extract `WorksheetGridCell` out, then remove references to the old views.

**Files:**
- Modify: `Reviso/Views/Home/HomeView.swift` — keep only `WorksheetGridCell`, remove `HomeView`
- Delete content of: `Reviso/Views/Practice/PracticeTabView.swift` is no longer used from ContentView (but may still be referenced elsewhere — verify)

**Step 1: Update HomeView.swift to only contain WorksheetGridCell**

Replace the entire content of `Reviso/Views/Home/HomeView.swift` with:

```swift
import SwiftUI

struct WorksheetGridCell: View {
    let worksheet: Worksheet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let uiImage = UIImage(data: worksheet.cleanedImage ?? worksheet.originalImage) {
                Color.clear
                    .frame(height: 160)
                    .overlay {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
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
```

**Step 2: Verify PracticeTabView has no other references**

Search the codebase for `PracticeTabView` and `HomeView` references outside of their own files. The only reference should have been in the old `ContentView.swift` which we already updated. If there are no other references, `PracticeTabView.swift` can be deleted.

**Step 3: Build to verify**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Reviso/Views/Home/HomeView.swift
git commit -m "refactor: extract WorksheetGridCell, remove unused HomeView"
```

---

### Task 11: Run Full Test Suite

Run all tests to verify nothing is broken by the UX restructure.

**Step 1: Run all tests**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests 2>&1 | tail -30`
Expected: All tests pass (the 2 pre-existing flaky tests in AIProviderTests/AIInpainterTests may still fail — these are unrelated)

**Step 2: Fix any failures**

If any new test failures appear, investigate and fix them.

**Step 3: Final commit if fixes were needed**

```bash
git add -A
git commit -m "fix: resolve test failures from UX overhaul"
```

---

### Task 12: Build Verification + Cleanup

Final build verification and cleanup of any unused imports or files.

**Step 1: Full build**

Run: `xcodebuild build -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 2: Check for unused PracticeTabView**

If `PracticeTabView` is not referenced anywhere after Task 10, delete it:
```bash
rm Reviso/Views/Practice/PracticeTabView.swift
```

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: cleanup unused files after UX overhaul"
```
