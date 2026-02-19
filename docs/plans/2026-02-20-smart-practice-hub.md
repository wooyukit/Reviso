# Smart Practice Hub Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand Reviso with answer key generation, self-scoring, preset subjects, and progress tracking.

**Architecture:** Extend existing MVVM + SwiftData architecture. New SwiftData models (`GeneratedPractice`, `PracticeSession`, `QuestionResult`) link to existing `Worksheet`. Static `SubjectData` for predefined subjects. Modified `QuestionGenerator` accepts difficulty level. New Practice tab with progress dashboard.

**Tech Stack:** Swift, SwiftUI, SwiftData, @Observable, Swift Testing, async/await

**Design doc:** `docs/plans/2026-02-20-smart-practice-hub-design.md`

---

## Phase 1: Foundation Models

### Task 1: Add Difficulty Enum

**Files:**
- Create: `Reviso/Models/Difficulty.swift`
- Test: `RevisoTests/DifficultyTests.swift`

**Step 1: Write the failing test**

Create `RevisoTests/DifficultyTests.swift`:

```swift
import Testing
@testable import Reviso

struct DifficultyTests {

    @Test func difficulty_hasThreeCases() {
        let all = Difficulty.allCases
        #expect(all.count == 3)
        #expect(all.contains(.easy))
        #expect(all.contains(.medium))
        #expect(all.contains(.hard))
    }

    @Test func difficulty_displayNames() {
        #expect(Difficulty.easy.displayName == "Easy")
        #expect(Difficulty.medium.displayName == "Medium")
        #expect(Difficulty.hard.displayName == "Hard")
    }

    @Test func difficulty_promptDescriptions() {
        #expect(Difficulty.easy.promptDescription.contains("simpl"))
        #expect(Difficulty.medium.promptDescription.contains("same"))
        #expect(Difficulty.hard.promptDescription.contains("complex"))
    }

    @Test func difficulty_isCodable() throws {
        let encoded = try JSONEncoder().encode(Difficulty.medium)
        let decoded = try JSONDecoder().decode(Difficulty.self, from: encoded)
        #expect(decoded == .medium)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/DifficultyTests 2>&1 | tail -20`
Expected: FAIL — `Difficulty` type not found

**Step 3: Write minimal implementation**

Create `Reviso/Models/Difficulty.swift`:

```swift
import Foundation

enum Difficulty: String, Codable, CaseIterable {
    case easy
    case medium
    case hard

    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }

    var promptDescription: String {
        switch self {
        case .easy:
            "Simplify the concepts, use smaller numbers, and provide more hints. Make it easier than the original."
        case .medium:
            "Keep the same difficulty level as the original worksheet."
        case .hard:
            "Increase complexity, add multi-step problems, and provide less guidance. Make it harder than the original."
        }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/DifficultyTests 2>&1 | tail -20`
Expected: PASS — all 4 tests pass

**Step 5: Commit**

```bash
git add Reviso/Models/Difficulty.swift RevisoTests/DifficultyTests.swift
git commit -m "feat: add Difficulty enum with display names and prompt descriptions"
```

---

### Task 2: Add SubjectData Static Definitions

**Files:**
- Create: `Reviso/Models/SubjectData.swift`
- Test: `RevisoTests/SubjectDataTests.swift`

**Step 1: Write the failing test**

Create `RevisoTests/SubjectDataTests.swift`:

```swift
import Testing
@testable import Reviso

struct SubjectDataTests {

    @Test func subjects_containsExpectedCount() {
        #expect(SubjectData.all.count == 7)
    }

    @Test func subjects_mathHasExpectedSubTopics() {
        let math = SubjectData.all.first { $0.name == "Math" }
        #expect(math != nil)
        #expect(math?.subTopics.contains("Arithmetic") == true)
        #expect(math?.subTopics.contains("Fractions") == true)
        #expect(math?.subTopics.contains("Algebra") == true)
    }

    @Test func subjects_generalIsLast() {
        #expect(SubjectData.all.last?.name == "General")
    }

    @Test func subjectNames_returnsAllNames() {
        let names = SubjectData.subjectNames
        #expect(names.contains("Math"))
        #expect(names.contains("English"))
        #expect(names.contains("General"))
        #expect(names.count == 7)
    }

    @Test func subTopics_returnsCorrectListForSubject() {
        let topics = SubjectData.subTopics(for: "Science")
        #expect(topics.contains("Physics"))
        #expect(topics.contains("Chemistry"))
    }

    @Test func subTopics_returnsEmptyForUnknownSubject() {
        let topics = SubjectData.subTopics(for: "Unknown")
        #expect(topics.isEmpty)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/SubjectDataTests 2>&1 | tail -20`
Expected: FAIL — `SubjectData` type not found

**Step 3: Write minimal implementation**

Create `Reviso/Models/SubjectData.swift`:

```swift
import Foundation

struct SubjectInfo {
    let name: String
    let subTopics: [String]
}

enum SubjectData {
    static let all: [SubjectInfo] = [
        SubjectInfo(name: "Math", subTopics: ["Arithmetic", "Fractions", "Algebra", "Geometry", "Statistics"]),
        SubjectInfo(name: "English", subTopics: ["Grammar", "Vocabulary", "Comprehension", "Writing"]),
        SubjectInfo(name: "Science", subTopics: ["Physics", "Chemistry", "Biology", "General Science"]),
        SubjectInfo(name: "Chinese", subTopics: ["Reading", "Writing", "Vocabulary", "Grammar"]),
        SubjectInfo(name: "History", subTopics: ["World History", "Local History"]),
        SubjectInfo(name: "Geography", subTopics: ["Physical", "Human"]),
        SubjectInfo(name: "General", subTopics: ["Other", "Mixed"]),
    ]

    static var subjectNames: [String] {
        all.map(\.name)
    }

    static func subTopics(for subject: String) -> [String] {
        all.first { $0.name == subject }?.subTopics ?? []
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/SubjectDataTests 2>&1 | tail -20`
Expected: PASS — all 6 tests pass

