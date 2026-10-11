/**
 * SAYN — Shared Type Definitions
 * "Say it. Refine it. Send it."
 */

export type WritingMode =
  // Core QuillBot & Keyboard Writing Modes
  | 'standard'
  | 'fluent'
  | 'natural'
  | 'professional'
  | 'casual'
  | 'shorten'
  | 'expand'
  | 'formal'
  | 'custom'
  // Extended modes for web/dictation
  | 'grammar'
  | 'paraphrase'
  | 'concise'
  | 'summarize'
  | 'clarity'
  | 'friendly'
  | 'confident'
  | 'academic'
  | 'translate';

export type WritingTone =
  | 'neutral'
  | 'professional'
  | 'casual'
  | 'friendly'
  | 'confident'
  | 'academic'
  | 'direct';

export interface WritingModeMetadata {
  id: WritingMode;
  label: string;
  description: string;
  promptGuidance: string;
}

export const WRITING_MODES: Record<WritingMode, WritingModeMetadata> = {
  standard: {
    id: 'standard',
    label: 'Standard',
    description: 'Fix grammar and readability with minimal changes while preserving meaning.',
    promptGuidance: 'Fix grammar, spelling, punctuation, capitalization, and readability with minimal changes strictly preserving original meaning and vocabulary.'
  },
  fluent: {
    id: 'fluent',
    label: 'Fluent',
    description: 'Improve flow, clarity, and sentence structure so the text reads smoothly.',
    promptGuidance: 'Improve flow, rhythm, clarity, and sentence structure. Smooth out awkward transitions so the prose reads naturally and effortlessly.'
  },
  natural: {
    id: 'natural',
    label: 'Natural',
    description: 'Produce conversational, human-sounding text without sounding robotic.',
    promptGuidance: 'Make the text sound human, genuine, and conversational. Eliminate stiff, overly robotic, or formulaic phrasing.'
  },
  professional: {
    id: 'professional',
    label: 'Professional',
    description: 'Use clear, polished, workplace-appropriate language.',
    promptGuidance: 'Transform the text into polished, courteous, and articulate workplace correspondence with clean structure and respectful professional tone.'
  },
  casual: {
    id: 'casual',
    label: 'Casual',
    description: 'Make the text relaxed, informal, and friendly.',
    promptGuidance: 'Make the text relaxed, conversational, and natural, as spoken between friends. Remove stiff or overly formal language.'
  },
  shorten: {
    id: 'shorten',
    label: 'Shorten',
    description: 'Reduce unnecessary words while preserving key information.',
    promptGuidance: 'Cut all unnecessary filler, redundancy, and fluff. Deliver the core message with maximum brevity, preserving all vital facts.'
  },
  expand: {
    id: 'expand',
    label: 'Expand',
    description: 'Elaborate thoughtfully without inventing unsupported facts.',
    promptGuidance: 'Elaborate thoughtfully on the provided thoughts. Add supportive context, smooth transitions, and thorough explanations without fabricating external facts or commitments.'
  },
  formal: {
    id: 'formal',
    label: 'Formal',
    description: 'Increase formality, precision, and respectful distance.',
    promptGuidance: 'Increase grammatical formality, precision, and dignity. Use polite, dignified vocabulary appropriate for high-stakes formal communication.'
  },
  custom: {
    id: 'custom',
    label: 'Custom',
    description: 'Follow the user\'s saved instruction precisely.',
    promptGuidance: 'Follow the specific custom user instructions precisely while preserving the foundational facts of the source text.'
  },
  grammar: {
    id: 'grammar',
    label: 'Grammar',
    description: 'Fix grammar, spelling, and punctuation without altering meaning.',
    promptGuidance: 'Correct all grammar, spelling, punctuation, capitalization, and syntax errors. Maintain the original vocabulary strictly.'
  },
  paraphrase: {
    id: 'paraphrase',
    label: 'Paraphrase',
    description: 'Rephrase with natural flow and fresh vocabulary while preserving intent.',
    promptGuidance: 'Rewrite the text using fresh, varied vocabulary and natural phrasing. Retain the core meaning, facts, and names completely.'
  },
  concise: {
    id: 'concise',
    label: 'Concise',
    description: 'Eliminate fluff and filler to deliver maximum clarity in fewer words.',
    promptGuidance: 'Deliver the core message with maximum brevity and punch, cutting all filler and preserving vital facts.'
  },
  summarize: {
    id: 'summarize',
    label: 'Summarize',
    description: 'Condense into high-impact key points and actionable takeaways.',
    promptGuidance: 'Provide a concise, high-impact summary capturing the primary thesis and essential takeaways.'
  },
  clarity: {
    id: 'clarity',
    label: 'Clarity',
    description: 'Disentangle complex sentences for crystal-clear readability.',
    promptGuidance: 'Restructure convoluted phrases into crystal-clear, active-voice sentences. Enhance flow, coherence, and immediate readability.'
  },
  friendly: {
    id: 'friendly',
    label: 'Friendly',
    description: 'Warm, approachable, empathetic, and encouraging.',
    promptGuidance: 'Infuse warm, empathetic, and encouraging tone. Make the reader feel appreciated and supported while maintaining clarity.'
  },
  confident: {
    id: 'confident',
    label: 'Confident',
    description: 'Decisive, assertive, and authoritative without being aggressive.',
    promptGuidance: 'Eliminate hesitation, filler hedges, and passive phrasing. Express ideas with calm, unwavering certainty.'
  },
  academic: {
    id: 'academic',
    label: 'Academic',
    description: 'Formal scholarly tone, structured arguments, and analytical rigor.',
    promptGuidance: 'Frame the prose in scholarly, objective academic style with precise analytical terminology and logical transitions.'
  },
  translate: {
    id: 'translate',
    label: 'Translate',
    description: 'Translate naturally into the target language preserving nuance.',
    promptGuidance: 'Accurately translate the text into the requested target language. Ensure natural native idioms and correct grammar.'
  }
};

