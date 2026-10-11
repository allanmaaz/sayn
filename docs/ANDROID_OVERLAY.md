# SAYN — Android Floating Voice Assistant Specification

**Feature:** Floating Voice Assistant  
**Platform:** Android (`WindowManager` System Overlay)  
**Design Reference:** Wispr Flow floating dictation  
**Tagline:** Say it. Refine it. Send it.

---

## 1. Overview
The SAYN Floating Assistant is a native Android system overlay (`FloatingBubbleService.kt` and `FloatingPanelView.kt`). It provides a draggable, system-wide microphone bubble that enables voice dictation and writing refinement over WhatsApp, Instagram, Telegram, Gmail, Messages, and browsers.

---

## 2. Five Operational States

### 1. Idle State
- Compact 56dp circular microphone bubble (`#151518` surface, `#303036` border, `#5DE4FF` cyan mic icon).
- Draggable across screen bounds with smooth decelerated edge-snapping on release.
- Remembers user's preferred position in `SharedPreferences`.
- Zero active audio capture in idle state.

### 2. Recording State
- Tapping bubble opens compact recording panel.
- Records speech via Android `SpeechRecognizer`.
- Displays real-time cyan waveform bars modulated by speech volume.
- Displays elapsed duration timer (`00:15`).
- Visible Stop & Cancel controls.

### 3. Transcription State
- Converts speech into punctuated text.
- Handles silence, mic errors, and preserves transcript for user recovery.

### 4. Refinement State
- Original transcript preview.
- Writing-style selector (Standard, Fluent, Natural, Professional, Casual, Shorten, Expand, Formal, Custom).
- Refined result presentation.
- One-tap style switching automatically regenerates refinement.

### 5. Completion State
- **Insert / Share:** Shares directly into the active host app or copies to clipboard with toast notification.
- **Copy:** Copies to clipboard.
- User retains full control: never automatically sends messages or submits forms.
