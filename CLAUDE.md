# Reviso

A SwiftUI iOS app that helps students (ages 6-18) practice and revise exercises by erasing handwritten answers from worksheets and generating similar practice questions using AI.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Target:** iOS 17.0+
- **Persistence:** SwiftData
- **Image Caching:** Kingfisher (CocoaPods)
- **AI Image Cleaning:** Poe API (Grok-Imagine-Image) — sends raw worksheet image, AI removes handwriting
- **Architecture:** MVVM with `@Observable`
- **Package Manager:** CocoaPods

## Build & Run

```bash
# Install dependencies
cd /Users/wooyukit/Documents/iOSProjects/Reviso
pod install

# Build (always use .xcworkspace with CocoaPods)
xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Run Tests

```bash
# Unit tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests

# UI tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoUITests

# All tests
xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Project Structure

```
Reviso/
├── RevisoApp.swift              # App entry point, SwiftData container
├── Models/                      # SwiftData models & Codable types
├── Services/
│   ├── DocumentScanner/         # VNDocumentCameraViewController wrapper
│   ├── ImageProcessing/         # AI-powered answer erasing (PoeInpainter, AnswerEraser)
│   ├── AI/                      # AI provider protocol + implementations
│   ├── OCR/                     # Vision framework text recognition
│   ├── KeychainService.swift    # Secure API key storage
│   └── WorksheetStore.swift     # SwiftData CRUD
├── ViewModels/                  # @Observable view models
├── Views/                       # SwiftUI views
├── Resources/                   # Assets
└── Utilities/                   # Image processing helpers (resize, base64)
```

## Conventions

- **TDD approach:** Write tests first, then implement
- **Architecture:** MVVM with `@Observable` macro (not ObservableObject)
- **Networking:** `URLSession` + `async/await` (no Combine for networking)
- **DI:** Protocol-based injection for testability; all services have protocols
- **Testing:** Use mocks conforming to service protocols; use in-memory ModelContainer for SwiftData tests
- **Naming:** PascalCase for types, camelCase for properties/methods, descriptive test names with `test_methodName_expectedBehavior` pattern
- **Error handling:** Typed errors where possible; display user-friendly messages in ViewModels
- **Image processing:** Raw worksheet image sent directly to Poe API (Grok-Imagine-Image); no on-device preprocessing. Includes retry with exponential backoff for 429 rate limits.
- **API keys:** Stored in Keychain, never hardcoded or logged

## Key Features

1. **Answer Eraser:** Scan worksheet → send to Poe API (Grok-Imagine-Image) → AI removes handwriting and cleans image → clean copy ready for students to fill in again
2. **AI Question Generator:** OCR worksheet → send to AI (user's API key) → generate similar questions
3. **Worksheet Library:** SwiftData persistence of original + cleaned worksheets

## AI Providers Supported

Users provide their own API keys. Supported providers for question generation:
- **Claude** (Anthropic): `api.anthropic.com/v1/messages`
- **OpenAI**: `api.openai.com/v1/chat/completions`
- **Gemini** (Google): `generativelanguage.googleapis.com/v1beta/...`
- **Poe**: `api.poe.com/v1/chat/completions`

**AI Inpainting (Answer Eraser):** Requires a Poe API key. Uses Poe's OpenAI-compatible API with the Grok-Imagine-Image model. Images are resized to max 1024px and sent as base64 JPEG. Retry with exponential backoff (up to 5 retries) handles 429 rate limits. The Poe key is independent of the question generation provider selection.
