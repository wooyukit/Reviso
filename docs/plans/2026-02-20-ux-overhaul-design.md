# UX Overhaul — Design Document

**Date:** 2026-02-20
**Status:** Approved

## Overview

Restructure Reviso's navigation and flow to create a continuous, intuitive user journey. The current 4-tab layout fragments the core workflow (Scan → Erase → Generate → Print → Score) across disconnected screens with dead-end states. This overhaul streamlines tabs, adds flow continuations, fixes dead-ends, and introduces first-launch onboarding.

**Approach:** Streamlined Tabs + Flow Continuations (Approach B)

## Problems Being Solved

1. **Disconnected workflow:** After saving a worksheet, users must navigate Home → tap worksheet → tap "Generate" — fragmented
2. **Dead-end screens:** Scan tab shows "Poe API Key Required" with no way forward; Question generator shows "AI Provider Not Configured" with a dismiss-only button
3. **No onboarding:** New users land on an empty Home tab with no guidance
4. **Fragmented tabs:** Home and Practice tabs serve overlapping purposes, increasing cognitive load
5. **Missing flow continuations:** No "next step" prompts after completing an action

## Changes

### 1. Tab Structure

**Current (4 tabs):** Home | Practice | Scan | Settings
**New (3 tabs):** Worksheets | Scan | Settings

The **Worksheets** tab merges Home (worksheet grid) + Practice (generated practices, scoring, progress) into one screen with sections:

- **Top:** Worksheet grid (same 2-column layout as current Home)
- **Middle:** Recent Practice list (generated practices with Score buttons)
- **Bottom:** Progress summary (session count, per-subject averages)

### 2. First-Launch Onboarding

When `UserDefaults.hasCompletedOnboarding == false`, show a full-screen sheet before the main app:

- **Page 1:** Welcome — app description, icon
- **Page 2:** Poe API Key — explanation + SecureField + Save + Skip
- **Page 3:** AI Provider — provider picker + SecureField + Save + Skip
- **Page 4:** Confirmation — "You're all set!" → dismiss to main app

Skipping keys allows the app to open. Affected features show inline banners with "Set Up" buttons instead of dead-end screens.

### 3. Flow Continuations

**After Scan + Erase → Result screen:**
- **"Save & Generate Questions"** (primary button) — saves worksheet, immediately opens QuestionGeneratorView
- **"Save to Library"** (secondary button) — saves and returns to Worksheets tab
- **"Retry"** (tertiary) — reset and scan again

**After Generating Questions → Question List:**
- **"Share / Print"** — share sheet for questions
- **"Save & Score Later"** — saves GeneratedPractice, returns to Worksheets tab (practice appears in Recent Practice section)
- **"Show Answer Key"** — toggle to reveal answers

### 4. Dead-End Fixes

**Scan tab without Poe key:**
- Replace ContentUnavailableView with: same message + "Set Up API Key" button that programmatically switches to Settings tab via shared `TabSelection` state

**Question generator without AI provider:**
- Replace dismiss-only button with: "Go to Settings" button that dismisses the sheet AND switches to Settings tab

**Implementation:** Shared `@Observable` class or `@State` in ContentView for tab selection, passed via `@Environment` or `@Binding`.

### 5. Enhanced Worksheet Detail

Worksheet detail becomes the hub for each worksheet's journey. Actions shown are contextual:

- **No practice exists:** "Generate Practice Questions" button
- **Practice exists, not scored:** "View Practice" + "Score My Answers" buttons
- **Practice scored:** "View Practice" + "View Score: 8/10 (80%)" + "Score Again" buttons
- Always: "Share Worksheet" button

### 6. Files Affected

**New files:**
- `OnboardingView.swift` — first-launch onboarding flow (4 pages)
- `WorksheetsTabView.swift` — merged Worksheets + Practice + Progress tab

**Modified files:**
- `ContentView.swift` — 3 tabs, shared tab selection state
- `ScanView.swift` — "Save & Generate" flow continuation after erase
- `WorksheetDetailView.swift` — contextual actions based on worksheet/practice state
- `QuestionListView.swift` — "Save & Score Later" flow continuation
- `QuestionGeneratorView.swift` — fix dead-end with tab navigation
- `PracticeTabView.swift` — content extracted into WorksheetsTabView (may be deleted or repurposed)
- `HomeView.swift` — content extracted into WorksheetsTabView (may be deleted or repurposed)
- `RevisoApp.swift` — onboarding check on launch

## Out of Scope

- Visual styling (colors, fonts, spacing) — deferred to separate pass
- Animations and transitions — keep SwiftUI defaults
- iPad/landscape layout — iOS phone only for now
