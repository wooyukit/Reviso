# Simplify to Poe-Only Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove all multi-provider infrastructure and user API key management; use a single hardcoded Poe API key for both answer erasing and question generation, and drop the Settings tab.

**Architecture:** A new `APIConfig` singleton provides the Poe key to all consumers. `ScanView` and `QuestionGeneratorView` use it directly instead of reading from Keychain via `SettingsViewModel`. The app goes from 3 tabs to 2 (Worksheets + Scan). All unused provider/settings code is deleted.

**Tech Stack:** Swift, SwiftUI, SwiftData, Poe API (OpenAI-compatible)

---

### Task 1: Add APIConfig with hardcoded Poe key

Create a single source of truth for the API key.

**Files:**
- Create: `Reviso/Services/APIConfig.swift`

**Step 1: Create APIConfig**

```swift
// Reviso/Services/APIConfig.swift
import Foundation

enum APIConfig {
    /// Poe API key used for both answer erasing and question generation.
    static let poeAPIKey = "YOUR_POE_API_KEY_HERE"
}
```

> **Important:** Replace `YOUR_POE_API_KEY_HERE` with the actual Poe API key before building.

**Step 2: Commit**

```bash
git add Reviso/Services/APIConfig.swift
git commit -m "feat: add APIConfig with hardcoded Poe API key"
```

---

### Task 2: Simplify AIProviderProtocol — remove providerType

The `providerType` property is only used by the multi-provider picker. Remove it.

**Files:**
- Modify: `Reviso/Services/AI/AIProviderProtocol.swift`
- Modify: `Reviso/Services/AI/PoeProvider.swift`
- Modify: `RevisoTests/Mocks/MockAIProvider.swift`

**Step 1: Update AIProviderProtocol**

Remove the `providerType` requirement. The file becomes:

```swift
// Reviso/Services/AI/AIProviderProtocol.swift
import UIKit

enum AIProviderError: LocalizedError {
    case requestFailed(String)
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .requestFailed(let message): return "Request failed: \(message)"
        case .invalidResponse: return "Invalid response from AI provider"
        case .httpError(let code): return "HTTP error \(code) from AI provider"
        }
    }
}

protocol AIProviderProtocol {
    func send(prompt: String, image: UIImage?) async throws -> String
}
```

**Step 2: Remove providerType from PoeProvider**

In `Reviso/Services/AI/PoeProvider.swift`, delete line 13:
```swift
// DELETE: let providerType: AIProviderType = .poe
```

**Step 3: Remove providerType from MockAIProvider**

In `RevisoTests/Mocks/MockAIProvider.swift`, delete line 12:
```swift
// DELETE: var providerType: AIProviderType = .claude
```

**Step 4: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 5: Commit**

```bash
git add Reviso/Services/AI/AIProviderProtocol.swift Reviso/Services/AI/PoeProvider.swift RevisoTests/Mocks/MockAIProvider.swift
git commit -m "refactor: remove providerType from AIProviderProtocol"
```

---

### Task 3: Simplify ScanView — use APIConfig directly

Remove Keychain lookup and the "no provider" dead-end. The eraser always works now.

**Files:**
- Modify: `Reviso/Views/Scan/ScanView.swift`

**Step 1: Replace setupEraser() and remove noProviderView**

Changes:
1. Delete `@State private var settingsVM = SettingsViewModel()` (line 20)
2. Delete the entire `noProviderView` computed property (lines 86-97)
3. In the `body`, replace the `else { noProviderView }` branch (lines 38-40) — remove it so the Group always shows `inputSelectionView` when not processing/showing result
4. Replace `setupEraser()` with a version that uses `APIConfig.poeAPIKey`:

```swift
private func setupEraser() {
    guard viewModel == nil else { return }
    let inpainter = PoeInpainter(apiKey: APIConfig.poeAPIKey)
    let eraser = AnswerEraser(inpainter: inpainter)
    viewModel = ScanViewModel(eraser: eraser)
}
```

5. Since `viewModel` is now always set, the body's Group simplifies to:

```swift
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
        ProgressView()
    }
}
```

6. Remove `@Environment(AppNavigation.self) private var navigation: AppNavigation?` (line 25) — no longer needed for "Go to Settings" navigation.

