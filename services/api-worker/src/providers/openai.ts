import { Env, InternalRefineParams, ProviderResult } from '../types.js';
import { LLMProvider } from './types.js';
import { buildSystemPrompt, buildUserPrompt } from '../prompts/index.js';

export class OpenAIProvider implements LLMProvider {
  readonly name = 'openai';

  isConfigured(env: Env): boolean {
    return Boolean(env.OPENAI_API_KEY && env.OPENAI_API_KEY.trim().length > 0);
  }

  async refine(params: InternalRefineParams, env: Env): Promise<ProviderResult> {
    const apiKey = env.OPENAI_API_KEY;
    if (!apiKey) {
      throw new Error('OPENAI_API_KEY is not configured in environment secrets');
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

    let temperature = 0.3;
    if (params.synonymLevel !== undefined) {
      const tempMap = [0.1, 0.15, 0.25, 0.45, 0.7];
      temperature = tempMap[params.synonymLevel] ?? 0.3;
    }

    const model = 'gpt-4o-mini';
    const url = 'https://api.openai.com/v1/chat/completions';

    const payload = {
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature,
      max_tokens: 4096,
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      const errText = await response.text();
      throw new Error(`OpenAI API error (${response.status}): ${errText}`);
    }

    const data: any = await response.json();
    let content = data.choices?.[0]?.message?.content;

    if (!content) {
      throw new Error('OpenAI returned an empty or invalid completion');
    }

    content = content.trim();
    if (content.startsWith('```') && content.endsWith('```')) {
      content = content.replace(/^```[a-z]*\n?/, '').replace(/\n?```$/, '').trim();
    }

    if (content.startsWith('{') && content.endsWith('}')) {
      try {
        const parsed = JSON.parse(content);
        return {
          refinedText: parsed.refinedText || content,
          provider: 'OpenAI',
          model,
          alternatives: parsed.alternatives,
          issues: parsed.issues,
        };
      } catch {
        // fallback to plain content
      }
    }

    return {
      refinedText: content,
      provider: 'OpenAI',
      model,
    };
  }
}
