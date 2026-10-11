# SAYN — Android AI Keyboard (IME) Specification

**Feature:** AI Writing Keyboard  
**Platform:** Android (`InputMethodService`)  
**Design Reference:** QuillBot keyboard writing tools  
**Tagline:** Say it. Refine it. Send it.

---

## 1. Overview
The SAYN Smart Keyboard is a native Android Input Method Editor (IME) written in Kotlin (`SaynInputMethodService.kt`). It provides ordinary keyboard typing combined with one-tap AI writing refinement, writing style selection, and dedicated suggestions directly above the keyboard keys.

---

## 2. Four Functional Keyboard Areas

### A. Input Area
- Standard QWERTY layout with lowercase, uppercase, and caps lock support.
- Numbers & symbols layout (`?123` and `ABC` toggles).
- Shift, Space, and Backspace (`DEL`) keys.
- Enter key respecting `EditorInfo.imeOptions` (Search, Send, Done, Go, Next, or Return).
- Keyboard switcher key (`GLOBE`) to return to the user's previous system keyboard via `switchToPreviousInputMethod()`.

### B. SAYN Toolbar
Positioned immediately above the keyboard rows:
- **In-Keyboard Dictation (`Voice`):** Uses Android `SpeechRecognizer` to capture speech directly into the active text field.
- **Writing-Style Selector (QuillBot style):** Horizontal scrollable pill row displaying:
  - **Standard:** Correct grammar and readability with minimal changes.
  - **Fluent:** Improve flow, clarity, rhythm, and sentence structure.
  - **Natural:** Conversational, human phrasing without robotic tone.
  - **Professional:** Clear, polished, workplace-appropriate communication.
  - **Casual:** Relaxed, friendly everyday language.
  - **Shorten:** Condense and cut filler while preserving key facts.
  - **Expand:** Thoughtfully elaborate without inventing facts.
  - **Formal:** High grammatical formality and precision.
  - **Custom:** User-defined instruction.
- **Loading State:** Clear progress feedback while processing, disabling duplicate requests.

### C. Dedicated AI Suggestion Area
Appears above the keyboard when a refinement completes:
- Proposal text with mode badge (e.g. `[PROFESSIONAL SUGGESTION]`).
- **Replace:** Replaces the selected text or current draft range, saving the previous text for **Undo**.
- **Insert:** Inserts the refined text at the cursor position.
- **Copy:** Copies the suggestion to the clipboard.
- **Regen:** Requests a fresh alternative with the same mode.
- **Dismiss (`✕`):** Dismisses the suggestion panel and resumes ordinary typing.
- **Undo:** Appears after Replace or Insert to restore the original draft if the user wants to revert.

### D. Sensitive Field Guard
- Inspects `EditorInfo.inputType`.
- Detects password variations (`TYPE_TEXT_VARIATION_PASSWORD`, `TYPE_TEXT_VARIATION_VISIBLE_PASSWORD`, `TYPE_TEXT_VARIATION_WEB_PASSWORD`, and PIN numbers).
- **Guarantees:**
  - Hides the AI toolbar and suggestion area on sensitive fields.
  - Zero keystroke logging. Text is processed only upon explicit user tap on an AI mode pill.

---

## 3. Shared State Synchronization
- Default writing mode and custom instructions are persisted in `SharedPreferences("com.sayn.app.PREFS")`.
- Synchronized between the Flutter app settings, the native keyboard, and the floating overlay.