**Step 5: Commit**

```bash
git add Reviso/Models/SubjectData.swift RevisoTests/SubjectDataTests.swift
git commit -m "feat: add SubjectData with predefined subjects and sub-topics"
```

---

### Task 3: Add GeneratedPractice SwiftData Model

**Files:**
- Create: `Reviso/Models/GeneratedPractice.swift`
- Test: `RevisoTests/GeneratedPracticeTests.swift`
- Modify: `Reviso/RevisoApp.swift:14` — register new model in schema

**Step 1: Write the failing test**

Create `RevisoTests/GeneratedPracticeTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Reviso

struct GeneratedPracticeTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Worksheet.self, GeneratedPractice.self, configurations: config)
    }

    @Test func createGeneratedPractice_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let practice = GeneratedPractice(
            difficulty: .medium,
            subjectName: "Math",
            subTopicName: "Algebra",
            questionsText: "Q1: Solve x + 5 = 10\nQ2: Solve 2x = 8",
            answerKeyText: "A1: x = 5\nA2: x = 4",
            questionCount: 2
        )
        context.insert(practice)
        try context.save()

        #expect(practice.difficulty == .medium)
        #expect(practice.subjectName == "Math")
        #expect(practice.subTopicName == "Algebra")
        #expect(practice.questionsText.contains("Solve x + 5"))
        #expect(practice.answerKeyText.contains("x = 5"))
        #expect(practice.questionCount == 2)
        #expect(practice.sourceWorksheet == nil)
    }

    @Test func createGeneratedPractice_withSourceWorksheet() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let worksheet = Worksheet(name: "Math HW", subject: "Math", originalImage: Data("img".utf8))
        context.insert(worksheet)

        let practice = GeneratedPractice(
            difficulty: .easy,
            subjectName: "Math",
            questionsText: "Q1: 2 + 3 = ?",
            answerKeyText: "A1: 5",
            questionCount: 1
        )
        practice.sourceWorksheet = worksheet
        context.insert(practice)
        try context.save()

        #expect(practice.sourceWorksheet?.name == "Math HW")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/GeneratedPracticeTests 2>&1 | tail -20`
Expected: FAIL — `GeneratedPractice` type not found

**Step 3: Write minimal implementation**

Create `Reviso/Models/GeneratedPractice.swift`:

```swift
import Foundation
import SwiftData

@Model
final class GeneratedPractice {
    var date: Date
    var difficulty: Difficulty
    var subjectName: String
    var subTopicName: String?
    var questionsText: String
    var answerKeyText: String
    var questionCount: Int
    var sourceWorksheet: Worksheet?

    init(
        difficulty: Difficulty,
        subjectName: String,
        subTopicName: String? = nil,
        questionsText: String,
        answerKeyText: String,
        questionCount: Int
    ) {
        self.date = Date()
        self.difficulty = difficulty
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.questionsText = questionsText
        self.answerKeyText = answerKeyText
        self.questionCount = questionCount
        self.sourceWorksheet = nil
    }
}
```

**Step 4: Register model in RevisoApp.swift**

In `Reviso/RevisoApp.swift`, change line 14 from:
```swift
let schema = Schema([
    Worksheet.self,
])
```
to:
```swift
let schema = Schema([
    Worksheet.self,
    GeneratedPractice.self,
])
```

**Step 5: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/GeneratedPracticeTests 2>&1 | tail -20`
Expected: PASS — all 2 tests pass

**Step 6: Commit**

```bash
git add Reviso/Models/GeneratedPractice.swift RevisoTests/GeneratedPracticeTests.swift Reviso/RevisoApp.swift
git commit -m "feat: add GeneratedPractice SwiftData model with worksheet relationship"
```

---

### Task 4: Add PracticeSession and QuestionResult SwiftData Models

**Files:**
- Create: `Reviso/Models/PracticeSession.swift`
- Create: `Reviso/Models/QuestionResult.swift`
- Test: `RevisoTests/PracticeSessionTests.swift`
- Modify: `Reviso/RevisoApp.swift:14-16` — register new models

**Step 1: Write the failing test**

Create `RevisoTests/PracticeSessionTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Reviso

struct PracticeSessionTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    @Test func createSession_hasCorrectProperties() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .hard,
            subjectName: "Science",
            subTopicName: "Physics",
            totalQuestions: 5
        )
        context.insert(session)
        try context.save()

        #expect(session.difficulty == .hard)
        #expect(session.subjectName == "Science")
        #expect(session.subTopicName == "Physics")
        #expect(session.totalQuestions == 5)
        #expect(session.questionResults.isEmpty)
    }

    @Test func session_correctCount_computedFromResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = PracticeSession(
            difficulty: .medium,
            subjectName: "Math",
            totalQuestions: 3
        )
        context.insert(session)

        let r1 = QuestionResult(questionNumber: 1, isCorrect: true)
        let r2 = QuestionResult(questionNumber: 2, isCorrect: false)
        let r3 = QuestionResult(questionNumber: 3, isCorrect: true)
        r1.session = session
        r2.session = session
        r3.session = session
        context.insert(r1)
        context.insert(r2)
        context.insert(r3)
        try context.save()

        #expect(session.correctCount == 2)
        #expect(session.scorePercentage == 67) // 2/3 * 100 rounded
    }

    @Test func session_withWorksheetRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let worksheet = Worksheet(name: "Test", subject: "Math", originalImage: Data())
        context.insert(worksheet)

        let session = PracticeSession(
            difficulty: .easy,
            subjectName: "Math",
            totalQuestions: 1
        )
        session.worksheet = worksheet
        context.insert(session)
        try context.save()

        #expect(session.worksheet?.name == "Test")
    }

    @Test func session_withGeneratedPracticeRelationship() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let practice = GeneratedPractice(
            difficulty: .medium,
            subjectName: "Math",
            questionsText: "Q1",
            answerKeyText: "A1",
            questionCount: 1
        )
        context.insert(practice)

        let session = PracticeSession(
            difficulty: .medium,
            subjectName: "Math",
            totalQuestions: 1
        )
        session.generatedPractice = practice
        context.insert(session)
        try context.save()

        #expect(session.generatedPractice != nil)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/PracticeSessionTests 2>&1 | tail -20`
