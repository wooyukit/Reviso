# 📝 Reviso

[![Platform](https://img.shields.io/badge/Platform-iOS%2017%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org/)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg)](https://developer.apple.com/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**An AI-powered worksheet revision app for students aged 6–18.** Scan worksheets, erase handwritten answers with AI, and generate fresh practice questions — all from your iPhone. 🧠✨

<!--
<p align="center">
  <img src="demo.gif" alt="Reviso Demo" width="300">
</p>
-->

## 🤔 Why Reviso?

Students finish a worksheet and want to practice again, but the answers are already written on it. Parents photocopy or buy new workbooks. **Reviso** solves this with AI magic:

- 🧹 **AI Answer Eraser** — Scan a worksheet, AI removes all handwriting, clean copy ready to print or fill in again
- 🤖 **Smart Question Generator** — AI reads your worksheet and creates similar practice questions at adjustable difficulty
- 📚 **Worksheet Library** — All your original + cleaned worksheets saved and organized
- ✅ **Self-Scoring** — Mark your answers, track your progress, see encouragement messages
- 🌐 **Bilingual** — Full app localization in English & 繁體中文, switchable in-app
- 🔒 **Privacy First** — No accounts, no sign-ups, everything stored locally on your device

## ✨ Features at a Glance

| Feature | What it does |
|---------|-------------|
| 📸 **Scan** | Use camera or photo library to capture worksheets |
| 🧹 **Erase** | AI-powered handwriting removal (Poe API + Grok-Imagine-Image) |
| 🤖 **Generate** | AI creates similar questions with Easy / Medium / Hard difficulty |
| 📋 **Library** | Browse, organize, and share your worksheet collection |
| ✍️ **Score** | Self-mark your practice, track correct/incorrect per question |
| 📊 **Progress** | See total sessions, per-subject stats, and average scores |
| 🌍 **Language** | Switch between English and 繁體中文 instantly |
| ⚙️ **Settings** | Language picker + app version info |

## 🚀 Getting Started

### Prerequisites

- 🍎 Xcode 16+
- 📱 iOS 17.0+ target
- 💎 [CocoaPods](https://cocoapods.org/) installed

### Installation

```bash
# Clone the repo
git clone https://github.com/wooyukit/Reviso.git
cd Reviso

# Install dependencies
pod install

# Open workspace (always use .xcworkspace with CocoaPods!)
open Reviso.xcworkspace
```

### Build & Run

```bash
# Build
xcodebuild -workspace Reviso.xcworkspace \
  -scheme Reviso \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
```

Hit ▶️ in Xcode or use the command above. That's it! 🎉

## 🎬 How It Works

```
📸 Scan worksheet ──→ 🧹 AI erases answers ──→ 📚 Save to library
                                                       │
                                                       ▼
                                               🤖 Generate questions
                                                       │
                                                       ▼
                                               ✍️ Practice & Score
                                                       │
                                                       ▼
                                               📊 Track progress!
```

### 1. 📸 Scan a Worksheet

Open the **Scan** tab → use camera or choose from photo library. The app automatically detects document boundaries and normalizes the image.

### 2. 🧹 AI Removes Handwriting

The scanned image is sent to the AI (Poe API with Grok-Imagine-Image model). It intelligently removes handwritten answers while preserving the printed questions. ✨

### 3. 🤖 Generate Similar Questions

Choose difficulty (Easy / Medium / Hard) and number of questions (1–10). The AI reads your worksheet via OCR and generates fresh practice questions in the same style.

### 4. ✍️ Score Your Answers

Mark each question ✅ or ❌. Get instant feedback with a score circle, percentage, and encouraging messages:

| Score | Message |
|-------|---------|
| 🏆 90–100% | *"Excellent work! You've mastered this!"* |
| ⭐ 80–89% | *"Great job! Almost perfect!"* |
| 💪 70–79% | *"Good effort! Keep practicing!"* |
| 📖 60–69% | *"Not bad! A bit more practice will help."* |
| 🌱 Below 60% | *"Keep going! Practice makes perfect."* |

## 🏗️ Architecture

```
Reviso/
├── 📱 RevisoApp.swift              # App entry point, SwiftData container
├── 🗂️ Models/                      # SwiftData models & Codable types
│   ├── AppNavigation.swift         # Tab navigation state
│   ├── AppLanguage.swift           # Language enum (en, zh-Hant)
│   ├── Worksheet.swift             # Core worksheet model
│   ├── GeneratedPractice.swift     # AI-generated questions
│   ├── PracticeSession.swift       # Scoring sessions
│   └── ...
├── ⚙️ Services/
│   ├── AI/                         # AI provider protocol + Poe implementation
│   ├── ImageProcessing/            # AI-powered answer erasing
│   ├── OCR/                        # Vision framework text recognition
│   ├── DocumentScanner/            # VNDocumentCameraViewController wrapper
│   └── APIConfig.swift             # API configuration
├── 🧠 ViewModels/                  # @Observable view models (MVVM)
├── 🎨 Views/                       # SwiftUI views
│   ├── Worksheets/                 # Library tab
│   ├── Scan/                       # Scan + process + result flow
│   ├── Practice/                   # Questions, scoring, summary
│   ├── Settings/                   # Language & version
│   └── Components/                 # Reusable UI components
├── 🔧 Utilities/                   # Image helpers, Bundle extension
└── 🌐 Localizable.xcstrings       # String Catalog (en + zh-Hant)
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| 🎨 **UI** | SwiftUI |
| 💾 **Persistence** | SwiftData |
| 🧠 **Architecture** | MVVM with `@Observable` |
| 🤖 **AI** | Poe API (OpenAI-compatible) |
| 🖼️ **Image Caching** | Kingfisher |
| 👁️ **OCR** | Apple Vision framework |
| 📦 **Dependencies** | CocoaPods |
| 🌐 **Localization** | String Catalog (.xcstrings) |

## 🧪 Testing

```bash
# Run unit tests 🧬
xcodebuild test -workspace Reviso.xcworkspace \
  -scheme Reviso \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RevisoTests

# Run UI tests 🖥️
xcodebuild test -workspace Reviso.xcworkspace \
  -scheme Reviso \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:RevisoUITests

# Run all tests 🚀
xcodebuild test -workspace Reviso.xcworkspace \
  -scheme Reviso \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Test Coverage

| Suite | Tests | What's covered |
|-------|-------|---------------|
| 🧬 **Unit Tests** | 80+ | Models, ViewModels, Services, AI providers, OCR, image processing |
| 🖥️ **UI Tests** | 15+ | Tab navigation, settings, scan flow, empty states |

All tests use **Swift Testing** (`@Test`, `#expect()`) for unit tests and **XCUITest** for UI tests. Mock protocols ensure fast, reliable, offline testing. ⚡

## 🌍 Localization

Reviso supports **in-app language switching** — no need to change your device settings!

| Language | Status |
|----------|--------|
| 🇬🇧 English | ✅ Complete |
| 🇭🇰 繁體中文 | ✅ Complete (68+ strings) |

Switch languages instantly in **Settings** → **Language**. All UI strings, buttons, navigation titles, error messages, and encouragement text are fully translated. 🎌

## 💡 Tips for Parents & Students

1. 📸 **Scan early, practice often** — Scan worksheets before filling them in for unlimited practice
2. 🎯 **Start with Medium** — Use Medium difficulty first, then adjust based on your score
3. 📊 **Track progress** — Check the Progress section to see which subjects need more work
4. 🔄 **Regenerate questions** — Not happy with the questions? Hit regenerate for a fresh set
5. 🖨️ **Share & print** — Use the share button to print cleaned worksheets or send to a printer app

## 🤝 Contributing

Contributions welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest new features
- 🌐 Add more language translations
- 🎨 Improve the UI/UX

## 📄 License

MIT © Vincent Woo
