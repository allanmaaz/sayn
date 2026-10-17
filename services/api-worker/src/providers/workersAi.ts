import { Env, InternalRefineParams, ProviderResult } from '../types.js';
import { LLMProvider } from './types.js';
import { buildSystemPrompt, buildUserPrompt } from '../prompts/index.js';

export class WorkersAIProvider implements LLMProvider {
  readonly name = 'workers-ai';

  isConfigured(env: Env): boolean {
    return Boolean(env.AI);
  }

  async refine(params: InternalRefineParams, env: Env): Promise<ProviderResult> {
    if (!env.AI) {
      throw new Error('Cloudflare Workers AI binding [env.AI] is not configured');
    }

    const systemPrompt = buildSystemPrompt(
      params.mode,
      params.tone,
      params.targetLanguage,
      params.customInstruction,
      params.angle
    );
    const userPrompt = buildUserPrompt(params.text);

    const model = '@cf/meta/llama-3.1-8b-instruct';

    const messages = [
      { role: 'system', content: systemPrompt },
      { role: 'user', content: userPrompt },
    ];

    const response: any = await env.AI.run(model, {
      messages,
      max_tokens: 4096,
      temperature: 0.3,
    });

    const responseText = response?.response;
    if (!responseText) {
      throw new Error('Workers AI returned an empty response');
    }

    return {
      refinedText: responseText.trim(),
      provider: 'Cloudflare Workers AI',
      model,
    };
  }
}