Expected: FAIL — `PracticeSession` / `QuestionResult` types not found

**Step 3: Write minimal implementation**

Create `Reviso/Models/QuestionResult.swift`:

```swift
import Foundation
import SwiftData

@Model
final class QuestionResult {
    var questionNumber: Int
    var isCorrect: Bool
    var session: PracticeSession?

    init(questionNumber: Int, isCorrect: Bool) {
        self.questionNumber = questionNumber
        self.isCorrect = isCorrect
    }
}
```

Create `Reviso/Models/PracticeSession.swift`:

```swift
import Foundation
import SwiftData

@Model
final class PracticeSession {
    var date: Date
    var difficulty: Difficulty
    var subjectName: String
    var subTopicName: String?
    var totalQuestions: Int
    var worksheet: Worksheet?
    var generatedPractice: GeneratedPractice?
    @Relationship(deleteRule: .cascade, inverse: \QuestionResult.session)
    var questionResults: [QuestionResult] = []

    var correctCount: Int {
        questionResults.filter(\.isCorrect).count
    }

    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestions) * 100).rounded())
    }

    init(
        difficulty: Difficulty,
        subjectName: String,
        subTopicName: String? = nil,
        totalQuestions: Int
    ) {
        self.date = Date()
        self.difficulty = difficulty
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.totalQuestions = totalQuestions
    }
}
```

**Step 4: Register models in RevisoApp.swift**

In `Reviso/RevisoApp.swift`, update the schema to:
```swift
let schema = Schema([
    Worksheet.self,
    GeneratedPractice.self,
    PracticeSession.self,
    QuestionResult.self,
])
```

**Step 5: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/PracticeSessionTests 2>&1 | tail -20`
Expected: PASS — all 4 tests pass

**Step 6: Commit**

```bash
git add Reviso/Models/PracticeSession.swift Reviso/Models/QuestionResult.swift RevisoTests/PracticeSessionTests.swift Reviso/RevisoApp.swift
git commit -m "feat: add PracticeSession and QuestionResult SwiftData models"
```

---

### Task 5: Add subTopicName to Worksheet Model

**Files:**
- Modify: `Reviso/Models/Worksheet.swift`
- Modify: `RevisoTests/WorksheetTests.swift`

**Step 1: Write the failing test**

Add to `RevisoTests/WorksheetTests.swift`:

```swift
@Test func worksheet_subTopicName_defaultsToNil() throws {
    let container = try makeContainer()
    let context = ModelContext(container)

    let worksheet = Worksheet(name: "Test", subject: "Math", originalImage: Data())
    context.insert(worksheet)
    try context.save()

    #expect(worksheet.subTopicName == nil)
}

