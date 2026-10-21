import {
  WritingMode,
  WritingTone,
  WritingAngle,
  SynonymIntensity,
  WordAlternative,
  GrammarIssue,
} from '@sayn/shared-types';

export interface Env {
  ENVIRONMENT?: string;
  DEFAULT_AI_PROVIDER?: string;
  SUPABASE_URL?: string;
  SUPABASE_ANON_KEY?: string;
  SUPABASE_SERVICE_ROLE_KEY?: string;
  SUPABASE_JWT_SECRET?: string;

  // Provider API Keys
  GEMINI_API_KEY?: string;
  OPENAI_API_KEY?: string;
  GROQ_API_KEY?: string;

  // Cloudflare Workers AI binding
  AI?: any;

  MAX_CHARACTERS?: string | number;
  RATE_LIMIT_PER_MINUTE?: string | number;
}

export interface InternalRefineParams {
  text: string;
  mode: WritingMode;
  angle?: WritingAngle | string;
  tone?: WritingTone;
  targetLanguage?: string;
  customInstruction?: string;
  synonymLevel?: SynonymIntensity;
  freezeWords?: string[];
  includeGrammarIssues?: boolean;
  includeAlternatives?: boolean;
}

export interface ProviderResult {
  refinedText: string;
  provider: string;
  model: string;
  alternatives?: WordAlternative[];
  issues?: GrammarIssue[];
}