**Step 2: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 3: Commit**

```bash
git add Reviso/Views/Scan/ScanView.swift
git commit -m "refactor: ScanView uses hardcoded Poe key, remove no-provider view"
```

---

### Task 4: Simplify QuestionGeneratorView — use APIConfig directly

Remove SettingsViewModel dependency and the "provider not configured" dead-end.

**Files:**
- Modify: `Reviso/Views/Practice/QuestionGeneratorView.swift`

**Step 1: Replace provider setup**

Changes:
1. Delete `@State private var settingsVM = SettingsViewModel()` (line 14)
2. Delete `@Environment(AppNavigation.self) private var navigation: AppNavigation?` (line 15)
3. Delete the entire `providerSetupView` computed property (lines 48-60)
4. In the `body`, replace `else { providerSetupView }` (lines 30-32) with `else { ProgressView() }`
5. Replace `setupProvider()`:

```swift
private func setupProvider() {
    let provider = PoeProvider(apiKey: APIConfig.poeAPIKey)
    let generator = QuestionGenerator(provider: provider)
    viewModel = QuestionGeneratorViewModel(generator: generator)
}
```

6. In `onAppear`, remove `settingsVM.loadAPIKey()` — just call `setupProvider()`.

**Step 2: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 3: Commit**

```bash
git add Reviso/Views/Practice/QuestionGeneratorView.swift
git commit -m "refactor: QuestionGeneratorView uses hardcoded Poe key"
```

---

### Task 5: Remove Settings tab and update AppNavigation

Go from 3 tabs to 2. Remove the `.settings` case.

**Files:**
- Modify: `Reviso/ContentView.swift`
- Modify: `Reviso/Models/AppNavigation.swift`

**Step 1: Update AppNavigation — remove .settings**

```swift
// Reviso/Models/AppNavigation.swift
import SwiftUI

enum AppTab: Int, CaseIterable {
    case worksheets
    case scan
}

@Observable
final class AppNavigation {
    var selectedTab: AppTab = .worksheets
}
```

**Step 2: Update ContentView — remove Settings tab**

```swift
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
        }
        .environment(navigation)
    }
}
```

**Step 3: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 4: Commit**

```bash
git add Reviso/ContentView.swift Reviso/Models/AppNavigation.swift
git commit -m "refactor: remove Settings tab, go to 2 tabs"
```

---

### Task 6: Delete unused source files

Remove all the multi-provider infrastructure and settings code that is no longer referenced.

**Files to delete:**
- `Reviso/Services/AI/ClaudeProvider.swift`
- `Reviso/Services/AI/OpenAIProvider.swift`
- `Reviso/Services/AI/GeminiProvider.swift`
- `Reviso/Models/AIProviderType.swift`
- `Reviso/ViewModels/SettingsViewModel.swift`
- `Reviso/Views/Settings/SettingsView.swift`
- `Reviso/Services/KeychainService.swift`

**Step 1: Delete files**

```bash
rm Reviso/Services/AI/ClaudeProvider.swift
rm Reviso/Services/AI/OpenAIProvider.swift
rm Reviso/Services/AI/GeminiProvider.swift
rm Reviso/Models/AIProviderType.swift
rm Reviso/ViewModels/SettingsViewModel.swift
rm Reviso/Views/Settings/SettingsView.swift
rm Reviso/Services/KeychainService.swift
```

**Step 2: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: delete unused multi-provider and settings code"
```

---

### Task 7: Update unit tests

Remove tests for deleted code, update remaining tests.

**Files to delete:**
- `RevisoTests/SettingsViewModelTests.swift`
- `RevisoTests/KeychainServiceTests.swift`

**Files to modify:**
- `RevisoTests/AIProviderTests.swift` — remove Claude, OpenAI, Gemini tests; keep only Poe tests
- `RevisoTests/GeneratedQuestionTests.swift` — remove `aiProviderType_properties` test (lines 116-123)
- `RevisoTests/AppNavigationTests.swift` — update tab count from 3 to 2, remove `.settings` assertion

**Step 1: Delete test files**

```bash
rm RevisoTests/SettingsViewModelTests.swift
rm RevisoTests/KeychainServiceTests.swift
```

**Step 2: Update AIProviderTests.swift**

Remove the Claude, OpenAI, and Gemini test sections and their JSON helpers. Keep only the Poe section and `makeSession()`. The file becomes:

```swift
// RevisoTests/AIProviderTests.swift
import Testing
import Foundation
@testable import Reviso

