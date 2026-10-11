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
      params.customInstruction
    );
    const userPrompt = buildUserPrompt(params.text);

    const model = 'gpt-4o-mini';
    const url = 'https://api.openai.com/v1/chat/completions';

    const payload = {
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt },
      ],
      temperature: 0.3,
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
    const content = data.choices?.[0]?.message?.content;

    if (!content) {
      throw new Error('OpenAI returned an empty or invalid completion');
    }

    return {
      refinedText: content.trim(),
      provider: 'OpenAI',
      model,
    };
  }
}
