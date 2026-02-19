# Smart Practice Hub — Design Document

**Date:** 2026-02-20
**Status:** Approved

## Overview

Evolve Reviso from a worksheet eraser into a Smart Practice Hub that generates unlimited practice material with answer keys, supports self-scoring, and tracks student progress by subject.

**Target users:** Students ages 6-18 and their parents/teachers.

## Current State

Reviso has two features:
1. **Answer Eraser** — Scan worksheet, AI removes handwriting, student prints clean copy to redo
2. **AI Question Generator** — OCR worksheet, AI generates similar questions to print and practice

## New Features (V1)

### 1. Answer Key Generation

AI generates questions AND answer keys in a single prompt. The app parses and stores them separately.

**How it works:**
- Prompt includes the student's chosen difficulty level (easy/medium/hard)
- Prompt requests answers inline using a `---ANSWER---` separator
- App splits the AI response into questions text and answer key text
- Stored as a `GeneratedPractice` entity in SwiftData

**Difficulty mapping in prompt:**
- Easy: Simplify concepts, smaller numbers, more hints
- Medium: Same level as the original worksheet
- Hard: Increase complexity, multi-step problems, less guidance

**Display:**
- "Questions" view — shows only questions (printable/shareable)
- "Answer Key" view — hidden by default, tap to reveal

### 2. Self-Scoring Flow

After students complete practice on paper, they record results in the app.

**Flow:**
1. Student opens the practice session in the app
2. Taps "Score My Answers"
3. Sees a list of question numbers (Q1, Q2, Q3...)
4. Can reveal the answer key alongside
5. Taps each question to mark correct or incorrect
6. Submits and sees summary: "7/10 correct"
7. Results saved as `PracticeSession` + `QuestionResult` entries

### 3. Preset Subject System

Curated subject list for categorizing worksheets and tracking progress by topic.

| Subject | Sub-topics |
|---------|-----------|
| Math | Arithmetic, Fractions, Algebra, Geometry, Statistics |
| English | Grammar, Vocabulary, Comprehension, Writing |
| Science | Physics, Chemistry, Biology, General Science |
| Chinese | Reading, Writing, Vocabulary, Grammar |
| History | World History, Local History |
| Geography | Physical, Human |
| General | Other, Mixed |

- Assigned when importing a worksheet or generating questions
- Optional — worksheets can exist without a subject tag

### 4. Progress Tracking

Basic stats on the home screen:
- Total practice sessions completed
- Recent scores by subject
- Simple bar chart or list showing scores over time per subject

### 5. Print-Friendly Output (Nice to Have)

- Questions and answer keys displayed cleanly in the app for sharing/screenshotting
- QR codes and PDF generation deferred to V2

## Data Model

### New SwiftData Models

**`Subject`**
- `id: UUID`
- `name: String` (e.g., "Math")
- `subTopics: [String]` (e.g., ["Fractions", "Algebra", "Geometry"])
- Predefined list seeded on first launch

**`PracticeSession`**
- `id: UUID`
- `date: Date`
- `worksheet: Worksheet?` (relationship to existing model)
- `generatedPractice: GeneratedPractice?` (relationship)
- `difficulty: Difficulty` (enum: easy/medium/hard)
- `subjectName: String`
- `subTopicName: String?`
- `questionResults: [QuestionResult]` (relationship)
- `totalQuestions: Int` (computed)
- `correctCount: Int` (computed)

**`QuestionResult`**
- `id: UUID`
- `questionNumber: Int`
- `isCorrect: Bool`
- `session: PracticeSession` (relationship)

**`GeneratedPractice`**
- `id: UUID`
- `date: Date`
- `sourceWorksheet: Worksheet?` (relationship)
- `difficulty: Difficulty`
- `subjectName: String`
- `subTopicName: String?`
- `questionsText: String` (questions for the student)
- `answerKeyText: String` (answers, shown separately)

### Modifications to Existing Models

**`Worksheet`** — add optional `subjectName: String?` and `subTopicName: String?`

## Technical Approach

- **Answer key generation:** Single AI prompt returning questions + answers with separator. App parses the response. Same AI providers already supported (Claude, OpenAI, Gemini, Poe).
- **Progress data:** SwiftData models with relationships to existing `Worksheet` entity. Consistent with current architecture.
- **Subject system:** Predefined list, not user-editable in V1. Stored as a simple data structure.
- **Gamification:** Minimal in V1 — practice count and basic stats only. Full gamification (streaks, badges) deferred to V2.

## New UI Screens

1. **Subject Picker** — shown when importing a worksheet or generating questions
2. **Difficulty Picker** — easy/medium/hard selection before generating questions
3. **Generated Practice View** — questions display with hidden answer key
4. **Score Entry View** — list of question numbers with correct/incorrect toggles + answer key reveal
5. **Score Summary View** — result display with encouragement text
6. **Progress Dashboard** — home screen section showing stats by subject

## Out of Scope (V2)

- QR codes on printed worksheets
- PDF generation for printing
- Spaced repetition scheduling
- Full gamification (streaks, badges, levels)
- Parent/teacher dashboard
- Adaptive difficulty
- AI auto-detection of subject/difficulty
