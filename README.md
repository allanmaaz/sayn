# SAYN — Say it. Refine it. Send it.

**SAYN** is an AI-powered communication assistant combining voice dictation, smart writing refinement, and a system-wide floating assistant in an Apple-inspired visual design.

---

## Features

- **Voice to Text:** Natural speech dictation with automatic punctuation and formatting.
- **AI Writing Workspace:** 12 refinement modes (Grammar Fix, Paraphrase, Professional, Casual, Concise, Expand, Summarize, Improve Clarity, Friendly, Confident, Academic, Translate) plus Custom Prompts.
- **Diff Comparison:** Word-level visual comparison between original source text and refined output.
- **Apple-Inspired Aesthetics:** Minimalist design system with centralized tokens. Zero emoji icons (using Lucide icons exclusively) and zero purple gradients.
- **Android System Overlay:** Native Kotlin `FloatingBubbleService` (`TYPE_APPLICATION_OVERLAY`) running above WhatsApp, Gmail, Slack, and browsers.
- **Android Smart Keyboard:** Native Kotlin `SaynInputMethodService` (IME) with direct in-app text transformations and sensitive password field protection.
- **Provider-Independent AI Gateway:** Cloudflare Worker backend supporting Google Gemini, OpenAI, Groq, and Cloudflare Workers AI with fallback handling.
- **Supabase PostgreSQL & Auth:** Full schema with Row Level Security (RLS) policies for user data isolation.

---

## Monorepo Architecture

```text
SAYN/
├── apps/
│   ├── web/               # React 18 + TypeScript + Vite + Tailwind CSS
│   └── android/           # Flutter app + Native Kotlin Overlay & IME services
├── services/
│   └── api-worker/        # Cloudflare Worker AI Gateway (TypeScript + Wrangler)
├── packages/
│   └── shared-types/      # Shared models, schemas, and writing modes
├── supabase/
│   └── migrations/        # PostgreSQL schema & RLS security policies
└── docs/                  # Architecture, Design System, Overlay & API specifications
```

---

## Getting Started

### 1. Prerequisites
- Node.js 18+ (tested with v24.11.0)
- npm 9+
- Java 17+ (for Android builds)

### 2. Install Dependencies
```bash
npm install
```

### 3. Run the Cloudflare Worker API Gateway
```bash
npm run dev:worker
```
The API Gateway starts on `http://localhost:8787`.

### 4. Run the Web Application
```bash
npm run dev:web
```
The React workspace starts on `http://localhost:5173`.

### 5. Run Worker Unit Tests
```bash
npm run test:worker
```

### 6. Build Web for Production
```bash
npm run build:web
```

---

## Environment Variables

### Web (`apps/web/.env`)
```ini
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
VITE_API_GATEWAY_URL=http://localhost:8787
```

### Cloudflare Worker (`services/api-worker/wrangler.toml` & Secrets)
Set your AI provider key using Wrangler secrets:
```bash
npx wrangler secret put GEMINI_API_KEY
# or
npx wrangler secret put OPENAI_API_KEY
# or
npx wrangler secret put GROQ_API_KEY
```

---

## Design System Rules
- **No Emoji Icons:** Lucide vector icons only.
- **No Purple Palette:** Strictly neutral dark (`#0B0B0D`) / light (`#F5F5F7`) with Apple system blue (`#0A84FF`) accents. Cyan (`#5DE4FF`) is reserved strictly for sound wave activity.
