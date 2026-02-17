# Reviso

A SwiftUI iOS app that helps students (ages 6-18) practice and revise exercises by erasing handwritten answers from worksheets and generating similar practice questions using AI.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Target:** iOS 17.0+
- **Persistence:** SwiftData
- **Image Caching:** Kingfisher (CocoaPods)
- **ML:** Core ML (handwriting segmentation + LaMa inpainting)
- **Architecture:** MVVM with `@Observable`
- **Package Manager:** CocoaPods

## Build & Run

```bash
# Install dependencies
cd /Users/wooyukit/Documents/iOSProjects/Reviso
pod install

# Build (use .xcworkspace after pod install)
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 16' build

# Before CocoaPods setup, use .xcodeproj
xcodebuild -project Reviso.xcodeproj -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Run Tests

```bash
# Unit tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RevisoTests

# UI tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:RevisoUITests

# All tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Project Structure

```
Reviso/
├── RevisoApp.swift              # App entry point, SwiftData container
├── Models/                      # SwiftData models & Codable types
├── Services/
│   ├── DocumentScanner/         # VNDocumentCameraViewController wrapper
│   ├── ImageProcessing/         # Handwriting detection + LaMa erasing
│   ├── AI/                      # AI provider protocol + implementations
│   ├── OCR/                     # Vision framework text recognition
│   ├── KeychainService.swift    # Secure API key storage
│   └── WorksheetStore.swift     # SwiftData CRUD
├── ViewModels/                  # @Observable view models
├── Views/                       # SwiftUI views
├── Resources/                   # Core ML models, assets
└── Utilities/                   # Image processing helpers
```

## Conventions

- **TDD approach:** Write tests first, then implement
- **Architecture:** MVVM with `@Observable` macro (not ObservableObject)
- **Networking:** `URLSession` + `async/await` (no Combine for networking)
- **DI:** Protocol-based injection for testability; all services have protocols
- **Testing:** Use mocks conforming to service protocols; use in-memory ModelContainer for SwiftData tests
- **Naming:** PascalCase for types, camelCase for properties/methods, descriptive test names with `test_methodName_expectedBehavior` pattern
- **Error handling:** Typed errors where possible; display user-friendly messages in ViewModels
- **Image processing:** All ML inference runs on-device via Core ML
- **API keys:** Stored in Keychain, never hardcoded or logged

## Key Features

1. **Answer Eraser:** Scan worksheet → detect handwriting (Core ML) → erase with inpainting (LaMa) → clean copy
2. **AI Question Generator:** OCR worksheet → send to AI (user's API key) → generate similar questions
3. **Worksheet Library:** SwiftData persistence of original + cleaned worksheets

## AI Providers Supported

Users provide their own API keys. Supported providers:
- **Claude** (Anthropic): `api.anthropic.com/v1/messages`
- **OpenAI**: `api.openai.com/v1/chat/completions`
- **Gemini** (Google): `generativelanguage.googleapis.com/v1beta/...`