@Test func worksheet_subTopicName_canBeSet() throws {
    let container = try makeContainer()
    let context = ModelContext(container)

    let worksheet = Worksheet(name: "Test", subject: "Math", originalImage: Data())
    worksheet.subTopicName = "Algebra"
    context.insert(worksheet)
    try context.save()

    #expect(worksheet.subTopicName == "Algebra")
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/WorksheetTests 2>&1 | tail -20`
Expected: FAIL — `subTopicName` property not found on Worksheet

**Step 3: Write minimal implementation**

In `Reviso/Models/Worksheet.swift`, add after `var createdDate: Date`:
```swift
var subTopicName: String?
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/WorksheetTests 2>&1 | tail -20`
Expected: PASS — all 6 tests pass

**Step 5: Commit**

```bash
git add Reviso/Models/Worksheet.swift RevisoTests/WorksheetTests.swift
git commit -m "feat: add subTopicName to Worksheet model"
```

---

## Phase 2: Service Layer

### Task 6: Modify QuestionGenerator to Accept Difficulty

**Files:**
- Modify: `Reviso/Services/AI/QuestionGenerator.swift`
- Modify: `RevisoTests/QuestionGeneratorTests.swift`

**Step 1: Write the failing tests**

Add to `RevisoTests/QuestionGeneratorTests.swift`:

```swift
@Test func generate_withDifficulty_includesDifficultyInPrompt() async throws {
    let mockProvider = MockAIProvider()
    mockProvider.mockResponse = """
    [{"question": "Q", "type": "shortAnswer", "correctAnswer": "A"}]
    """

    let generator = QuestionGenerator(provider: mockProvider)
    _ = try await generator.generate(from: "Test", difficulty: .hard, count: 1)

    #expect(mockProvider.lastPrompt?.contains("complex") == true)
}

@Test func generate_withEasyDifficulty_includesEasyInPrompt() async throws {
    let mockProvider = MockAIProvider()
    mockProvider.mockResponse = """
    [{"question": "Q", "type": "shortAnswer", "correctAnswer": "A"}]
    """

    let generator = QuestionGenerator(provider: mockProvider)
    _ = try await generator.generate(from: "Test", difficulty: .easy, count: 1)

    #expect(mockProvider.lastPrompt?.contains("simpl") == true)
}

@Test func generate_withoutDifficulty_defaultsToMedium() async throws {
    let mockProvider = MockAIProvider()
    mockProvider.mockResponse = """
    [{"question": "Q", "type": "shortAnswer", "correctAnswer": "A"}]
    """

    let generator = QuestionGenerator(provider: mockProvider)
    _ = try await generator.generate(from: "Test", count: 1)

    #expect(mockProvider.lastPrompt?.contains("same") == true)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/QuestionGeneratorTests 2>&1 | tail -20`
Expected: FAIL — `generate` does not accept `difficulty` parameter

**Step 3: Update implementation**

In `Reviso/Services/AI/QuestionGenerator.swift`:

Update the `generate` method signature (line 22):
```swift
func generate(from worksheetText: String, image: UIImage? = nil, difficulty: Difficulty = .medium, count: Int = 3) async throws -> [GeneratedQuestion] {
    let prompt = buildPrompt(worksheetText: worksheetText, difficulty: difficulty, count: count)
    let response = try await provider.send(prompt: prompt, image: image)
    return try parseQuestions(from: response)
}
```

Update the `buildPrompt` method (line 28):
```swift
private func buildPrompt(worksheetText: String, difficulty: Difficulty, count: Int) -> String {
    """
    Analyze the following worksheet content and generate \(count) similar practice questions.

    DIFFICULTY LEVEL: \(difficulty.displayName)
    \(difficulty.promptDescription)

    WORKSHEET CONTENT:
    \(worksheetText)

    Return ONLY a valid JSON array with no additional text. Use this exact schema:
    [
        {
            "question": "question text",
            "type": "multipleChoice" or "shortAnswer" or "fillInBlank",
            "options": ["A", "B", "C", "D"],
            "correctAnswer": "the correct answer",
            "explanation": "brief explanation"
        }
    ]

    Notes:
    - "options" is only required for "multipleChoice" type
    - Always include "correctAnswer" and "explanation" for every question
    - Vary the question types when appropriate
    """
}
```

**Step 4: Run all QuestionGenerator tests**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/QuestionGeneratorTests 2>&1 | tail -20`
Expected: PASS — all 8 tests pass (5 existing + 3 new)

**Step 5: Commit**

```bash
git add Reviso/Services/AI/QuestionGenerator.swift RevisoTests/QuestionGeneratorTests.swift
git commit -m "feat: add difficulty parameter to QuestionGenerator"
```

---

## Phase 3: ViewModels

### Task 7: Update QuestionGeneratorViewModel for Difficulty

**Files:**
- Modify: `Reviso/ViewModels/QuestionGeneratorViewModel.swift`
- Modify: `RevisoTests/QuestionGeneratorViewModelTests.swift`

**Step 1: Write the failing test**

Add to `RevisoTests/QuestionGeneratorViewModelTests.swift` (read the file first to understand existing test structure):

```swift
@Test func generateQuestions_passesDifficultyToGenerator() async {
    let mockProvider = MockAIProvider()
    mockProvider.mockResponse = """
    [{"question": "Q", "type": "shortAnswer", "correctAnswer": "A"}]
    """

    let generator = QuestionGenerator(provider: mockProvider)
    let vm = QuestionGeneratorViewModel(generator: generator)
    vm.selectedDifficulty = .hard

    await vm.generateQuestions(from: "Test")

    #expect(mockProvider.lastPrompt?.contains("complex") == true)
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/QuestionGeneratorViewModelTests 2>&1 | tail -20`
Expected: FAIL — `selectedDifficulty` property not found

**Step 3: Update implementation**

In `Reviso/ViewModels/QuestionGeneratorViewModel.swift`, add the property after `var questionCount = 3`:
```swift
var selectedDifficulty: Difficulty = .medium
```

Update the `generateQuestions` method to pass difficulty:
```swift
@MainActor
func generateQuestions(from text: String, image: UIImage? = nil) async {
    isGenerating = true
    error = nil
    questions = []

    do {
        questions = try await generator.generate(from: text, image: image, difficulty: selectedDifficulty, count: questionCount)
    } catch {
        self.error = "Failed to generate questions: \(error.localizedDescription)"
    }

    isGenerating = false
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/QuestionGeneratorViewModelTests 2>&1 | tail -20`
Expected: PASS

**Step 5: Commit**

```bash
git add Reviso/ViewModels/QuestionGeneratorViewModel.swift RevisoTests/QuestionGeneratorViewModelTests.swift
git commit -m "feat: add difficulty selection to QuestionGeneratorViewModel"
```

---

### Task 8: Add PracticeViewModel for Self-Scoring

**Files:**
- Create: `Reviso/ViewModels/PracticeViewModel.swift`
- Test: `RevisoTests/PracticeViewModelTests.swift`

**Step 1: Write the failing test**

Create `RevisoTests/PracticeViewModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Reviso

struct PracticeViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    @Test func init_setsUpCorrectQuestionCount() {
        let vm = PracticeViewModel(questionCount: 5, subjectName: "Math", difficulty: .medium)
        #expect(vm.totalQuestions == 5)
        #expect(vm.results.count == 5)
        #expect(vm.results.allSatisfy { $0 == nil })
    }

    @Test func markQuestion_updatesResult() {
        let vm = PracticeViewModel(questionCount: 3, subjectName: "Math", difficulty: .easy)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)

        #expect(vm.results[0] == true)
        #expect(vm.results[1] == false)
        #expect(vm.results[2] == nil)
    }

    @Test func toggleQuestion_flipsResult() {
        let vm = PracticeViewModel(questionCount: 2, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        #expect(vm.results[0] == true)

        vm.markQuestion(1, isCorrect: false)
        #expect(vm.results[0] == false)
    }

    @Test func isComplete_trueWhenAllMarked() {
        let vm = PracticeViewModel(questionCount: 2, subjectName: "Math", difficulty: .hard)
        #expect(vm.isComplete == false)

        vm.markQuestion(1, isCorrect: true)
        #expect(vm.isComplete == false)

        vm.markQuestion(2, isCorrect: false)
        #expect(vm.isComplete == true)
    }

    @Test func correctCount_countsOnlyCorrect() {
        let vm = PracticeViewModel(questionCount: 3, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)
        vm.markQuestion(3, isCorrect: true)

        #expect(vm.correctCount == 2)
    }

    @Test func scorePercentage_calculatesCorrectly() {
        let vm = PracticeViewModel(questionCount: 4, subjectName: "Math", difficulty: .medium)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: true)
        vm.markQuestion(3, isCorrect: true)
        vm.markQuestion(4, isCorrect: false)

        #expect(vm.scorePercentage == 75)
    }

    @Test func saveSession_createsSessionWithResults() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let vm = PracticeViewModel(questionCount: 2, subjectName: "Science", subTopicName: "Physics", difficulty: .hard)
        vm.markQuestion(1, isCorrect: true)
        vm.markQuestion(2, isCorrect: false)

        vm.saveSession(context: context)

        let descriptor = FetchDescriptor<PracticeSession>()
        let sessions = try context.fetch(descriptor)
        #expect(sessions.count == 1)
        #expect(sessions[0].subjectName == "Science")
        #expect(sessions[0].subTopicName == "Physics")
        #expect(sessions[0].difficulty == .hard)
        #expect(sessions[0].totalQuestions == 2)
        #expect(sessions[0].questionResults.count == 2)
        #expect(sessions[0].correctCount == 1)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/PracticeViewModelTests 2>&1 | tail -20`
Expected: FAIL — `PracticeViewModel` type not found

**Step 3: Write minimal implementation**

Create `Reviso/ViewModels/PracticeViewModel.swift`:

```swift
import SwiftUI
import SwiftData

@Observable
final class PracticeViewModel {
    let totalQuestions: Int
    let subjectName: String
    let subTopicName: String?
    let difficulty: Difficulty
    var results: [Bool?]
    var showAnswerKey = false

    var isComplete: Bool {
        results.allSatisfy { $0 != nil }
    }

    var correctCount: Int {
        results.compactMap { $0 }.filter { $0 }.count
    }

    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctCount) / Double(totalQuestions) * 100).rounded())
    }

    init(questionCount: Int, subjectName: String, subTopicName: String? = nil, difficulty: Difficulty) {
        self.totalQuestions = questionCount
        self.subjectName = subjectName
        self.subTopicName = subTopicName
        self.difficulty = difficulty
        self.results = Array(repeating: nil, count: questionCount)
    }

    func markQuestion(_ number: Int, isCorrect: Bool) {
        guard number >= 1, number <= totalQuestions else { return }
        results[number - 1] = isCorrect
    }

    func saveSession(context: ModelContext, worksheet: Worksheet? = nil, generatedPractice: GeneratedPractice? = nil) {
        let session = PracticeSession(
            difficulty: difficulty,
            subjectName: subjectName,
            subTopicName: subTopicName,
            totalQuestions: totalQuestions
        )
        session.worksheet = worksheet
        session.generatedPractice = generatedPractice
        context.insert(session)

        for (index, result) in results.enumerated() {
            guard let isCorrect = result else { continue }
            let questionResult = QuestionResult(questionNumber: index + 1, isCorrect: isCorrect)
            questionResult.session = session
            context.insert(questionResult)
        }

        try? context.save()
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/PracticeViewModelTests 2>&1 | tail -20`
Expected: PASS — all 7 tests pass

**Step 5: Commit**

```bash
git add Reviso/ViewModels/PracticeViewModel.swift RevisoTests/PracticeViewModelTests.swift
git commit -m "feat: add PracticeViewModel for self-scoring with SwiftData persistence"
```

---

### Task 9: Add ProgressViewModel for Dashboard Stats

**Files:**
- Create: `Reviso/ViewModels/ProgressViewModel.swift`
- Test: `RevisoTests/ProgressViewModelTests.swift`

**Step 1: Write the failing test**

Create `RevisoTests/ProgressViewModelTests.swift`:

```swift
import Testing
import Foundation
import SwiftData
@testable import Reviso

struct ProgressViewModelTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Worksheet.self, GeneratedPractice.self,
            PracticeSession.self, QuestionResult.self,
            configurations: config
        )
    }

    private func createSession(
        context: ModelContext,
        subject: String,
        correct: Int,
        total: Int,
        difficulty: Difficulty = .medium
    ) {
        let session = PracticeSession(
            difficulty: difficulty,
            subjectName: subject,
            totalQuestions: total
        )
        context.insert(session)
        for i in 1...total {
            let result = QuestionResult(questionNumber: i, isCorrect: i <= correct)
            result.session = session
            context.insert(result)
        }
        try? context.save()
    }

    @Test func loadStats_withNoSessions_returnsZeros() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let vm = ProgressViewModel()

        vm.loadStats(context: context)

        #expect(vm.totalSessions == 0)
        #expect(vm.subjectStats.isEmpty)
    }

    @Test func loadStats_countsTotalSessions() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        createSession(context: context, subject: "Math", correct: 3, total: 5)
        createSession(context: context, subject: "Science", correct: 4, total: 5)

        let vm = ProgressViewModel()
        vm.loadStats(context: context)

        #expect(vm.totalSessions == 2)
    }

    @Test func loadStats_groupsBySubject() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        createSession(context: context, subject: "Math", correct: 4, total: 5)
        createSession(context: context, subject: "Math", correct: 3, total: 5)
        createSession(context: context, subject: "Science", correct: 5, total: 5)

        let vm = ProgressViewModel()
        vm.loadStats(context: context)

        #expect(vm.subjectStats.count == 2)
        let mathStat = vm.subjectStats.first { $0.subjectName == "Math" }
        #expect(mathStat?.sessionCount == 2)
        #expect(mathStat?.averageScore == 70) // (80 + 60) / 2
    }
}
```

**Step 2: Run test to verify it fails**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/ProgressViewModelTests 2>&1 | tail -20`
Expected: FAIL — `ProgressViewModel` type not found

**Step 3: Write minimal implementation**

Create `Reviso/ViewModels/ProgressViewModel.swift`:

```swift
import SwiftUI
import SwiftData

struct SubjectStat: Identifiable {
    let id = UUID()
    let subjectName: String
    let sessionCount: Int
    let averageScore: Int
}

@Observable
final class ProgressViewModel {
    var totalSessions = 0
    var subjectStats: [SubjectStat] = []
    var recentSessions: [PracticeSession] = []

    func loadStats(context: ModelContext) {
        let descriptor = FetchDescriptor<PracticeSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sessions = try? context.fetch(descriptor) else { return }

        totalSessions = sessions.count
        recentSessions = Array(sessions.prefix(10))

        let grouped = Dictionary(grouping: sessions, by: \.subjectName)
        subjectStats = grouped.map { subject, sessions in
            let scores = sessions.map(\.scorePercentage)
            let avg = scores.isEmpty ? 0 : scores.reduce(0, +) / scores.count
            return SubjectStat(
                subjectName: subject,
                sessionCount: sessions.count,
                averageScore: avg
            )
        }.sorted { $0.sessionCount > $1.sessionCount }
    }
}
```

**Step 4: Run test to verify it passes**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests/ProgressViewModelTests 2>&1 | tail -20`
Expected: PASS — all 3 tests pass

**Step 5: Commit**

```bash
git add Reviso/ViewModels/ProgressViewModel.swift RevisoTests/ProgressViewModelTests.swift
git commit -m "feat: add ProgressViewModel with subject-grouped stats"
```

---

## Phase 4: Views

### Task 10: Add SubjectPicker Component

**Files:**
- Create: `Reviso/Views/Components/SubjectPicker.swift`

**Step 1: Create the component**

Create `Reviso/Views/Components/SubjectPicker.swift`:

```swift
import SwiftUI

struct SubjectPicker: View {
    @Binding var selectedSubject: String
    @Binding var selectedSubTopic: String?

    var body: some View {
        Picker("Subject", selection: $selectedSubject) {
            ForEach(SubjectData.subjectNames, id: \.self) { name in
                Text(name).tag(name)
            }
        }

        let subTopics = SubjectData.subTopics(for: selectedSubject)
        if !subTopics.isEmpty {
            Picker("Sub-topic", selection: Binding(
                get: { selectedSubTopic ?? subTopics[0] },
                set: { selectedSubTopic = $0 }
            )) {
                ForEach(subTopics, id: \.self) { topic in
                    Text(topic).tag(topic)
                }
            }
        }
    }
}
```

**Step 2: Commit**

```bash
git add Reviso/Views/Components/SubjectPicker.swift
git commit -m "feat: add SubjectPicker reusable component"
```

---

### Task 11: Update ScanView Save Sheet with SubjectPicker

**Files:**
- Modify: `Reviso/Views/Scan/ScanView.swift:142-168`

**Step 1: Update the save sheet**

In `Reviso/Views/Scan/ScanView.swift`:

Replace the `@State private var worksheetSubject = ""` property (line 18) with:
```swift
@State private var worksheetSubject = "General"
@State private var worksheetSubTopic: String?
```

Replace the `saveWorksheetSheet` computed property (lines 142-168) with:
```swift
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
                Button("Cancel") { showSaveSheet = false }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let name = worksheetName.isEmpty ? "Worksheet" : worksheetName
                    viewModel?.saveWorksheet(name: name, subject: worksheetSubject, context: modelContext)
                    if let vm = viewModel, let ws = fetchLatestWorksheet() {
                        ws.subTopicName = worksheetSubTopic
                        try? modelContext.save()
                    }
                    showSaveSheet = false
                    viewModel?.reset()
                    worksheetName = ""
                    worksheetSubject = "General"
                    worksheetSubTopic = nil
                }
            }
        }
    }
    .presentationDetents([.medium])
}

private func fetchLatestWorksheet() -> Worksheet? {
    var descriptor = FetchDescriptor<Worksheet>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
    descriptor.fetchLimit = 1
    return try? modelContext.fetch(descriptor).first
}
```

**Step 2: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Scan/ScanView.swift
git commit -m "feat: replace free-text subject field with SubjectPicker in save sheet"
```

---

### Task 12: Update QuestionGeneratorView with Difficulty Picker

**Files:**
- Modify: `Reviso/Views/Practice/QuestionGeneratorView.swift:59-95`

**Step 1: Update the setup view**

In `Reviso/Views/Practice/QuestionGeneratorView.swift`, replace the `setupView` computed property (lines 59-95) with:

```swift
private var setupView: some View {
    VStack(spacing: 20) {
        Spacer()

        Image(systemName: "sparkles")
            .font(.system(size: 60))
            .foregroundStyle(.tint)

        Text("Generate similar practice questions from this worksheet")
            .font(.headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

        if let viewModel {
            VStack(spacing: 16) {
                Stepper("Number of questions: \(viewModel.questionCount)",
                        value: Binding(
                            get: { viewModel.questionCount },
                            set: { viewModel.questionCount = $0 }
                        ),
                        in: 1...10)

                Picker("Difficulty", selection: Binding(
                    get: { viewModel.selectedDifficulty },
                    set: { viewModel.selectedDifficulty = $0 }
                )) {
                    ForEach(Difficulty.allCases, id: \.self) { difficulty in
                        Text(difficulty.displayName).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, 32)
        }

        Button {
            guard let viewModel else { return }
            Task { await generateQuestions(viewModel: viewModel) }
        } label: {
            Label("Generate Questions", systemImage: "sparkles")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding(.horizontal, 32)

        Spacer()
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Practice/QuestionGeneratorView.swift
git commit -m "feat: add difficulty picker to question generation setup"
```

---

### Task 13: Add GeneratedPracticeView for Saving and Viewing Practices

**Files:**
- Create: `Reviso/Views/Practice/GeneratedPracticeView.swift`
- Modify: `Reviso/Views/Practice/QuestionListView.swift` — add save button

**Step 1: Create GeneratedPracticeView**

Create `Reviso/Views/Practice/GeneratedPracticeView.swift`:

```swift
import SwiftUI
import SwiftData

struct GeneratedPracticeView: View {
    let practice: GeneratedPractice
    @Environment(\.dismiss) private var dismiss
    @State private var showAnswerKey = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    questionsSection
                    if showAnswerKey {
                        answerKeySection
                    }
                }
                .padding()
            }
            .navigationTitle("Practice Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation { showAnswerKey.toggle() }
                    } label: {
                        Label(
                            showAnswerKey ? "Hide Answers" : "Show Answers",
                            systemImage: showAnswerKey ? "eye.slash" : "eye"
                        )
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Label(practice.subjectName, systemImage: "book")
            Spacer()
            Text(practice.difficulty.displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.tint.opacity(0.1))
                .foregroundStyle(.tint)
                .cornerRadius(6)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var questionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Questions")
                .font(.headline)
            Text(practice.questionsText)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var answerKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Answer Key")
                .font(.headline)
                .foregroundStyle(.green)
            Text(practice.answerKeyText)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
```

**Step 2: Add save button to QuestionListView**

In `Reviso/Views/Practice/QuestionListView.swift`, add a new property and save action. Replace the entire file:

```swift
import SwiftUI
import SwiftData

struct QuestionListView: View {
    let viewModel: QuestionGeneratorViewModel
    let onRegenerate: () -> Void
    var onSavePractice: ((GeneratedPractice) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @State private var revealedAnswers: Set<Int> = []
    @State private var savedPractice: GeneratedPractice?
    @State private var showSaveSuccess = false

    var body: some View {
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        revealedAnswers.removeAll()
                        onRegenerate()
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                    if savedPractice == nil {
                        Button {
                            savePractice()
                        } label: {
                            Label("Save Practice", systemImage: "square.and.arrow.down")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Saved", isPresented: $showSaveSuccess) {
            Button("OK") {}
        } message: {
            Text("Practice questions saved. You can find them in the Practice tab.")
        }
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
            subjectName: "General",
            questionsText: questionsText,
            answerKeyText: answerKeyText,
            questionCount: questions.count
        )
        modelContext.insert(practice)
        try? modelContext.save()

        savedPractice = practice
        showSaveSuccess = true
        onSavePractice?(practice)
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Reviso/Views/Practice/GeneratedPracticeView.swift Reviso/Views/Practice/QuestionListView.swift
git commit -m "feat: add GeneratedPracticeView and save practice button"
```

---

### Task 14: Add ScoreEntryView and ScoreSummaryView

**Files:**
- Create: `Reviso/Views/Practice/ScoreEntryView.swift`
- Create: `Reviso/Views/Practice/ScoreSummaryView.swift`

**Step 1: Create ScoreEntryView**

Create `Reviso/Views/Practice/ScoreEntryView.swift`:

```swift
import SwiftUI
import SwiftData

struct ScoreEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PracticeViewModel
    let answerKeyText: String?
    let worksheet: Worksheet?
    let generatedPractice: GeneratedPractice?
    @State private var showAnswerKey = false
    @State private var showSummary = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showAnswerKey, let answerKeyText {
                    answerKeyBanner(answerKeyText)
                }

                List {
                    ForEach(1...viewModel.totalQuestions, id: \.self) { number in
                        questionRow(number: number)
                    }
                }

                submitBar
            }
            .navigationTitle("Score My Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if answerKeyText != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            withAnimation { showAnswerKey.toggle() }
                        } label: {
                            Label(
                                showAnswerKey ? "Hide Answers" : "Show Answers",
                                systemImage: showAnswerKey ? "eye.slash" : "eye"
                            )
                        }
                    }
                }
            }
            .sheet(isPresented: $showSummary) {
                ScoreSummaryView(
                    correctCount: viewModel.correctCount,
                    totalQuestions: viewModel.totalQuestions,
                    scorePercentage: viewModel.scorePercentage,
                    subjectName: viewModel.subjectName
                ) {
                    dismiss()
                }
            }
        }
    }

    private func answerKeyBanner(_ text: String) -> some View {
        ScrollView {
            Text(text)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 150)
        .background(.green.opacity(0.1))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func questionRow(number: Int) -> some View {
        HStack {
            Text("Q\(number)")
                .font(.headline)
                .frame(width: 40)

            Spacer()

            HStack(spacing: 12) {
                Button {
                    viewModel.markQuestion(number, isCorrect: true)
                } label: {
                    Image(systemName: viewModel.results[number - 1] == true
                          ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.results[number - 1] == true ? .green : .secondary)
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.markQuestion(number, isCorrect: false)
                } label: {
                    Image(systemName: viewModel.results[number - 1] == false
                          ? "xmark.circle.fill" : "xmark.circle")
                        .font(.title2)
                        .foregroundStyle(viewModel.results[number - 1] == false ? .red : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var submitBar: some View {
        VStack(spacing: 8) {
            let answered = viewModel.results.compactMap { $0 }.count
            Text("\(answered) of \(viewModel.totalQuestions) answered")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                viewModel.saveSession(
                    context: modelContext,
                    worksheet: worksheet,
                    generatedPractice: generatedPractice
                )
                showSummary = true
            } label: {
                Text("Submit Score")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.isComplete)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}
```

**Step 2: Create ScoreSummaryView**

Create `Reviso/Views/Practice/ScoreSummaryView.swift`:

```swift
import SwiftUI

struct ScoreSummaryView: View {
    let correctCount: Int
    let totalQuestions: Int
    let scorePercentage: Int
    let subjectName: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            scoreCircle

            Text("\(correctCount) out of \(totalQuestions) correct")
                .font(.title2)
                .fontWeight(.semibold)

            Text(encouragementText)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text(subjectName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.tint.opacity(0.1))
                .foregroundStyle(.tint)
                .cornerRadius(8)

            Spacer()

            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom)
        }
    }

    private var scoreCircle: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.2), lineWidth: 12)
            Circle()
                .trim(from: 0, to: Double(scorePercentage) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.8), value: scorePercentage)
            Text("\(scorePercentage)%")
                .font(.system(size: 36, weight: .bold))
        }
        .frame(width: 150, height: 150)
    }

    private var scoreColor: Color {
        switch scorePercentage {
        case 80...100: .green
        case 60..<80: .orange
        default: .red
        }
    }

    private var encouragementText: String {
        switch scorePercentage {
        case 90...100: "Excellent work! You've mastered this!"
        case 80..<90: "Great job! Almost perfect!"
        case 70..<80: "Good effort! Keep practicing!"
        case 60..<70: "Not bad! A bit more practice will help."
        default: "Keep going! Practice makes perfect."
        }
    }
}
```

**Step 3: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add Reviso/Views/Practice/ScoreEntryView.swift Reviso/Views/Practice/ScoreSummaryView.swift
git commit -m "feat: add ScoreEntryView and ScoreSummaryView for self-scoring"
```

---

### Task 15: Add Practice Tab with History and Progress Dashboard

**Files:**
- Create: `Reviso/Views/Practice/PracticeTabView.swift`

**Step 1: Create PracticeTabView**

Create `Reviso/Views/Practice/PracticeTabView.swift`:

```swift
import SwiftUI
import SwiftData

struct PracticeTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GeneratedPractice.date, order: .reverse) private var practices: [GeneratedPractice]
    @Query(sort: \PracticeSession.date, order: .reverse) private var sessions: [PracticeSession]
    @State private var progressVM = ProgressViewModel()
    @State private var selectedPractice: GeneratedPractice?
    @State private var showScoreEntry = false
    @State private var scoreEntryPractice: GeneratedPractice?

    var body: some View {
        NavigationStack {
            List {
                if !sessions.isEmpty {
                    progressSection
                }

                if !practices.isEmpty {
                    practicesSection
                }

                if practices.isEmpty && sessions.isEmpty {
                    ContentUnavailableView(
                        "No Practice Yet",
                        systemImage: "pencil.and.list.clipboard",
                        description: Text("Generate practice questions from a worksheet to get started.")
                    )
                }
            }
            .navigationTitle("Practice")
            .onAppear {
                progressVM.loadStats(context: modelContext)
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

    private var progressSection: some View {
        Section("Progress") {
            LabeledContent("Total Sessions", value: "\(progressVM.totalSessions)")

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
    }

    private var practicesSection: some View {
        Section("Generated Practices") {
            ForEach(practices) { practice in
                Button {
                    selectedPractice = practice
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(practice.subjectName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            HStack(spacing: 8) {
                                Text("\(practice.questionCount) questions")
                                Text(practice.difficulty.displayName)
                                    .font(.caption)
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
                }
            }
        }
    }
}
```

**Step 2: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/Views/Practice/PracticeTabView.swift
git commit -m "feat: add PracticeTabView with progress dashboard and practice history"
```

---

### Task 16: Add Practice Tab to ContentView

**Files:**
- Modify: `Reviso/ContentView.swift`

**Step 1: Add the Practice tab**

In `Reviso/ContentView.swift`, add a new tab between Home and Scan:

```swift
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
```

**Step 2: Build to verify**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add Reviso/ContentView.swift
git commit -m "feat: add Practice tab to main navigation"
```

---

## Phase 5: Integration & Final Verification

### Task 17: Run Full Test Suite

**Step 1: Run all tests**

Run: `xcodebuild test -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:RevisoTests 2>&1 | tail -30`
Expected: ALL TESTS PASS

**Step 2: Fix any failures**

If tests fail, investigate and fix. Common issues:
- In-memory `ModelContainer` needs all new model types registered
- Existing tests may need updated `makeContainer()` to include new models

**Step 3: Build the full app**

Run: `xcodebuild -workspace Reviso.xcworkspace -scheme Reviso -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -10`
Expected: BUILD SUCCEEDED

**Step 4: Commit any fixes**

```bash
git add -A
git commit -m "fix: resolve test and build issues from integration"
```

---

## File Summary

### New Files (13)
| File | Purpose |
|------|---------|
| `Reviso/Models/Difficulty.swift` | Difficulty enum (easy/medium/hard) |
| `Reviso/Models/SubjectData.swift` | Predefined subjects + sub-topics |
| `Reviso/Models/GeneratedPractice.swift` | SwiftData model for saved practices |
| `Reviso/Models/PracticeSession.swift` | SwiftData model for scoring sessions |
| `Reviso/Models/QuestionResult.swift` | SwiftData model for per-question results |
| `Reviso/ViewModels/PracticeViewModel.swift` | Self-scoring logic |
| `Reviso/ViewModels/ProgressViewModel.swift` | Dashboard stats |
| `Reviso/Views/Components/SubjectPicker.swift` | Reusable subject picker |
| `Reviso/Views/Practice/GeneratedPracticeView.swift` | View saved practice + answer key |
| `Reviso/Views/Practice/ScoreEntryView.swift` | Per-question marking UI |
| `Reviso/Views/Practice/ScoreSummaryView.swift` | Score result display |
| `Reviso/Views/Practice/PracticeTabView.swift` | Practice tab with history + progress |

### New Test Files (5)
| File | Purpose |
|------|---------|
| `RevisoTests/DifficultyTests.swift` | Difficulty enum tests |
| `RevisoTests/SubjectDataTests.swift` | Subject data tests |
| `RevisoTests/GeneratedPracticeTests.swift` | SwiftData model tests |
| `RevisoTests/PracticeSessionTests.swift` | Session + results tests |
| `RevisoTests/PracticeViewModelTests.swift` | Self-scoring VM tests |
| `RevisoTests/ProgressViewModelTests.swift` | Dashboard stats tests |

### Modified Files (6)
| File | Change |
|------|--------|
| `Reviso/RevisoApp.swift` | Register new models in schema |
| `Reviso/Models/Worksheet.swift` | Add `subTopicName` property |
| `Reviso/Services/AI/QuestionGenerator.swift` | Add difficulty parameter |
| `Reviso/ViewModels/QuestionGeneratorViewModel.swift` | Add `selectedDifficulty` |
| `Reviso/Views/Scan/ScanView.swift` | SubjectPicker in save sheet |
| `Reviso/Views/Practice/QuestionGeneratorView.swift` | Difficulty picker UI |
| `Reviso/Views/Practice/QuestionListView.swift` | Save practice button |
| `Reviso/ContentView.swift` | Add Practice tab |