// API Request & Response Schemas
export interface RefineRequest {
  text: string;
  mode: WritingMode;
  tone?: WritingTone;
  targetLanguage?: string;
  customInstruction?: string;
  preserveFormatting?: boolean;
}

export interface RefineResponse {
  success: boolean;
  refinedText: string;
  mode: WritingMode;
  tone?: WritingTone;
  stats: {
    originalWords: number;
    originalChars: number;
    refinedWords: number;
    refinedChars: number;
    latencyMs: number;
  };
  provider: string;
  model: string;
}

export interface TranscribeRequest {
  audioBase64?: string;
  language?: string;
}

export interface TranscribeResponse {
  success: boolean;
  transcript: string;
  durationSeconds?: number;
  language?: string;
  provider: string;
}

export interface UsageStatusResponse {
  userId: string;
  tier: 'free' | 'pro' | 'unlimited';
  requestsUsedToday: number;
  dailyLimit: number;
  remainingRequests: number;
  resetAt: string;
}

export interface HealthCheckResponse {
  status: 'ok' | 'degraded' | 'unhealthy';
  version: string;
  aiProviderConfigured: boolean;
  activeProvider: string;
  timestamp: string;
}

export interface ApiErrorResponse {
  success: false;
  error: {
    code: 'UNAUTHORIZED' | 'RATE_LIMITED' | 'INVALID_INPUT' | 'PROVIDER_ERROR' | 'CONFIGURATION_REQUIRED' | 'INTERNAL_ERROR';
    message: string;
    details?: unknown;
  };
}

// Supabase Database Models
export interface Profile {
  id: string;
  display_name: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface UserPreferences {
  id: string;
  user_id: string;
  preferred_language: string;
  default_tone: WritingTone;
  default_writing_mode: WritingMode;
  history_enabled: boolean;
  floating_assistant_enabled: boolean;
  keyboard_enabled: boolean;
  theme: 'system' | 'dark' | 'light';
  created_at: string;
  updated_at: string;
}

export interface WritingHistoryItem {
  id: string;
  user_id: string;
  source_text: string;
  result_text: string;
  writing_mode: WritingMode;
  input_language?: string;
  output_language?: string;
  provider?: string;
  created_at: string;
}

export interface SavedPrompt {
  id: string;
  user_id: string;
  name: string;
  instruction: string;
  created_at: string;
  updated_at: string;
}

export interface UsageEvent {
  id: string;
  user_id: string | null;
  event_type: 'refine' | 'transcribe' | 'paraphrase' | 'grammar';
  provider: string | null;
  model: string | null;
  input_size: number | null;
  usage_units: number;
  status: 'success' | 'rate_limited' | 'failed';
  created_at: string;
}
