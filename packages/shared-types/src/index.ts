/**
 * SAYN — Shared Type Definitions
 * "Say it. Refine it. Send it."
 */

export type WritingMode =
  // 4 Core AI Writing Styles
  | 'flow'
  | 'professional'
  | 'humanize'
  | 'mammals'
  // Core Writing Modes
  | 'standard'
  | 'fluent'
  | 'natural'
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

export type WritingAngle = 'normal' | 'professional' | 'alternative_english';

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
  flow: {
    id: 'flow',
    label: 'Fluency',
    description: 'Effortless cognitive flow and rhythm without altering original voice.',
    promptGuidance: 'Improve flow, rhythm, and sentence transitions so the prose reads naturally and effortlessly. Eliminate speech disfluencies, false starts, and hesitation words while preserving the author\'s original vocabulary and voice. Keep punctuation light and balanced.'
  },
  humanize: {
    id: 'humanize',
    label: 'Humanization',
    description: 'Warm, organic human resonance with dynamic rhythm and zero AI clichés.',
    promptGuidance: 'Infuse authentic, empathetic human warmth. Strictly strip away all synthetic AI markers (ban "delve", "testament", "tapestry", "beacon", "furthermore", "moreover"). Use dynamic, asymmetric sentence lengths like a real thoughtful person speaking to a peer.'
  },
  mammals: {
    id: 'mammals',
    label: 'Mammals',
    description: 'Modern low-friction messaging and casual texting with strictly zero trailing periods.',
    promptGuidance: 'Transform into modern, high-bandwidth digital texting cadence. Fix typos and grammar seamlessly while preserving casual shorthand and natural flow. CRITICAL RULE: STRICTLY NEVER append a full stop or period (.) at the very end of single sentences or text message bursts.'
  },
  standard: {
    id: 'standard',
    label: 'Standard',
    description: 'Fix grammar and readability with natural flow while preserving meaning.',
    promptGuidance: 'Fix grammar, spelling, and readability while preserving original meaning. Keep punctuation light and conversational: do NOT overuse commas, full stops, or underscores. Make it sound like a natural, articulate human.'
  },
  fluent: {
    id: 'fluent',
    label: 'Fluent',
    description: 'Improve flow, clarity, and sentence structure so the text reads smoothly.',
    promptGuidance: 'Improve flow, rhythm, and sentence transitions so the prose reads naturally and effortlessly like a real person. Keep punctuation clean without excessive commas, choppy stops, or underscores.'
  },
  natural: {
    id: 'natural',
    label: 'Natural',
    description: 'Produce conversational, human-sounding text without sounding robotic.',
    promptGuidance: 'Make the text sound genuine, human, and conversational. Eliminate stiff robotic phrasing, excessive commas, underscores, and choppy full stops.'
  },
  professional: {
    id: 'professional',
    label: 'Professional',
    description: 'Use clear, polished, workplace-appropriate language.',
    promptGuidance: 'Transform the text into polished, articulate workplace communication with smooth flow. Keep punctuation clean and natural without unnecessary commas or robotic dividers.'
  },
  casual: {
    id: 'casual',
    label: 'Casual',
    description: 'Make the text relaxed, informal, and friendly.',
    promptGuidance: 'Make the text relaxed, conversational, and natural, as spoken between colleagues or friends. Avoid stiff grammar, excessive commas, or robotic punctuation.'
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

// QuillBot & Grammarly Structured Data Definitions
export type SynonymIntensity = 0 | 1 | 2 | 3 | 4; // 0=Strict/Min, 1=Low, 2=Medium, 3=High, 4=Max

export interface WordAlternative {
  wordIndex: number;
  originalWord: string;
  paraphrasedWord: string;
  synonyms: string[];
}

export type GrammarlyPillar = 'correctness' | 'clarity' | 'engagement' | 'delivery';

export interface GrammarIssue {
  id: string;
  pillar: GrammarlyPillar;
  title: string;
  explanation: string;
  startOffset: number;
  endOffset: number;
  originalText: string;
  suggestedReplacement: string;
}

export interface DocumentScoreMetrics {
  overallScore: number; // 0 - 100
  readabilityScore: number; // Flesch Reading Ease (0 - 100)
  gradeLevel: string; // e.g. "8th Grade", "College", "Expert"
  readingTimeMinutes: number;
  wordCount: number;
  characterCount: number;
  sentenceCount: number;
  issuesCount: {
    correctness: number;
    clarity: number;
    engagement: number;
    delivery: number;
  };
}

// API Request & Response Schemas
export interface RefineRequest {
  text: string;
  mode: WritingMode;
  tone?: WritingTone;
  targetLanguage?: string;
  customInstruction?: string;
  preserveFormatting?: boolean;
  synonymLevel?: SynonymIntensity;
  freezeWords?: string[];
  includeGrammarIssues?: boolean;
  includeAlternatives?: boolean;
}

export interface RefineResponse {
  success: boolean;
  refinedText: string;
  mode: WritingMode;
  tone?: WritingTone;
  synonymLevel?: SynonymIntensity;
  stats: {
    originalWords: number;
    originalChars: number;
    refinedWords: number;
    refinedChars: number;
    latencyMs: number;
  };
  provider: string;
  model: string;
  alternatives?: WordAlternative[];
  issues?: GrammarIssue[];
  metrics?: DocumentScoreMetrics;
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
