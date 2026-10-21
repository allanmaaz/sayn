import { Env, InternalRefineParams, ProviderResult } from '../types.js';
import { LLMProvider } from './types.js';
import { buildSystemPrompt, buildUserPrompt } from '../prompts/index.js';

export class GeminiProvider implements LLMProvider {
  readonly name = 'gemini';

  isConfigured(env: Env): boolean {
    return Boolean(env.GEMINI_API_KEY && env.GEMINI_API_KEY.trim().length > 0);
  }

  async refine(params: InternalRefineParams, env: Env): Promise<ProviderResult> {
    const apiKey = env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured in environment secrets');
    }

    const systemPrompt = buildSystemPrompt(
      params.mode,
      params.tone,
      params.targetLanguage,
      params.customInstruction,
      params.angle,
      params.synonymLevel,
      params.freezeWords,
      params.includeAlternatives,
      params.includeGrammarIssues
    );
    const userPrompt = buildUserPrompt(params.text);

    let temperature = 0.2;
    if (params.synonymLevel !== undefined) {
      const tempMap = [0.1, 0.15, 0.25, 0.45, 0.7];
      temperature = tempMap[params.synonymLevel] ?? 0.2;
    }

    const candidateModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];
    let lastError = '';

    for (const model of candidateModels) {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

      const payload = {
        systemInstruction: {
          parts: [{ text: systemPrompt }],
        },
        contents: [
          {
            role: 'user',
            parts: [{ text: userPrompt }],
          },
        ],
        generationConfig: {
          temperature,
          maxOutputTokens: 4096,
        },
      };

      try {
        const response = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });

        if (!response.ok) {
          const errText = await response.text();
          lastError = `Gemini API error (${response.status}): ${errText}`;
          // If 503 high demand or 429 rate limit, try next model
          if (response.status === 503 || response.status === 429) {
            continue;
          }
          throw new Error(lastError);
        }

        const data: any = await response.json();
        const candidate = data.candidates?.[0];
        const textPart = candidate?.content?.parts?.[0]?.text;

        if (textPart && textPart.trim().length > 0) {
          // Clean any markdown backticks or quotes wrapping the response
          let cleaned = textPart.trim();
          if (cleaned.startsWith('```') && cleaned.endsWith('```')) {
            cleaned = cleaned.replace(/^```[a-z]*\n?/, '').replace(/\n?```$/, '').trim();
          }

          // If structured JSON was requested, parse it
          if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
            try {
              const parsed = JSON.parse(cleaned);
              return {
                refinedText: parsed.refinedText || cleaned,
                provider: 'Google Gemini',
                model,
                alternatives: parsed.alternatives,
                issues: parsed.issues,
              };
            } catch {
              // fallback to plain cleaned text if JSON parsing fails
            }
          }

          return {
            refinedText: cleaned,
            provider: 'Google Gemini',
            model,
          };
        }
      } catch (err: any) {
        lastError = err.message;
      }
    }

    throw new Error(lastError || 'Gemini returned an empty response across all candidate models.');
  }
}
