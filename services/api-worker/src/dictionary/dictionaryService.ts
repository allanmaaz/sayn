import { DictionaryDefineRequest, DictionaryDefineResponse, WordSense } from '@sayn/shared-types';
import { Env } from '../types.js';

// In-worker in-memory cache (persists across warm worker requests)
const memoryCache = new Map<string, { data: DictionaryDefineResponse; timestamp: number }>();
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

export async function lookupWordDefinition(
  req: DictionaryDefineRequest,
  env: Env
): Promise<DictionaryDefineResponse> {
  const startTime = Date.now();
  const rawWord = req.word.trim();
  const cleanWord = rawWord.toLowerCase().replace(/^[^\w]+|[^\w]+$/g, '');

  if (!cleanWord) {
    return {
      success: false,
      word: rawWord,
      senses: [],
      source: 'dictionary_api',
      latencyMs: Date.now() - startTime,
    };
  }

  const cacheKey = `${cleanWord}:${req.contextSentence ? req.contextSentence.slice(0, 50) : ''}`;
  const cached = memoryCache.get(cacheKey);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL_MS) {
    return {
      ...cached.data,
      source: 'cache',
      latencyMs: Date.now() - startTime,
    };
  }

  // 1. Try Free Dictionary API
  try {
    const dictApiUrl = `https://api.dictionaryapi.dev/api/v2/entries/en/${encodeURIComponent(cleanWord)}`;
    const res = await fetch(dictApiUrl, {
      headers: { 'Accept': 'application/json' },
    });

    if (res.ok) {
      const data: any = await res.json();
      if (Array.isArray(data) && data.length > 0) {
        const entry = data[0];
        const phonetic = entry.phonetic || entry.phonetics?.find((p: any) => p.text)?.text || '';
        
        // Find best audio URL (prefer .mp3)
        let audioUrl = '';
        if (entry.phonetics && Array.isArray(entry.phonetics)) {
          for (const p of entry.phonetics) {
            if (p.audio && typeof p.audio === 'string' && p.audio.trim().length > 0) {
              audioUrl = p.audio.startsWith('//') ? `https:${p.audio}` : p.audio;
              break;
            }
          }
        }

        const senses: WordSense[] = [];
        if (entry.meanings && Array.isArray(entry.meanings)) {
          for (const m of entry.meanings) {
            const pos = m.partOfSpeech || 'unknown';
            if (m.definitions && Array.isArray(m.definitions)) {
              for (const d of m.definitions) {
                senses.push({
                  partOfSpeech: pos,
                  definition: d.definition || '',
                  example: d.example || undefined,
                  synonyms: d.synonyms?.length ? d.synonyms.slice(0, 6) : undefined,
                  antonyms: d.antonyms?.length ? d.antonyms.slice(0, 6) : undefined,
                });
              }
            }
          }
        }

        let contextualNuance: string | undefined;
        // If context sentence was provided and senses exist, try to provide nuance
        if (req.contextSentence && senses.length > 0 && env.GEMINI_API_KEY) {
          try {
            contextualNuance = await getContextualNuance(cleanWord, req.contextSentence, senses, env);
          } catch {
            // Non-critical: continue without nuance
          }
        }

        const result: DictionaryDefineResponse = {
          success: true,
          word: entry.word || cleanWord,
          phonetic: phonetic || undefined,
          audioUrl: audioUrl || undefined,
          senses: senses.slice(0, 8),
          etymology: entry.origin || undefined,
          contextualNuance,
          source: 'dictionary_api',
          latencyMs: Date.now() - startTime,
        };

        memoryCache.set(cacheKey, { data: result, timestamp: Date.now() });
        return result;
      }
    }
  } catch (err) {
    // Dictionary API failed or timed out, fall through to Gemini
  }

  // 2. Fallback to Gemini AI Dictionary Engine
  if (env.GEMINI_API_KEY) {
    try {
      const geminiResult = await getGeminiDefinition(cleanWord, req.contextSentence, env);
      if (geminiResult && geminiResult.senses && geminiResult.senses.length > 0) {
        const result: DictionaryDefineResponse = {
          success: true,
          word: geminiResult.word || cleanWord,
          phonetic: geminiResult.phonetic,
          audioUrl: undefined,
          senses: geminiResult.senses,
          etymology: geminiResult.etymology,
          contextualNuance: geminiResult.contextualNuance,
          source: 'gemini_fallback',
          latencyMs: Date.now() - startTime,
        };

        memoryCache.set(cacheKey, { data: result, timestamp: Date.now() });
        return result;
      }
    } catch {
      // Fallback failed
    }
  }

  // If both failed, return minimal response
  return {
    success: false,
    word: cleanWord,
    senses: [],
    source: 'dictionary_api',
    latencyMs: Date.now() - startTime,
  };
}

async function getContextualNuance(
  word: string,
  contextSentence: string,
  senses: WordSense[],
  env: Env
): Promise<string | undefined> {
  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) return undefined;

  const candidateModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];
  const prompt = `In the sentence: "${contextSentence}"\nThe user selected the word: "${word}".\nBriefly explain in 1 concise sentence how "${word}" functions here and which nuance or tone it carries. Do NOT use markdown.`;

  for (const model of candidateModels) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ role: 'user', parts: [{ text: prompt }] }],
          generationConfig: { temperature: 0.2, maxOutputTokens: 100 },
        }),
      });

      if (res.ok) {
        const data: any = await res.json();
        const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (text && text.trim().length > 0) {
          return text.trim();
        }
      }
    } catch {
      continue;
    }
  }
  return undefined;
}

async function getGeminiDefinition(
  word: string,
  contextSentence: string | undefined,
  env: Env
): Promise<Partial<DictionaryDefineResponse> | null> {
  const apiKey = env.GEMINI_API_KEY;
  if (!apiKey) return null;

  const candidateModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];
  const systemInstruction = `You are a professional lexicographical dictionary engine. Provide accurate dictionary definitions, phonetic transcription (IPA), parts of speech, synonyms, antonyms, and usage examples for the requested word.
Respond ONLY with a valid raw JSON object matching this schema (no markdown backticks, no markdown headers):
{
  "word": "canonical word form",
  "phonetic": "/IPA/",
  "etymology": "Brief origin note or null",
  "contextualNuance": "Brief 1-sentence note if context was given, else null",
  "senses": [
    {
      "partOfSpeech": "noun | verb | adjective | adverb | etc",
      "definition": "Clear, precise definition",
      "example": "Natural example sentence",
      "synonyms": ["syn1", "syn2"],
      "antonyms": ["ant1"]
    }
  ]
}`;

  const userPrompt = contextSentence
    ? `Define the word "${word}" as used in this context: "${contextSentence}".`
    : `Define the word "${word}".`;

  for (const model of candidateModels) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemInstruction }] },
          contents: [{ role: 'user', parts: [{ text: userPrompt }] }],
          generationConfig: { temperature: 0.1, maxOutputTokens: 1024 },
        }),
      });

      if (res.ok) {
        const data: any = await res.json();
        const candidateText = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (candidateText) {
          let cleaned = candidateText.trim();
          if (cleaned.startsWith('```') && cleaned.endsWith('```')) {
            cleaned = cleaned.replace(/^```[a-z]*\n?/, '').replace(/\n?```$/, '').trim();
          }
          if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
            return JSON.parse(cleaned);
          }
        }
      }
    } catch {
      continue;
    }
  }

  return null;
}