@Suite(.serialized)
struct AIProviderTests {

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    // MARK: - Poe Provider

    @Test func poeProvider_sendsCorrectRequest() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession())
        _ = try await provider.send(prompt: "Hello", image: nil)

        let request = MockURLProtocol.lastRequest
        #expect(request?.url?.absoluteString == "https://api.poe.com/v1/chat/completions")
        #expect(request?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request?.value(forHTTPHeaderField: "content-type") == "application/json")
        #expect(request?.httpMethod == "POST")
    }

    @Test func poeProvider_parsesResponse() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession())
        let result = try await provider.send(prompt: "Hello", image: nil)

        #expect(result == "Test response from Poe")
    }

    @Test func poeProvider_httpError_throws() async {
        MockURLProtocol.reset()
        MockURLProtocol.mockStatusCode = 401
        MockURLProtocol.mockResponseData = Data("{}".utf8)

        let provider = PoeProvider(apiKey: "bad-key", session: makeSession())

        await #expect(throws: AIProviderError.self) {
            try await provider.send(prompt: "Hello", image: nil)
        }
    }

    @Test func poeProvider_usesCorrectModel() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.mockResponseData = poeResponseJSON()

        let provider = PoeProvider(apiKey: "test-key", session: makeSession(), model: "Claude-3.5-Sonnet")
        _ = try await provider.send(prompt: "Hello", image: nil)

        let bodyData = MockURLProtocol.lastRequestBody ?? Data()
        let body = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        #expect(body?["model"] as? String == "Claude-3.5-Sonnet")
    }

    // MARK: - JSON Helpers

    private func poeResponseJSON() -> Data {
        """
        {
            "id": "chatcmpl-poe-test",
            "object": "chat.completion",
            "created": 1234567890,
            "model": "GPT-4o",
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": "Test response from Poe"},
                "finish_reason": "stop"
            }],
            "usage": {"prompt_tokens": 10, "completion_tokens": 5, "total_tokens": 15}
        }
        """.data(using: .utf8)!
    }
}
```

**Step 3: Update GeneratedQuestionTests.swift**

Remove the `aiProviderType_properties` test (lines 116-123). Delete those lines.

**Step 4: Update AppNavigationTests.swift**

```swift
@Test func tabCases_areTwo() {
    let cases = AppTab.allCases
    #expect(cases.count == 2)
    #expect(cases.contains(.worksheets))
    #expect(cases.contains(.scan))
}
```

**Step 5: Verify tests pass**

```bash
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests
```

**Step 6: Commit**

```bash
git add -A
git commit -m "test: update tests for Poe-only architecture"
```

---

### Task 8: Update UI tests

Fix tab assertions and remove settings UI tests.

**Files to delete:**
- `RevisoUITests/SettingsUITests.swift`

**Files to modify:**
- `RevisoUITests/RevisoUITests.swift`

**Step 1: Delete SettingsUITests**

```bash
rm RevisoUITests/SettingsUITests.swift
```

**Step 2: Update RevisoUITests.swift**

Update `testTabBar_showsThreeTabs` → rename to `testTabBar_showsTwoTabs`:

```swift
@MainActor
func testTabBar_showsTwoTabs() throws {
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.exists)

    XCTAssertTrue(tabBar.buttons["Worksheets"].exists)
    XCTAssertTrue(tabBar.buttons["Scan"].exists)
}
```

Remove `testTabBar_switchToSettingsTab` test entirely.

**Step 3: Verify build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 4: Commit**

```bash
git add -A
git commit -m "test: update UI tests for 2-tab layout"
```

---

### Task 9: Full build and test verification

**Step 1: Build**

```bash
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

**Step 2: Run all unit tests**

```bash
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests
```

Expected: **TEST SUCCEEDED**, 0 failures.
