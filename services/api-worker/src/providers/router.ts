import { Env, InternalRefineParams, ProviderResult } from '../types.js';
import { LLMProvider } from './types.js';
import { GeminiProvider } from './gemini.js';
import { OpenAIProvider } from './openai.js';
import { GroqProvider } from './groq.js';
import { WorkersAIProvider } from './workersAi.js';
import { BuiltinEngine } from './builtin.js';

export class ProviderRouter {
  private providers: LLMProvider[];
  private fallbackProvider: LLMProvider;

  constructor() {
    this.providers = [
      new GeminiProvider(),
      new OpenAIProvider(),
      new GroqProvider(),
      new WorkersAIProvider(),
    ];
    this.fallbackProvider = new BuiltinEngine();
  }

  getActiveProvider(env: Env): LLMProvider {
    // Check if user specified a default provider and if it is configured
    const preferred = env.DEFAULT_AI_PROVIDER?.toLowerCase();
    if (preferred) {
      const match = this.providers.find((p) => p.name === preferred);
      if (match && match.isConfigured(env)) {
        return match;
      }
    }

    // Otherwise find the first configured external provider
    for (const provider of this.providers) {
      if (provider.isConfigured(env)) {
        return provider;
      }
    }

    // Return the built-in fallback engine
    return this.fallbackProvider;
  }

  isAnyConfigured(env: Env): boolean {
    return this.providers.some((p) => p.isConfigured(env));
  }

  getConfiguredProviderNames(env: Env): string[] {
    const active = this.providers
      .filter((p) => p.isConfigured(env))
      .map((p) => p.name);
    return active.length > 0 ? active : [this.fallbackProvider.name];
  }

  async refine(params: InternalRefineParams, env: Env): Promise<ProviderResult> {
    const provider = this.getActiveProvider(env);
    return provider.refine(params, env);
  }
}

