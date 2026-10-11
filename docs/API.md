# SAYN — Cloudflare Worker API Reference

## Base URL
- Production: `https://api.sayn.app/api/v1` (or your Cloudflare Worker route)
- Local Dev: `http://localhost:8787/api/v1`

---

## 1. Health Check
`GET /api/v1/health`

### Response (200 OK)
```json
{
  "status": "ok",
  "version": "1.0.0",
  "aiProviderConfigured": true,
  "activeProvider": "gemini",
  "timestamp": "2026-10-11T13:00:00.000Z"
}
```

---

## 2. Refine Text
`POST /api/v1/ai/refine`

### Headers
- `Content-Type: application/json`
- `Authorization: Bearer <supabase_jwt_token>`

### Request Body
```json
{
  "text": "hey so basically i checked the sprint tasks and design system stuff is pretty much done by thursday probably",
  "mode": "professional",
  "tone": "confident",
  "targetLanguage": "Spanish",
  "customInstruction": "Optional custom prompt"
}
```

### Response (200 OK)
```json
{
  "success": true,
  "refinedText": "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday.",
  "mode": "professional",
  "tone": "confident",
  "stats": {
    "originalWords": 18,
    "originalChars": 105,
    "refinedWords": 17,
    "refinedChars": 121,
    "latencyMs": 420
  },
  "provider": "Google Gemini",
  "model": "gemini-2.5-flash"
}
```

---

## 3. Speech Transcription
`POST /api/v1/ai/transcribe`

Supports `multipart/form-data` with `file` audio blob or `application/json` with `audioBase64`. Converts voice directly using OpenAI Whisper or Cloudflare Workers AI Whisper.
