import { Env, InternalRefineParams, ProviderResult } from '../types.js';

export interface LLMProvider {
  readonly name: string;
  isConfigured(env: Env): boolean;
  refine(params: InternalRefineParams, env: Env): Promise<ProviderResult>;
}
