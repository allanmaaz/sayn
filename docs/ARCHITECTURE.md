# SAYN — System Architecture Documentation

**Tagline:** Say it. Refine it. Send it.  
**Platforms:** Web (React + TS + Vite), Android (Flutter + Native Kotlin), Backend (Cloudflare Worker), Database (Supabase PostgreSQL + RLS)

---

## 1. System Overview

SAYN is an AI-powered communication assistant that brings voice-to-text, 12+ AI writing transformations, and cross-application assistance together in an Apple-inspired minimal interface.

```text
┌────────────────────────────────────────────────────────┐
│                   CLIENT APPLICATIONS                   │
├─────────────────────┬──────────────────────────────────┤
│ SAYN Web (React/TS) │ SAYN Android (Flutter + Kotlin) │
│ - Writing Workspace │ - System Overlay (Bubble/Panel)  │
│ - Voice Studio      │ - Smart Keyboard (IME)           │
│ - History & Prompts │ - Native Audio & Settings        │
└──────────┬──────────┴────────────────┬─────────────────┘
           │                           │
           │ JWT Sessions              │ JWT Sessions
           ▼                           ▼
┌────────────────────────────────────────────────────────┐
│               SUPABASE AUTH & DATABASE                 │
│ - PostgreSQL with strict Row Level Security (RLS)      │
│ - Profiles, Preferences, History, Prompts, Usage       │
└────────────────────────────────────────────────────────┘
           │                           │
           │ Authenticated Requests    │ Authenticated Requests
           ▼                           ▼
┌────────────────────────────────────────────────────────┐
│         CLOUDFLARE WORKER AI GATEWAY (/api/v1)         │
│ - Request Validation (Zod)                             │
│ - JWT Verification                                     │
│ - Provider Abstraction & Dynamic Routing               │
│ - Rate Limiting & Health Checks                        │
└──────────────────────────┬─────────────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│     LLM PROVIDERS     │       │   SPEECH PROVIDERS    │
│ - Google Gemini       │       │ - OpenAI Whisper      │
│ - OpenAI (GPT-4o)     │       │ - Cloudflare Whisper  │
│ - Groq (Llama 3.3)    │       │ - Web Speech API      │
│ - CF Workers AI       │       │ - Android Recognizer  │
└───────────────────────┘       └───────────────────────┘
```

---

## 2. Component Directory Architecture

- **`apps/web/`**: Vite + React 18 + TypeScript + Tailwind CSS application. Features the public landing page, interactive workspace, voice studio modal, history viewer, and settings.
- **`apps/android/`**: Flutter mobile application with Riverpod & GoRouter, hosting native Kotlin services for the floating assistant and IME.
- **`services/api-worker/`**: Cloudflare Worker TypeScript project exposing `/api/v1/health`, `/api/v1/ai/refine`, `/grammar`, `/paraphrase`, `/summarize`, `/translate`, and `/transcribe`.
- **`packages/shared-types/`**: Shared TypeScript contracts (writing modes, request/response models, database schemas).
- **`supabase/migrations/`**: SQL migrations establishing tables, triggers, and RLS policies.
