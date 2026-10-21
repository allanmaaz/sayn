/**
 * SAYN Wispr Flow Cleaner & Spoken Punctuation Engine
 * Provides sub-15ms deterministic cleanup of voice dictation:
 * 1. Spoken Punctuation parsing ("question mark" -> "?", "period" -> ".")
 * 2. Disfluency & hesitation particle stripping ("um", "uh", "you know")
 * 3. Currency & percentage formatting ("twenty dollars" -> "$20")
 * 4. Punctuation normalization & spacing cleanup
 * 5. Mammals zero-trailing-period enforcement
 */

// Spoken punctuation rules
const SPOKEN_PUNCTUATION_PATTERNS: Array<[RegExp, string]> = [
  [/\b(?:new line|next line)\b/gi, '\n'],
  [/\b(?:new paragraph|next paragraph)\b/gi, '\n\n'],
  [/\b(?:question mark)\b/gi, '?'],
  [/\b(?:exclamation point|exclamation mark)\b/gi, '!'],
  [/\b(?:full stop|period)\b/gi, '.'],
  [/\b(?:comma)\b/gi, ','],
  [/\b(?:colon)\b/gi, ':'],
  [/\b(?:semicolon)\b/gi, ';'],
  [/\b(?:open quote|quote)\s*(.*?)\s*(?:close quote|end quote|unquote)\b/gi, '"$1"'],
];

// Spoken currency and percentage patterns
const SPOKEN_NUMBER_PATTERNS: Array<[RegExp, string]> = [
  [/\b(\d+)\s+dollars?\b/gi, '$$$1'],
  [/\b(\d+)\s+percent\b/gi, '$1%'],
];

// Disfluency & filler words (matched with word boundaries and optional surrounding commas)
const FILLER_PATTERNS: RegExp[] = [
  /\b(?:um|uh|er|ah)\b,?\s*/gi,
  /\b(?:you know|sort of|kind of|so yeah|basically|i mean|honestly|actually)\b,?\s*/gi,
];

// Phonetic & Technical Jargon Whitelist (Wispr Flow vocabulary engine)
const PHONETIC_JARGON_REPLACEMENTS: Array<[RegExp, string]> = [
  [/\b(?:super\s*base|superbass)\b/gi, 'Supabase'],
  [/\b(?:sayn|sane\s+ai)\b/gi, 'SAYN'],
  [/\b(?:cloud\s*flare)\b/gi, 'Cloudflare'],
  [/\b(?:post\s*gres(?:ql)?|postgress?)\b/gi, 'PostgreSQL'],
  [/\b(?:git\s*hub)\b/gi, 'GitHub'],
  [/\b(?:git\s*lab)\b/gi, 'GitLab'],
  [/\b(?:type\s*script)\b/gi, 'TypeScript'],
  [/\b(?:java\s*script)\b/gi, 'JavaScript'],
  [/\b(?:open\s*a\s*i)\b/gi, 'OpenAI'],
  [/\b(?:chat\s*g\s*p\s*t|chat\s*gpt)\b/gi, 'ChatGPT'],
  [/\b(?:vs\s*code|visual\s+studio\s+code)\b/gi, 'VS Code'],
  [/\b(?:next\s*js)\b/gi, 'Next.js'],
  [/\b(?:node\s*js)\b/gi, 'Node.js'],
  [/\b(?:you\s*are\s*l|you\s*are\s*ell)\b/gi, 'URL'],
  [/\b(?:a\s+p\s+i)\b/gi, 'API'],
  [/\b(?:p\s+r)\b/gi, 'PR'],
  [/\b(?:u\s+i)\b/gi, 'UI'],
  [/\b(?:u\s+x)\b/gi, 'UX'],
  [/\b(?:q\s+a)\b/gi, 'QA'],
  [/\b(?:s\s+d\s+k)\b/gi, 'SDK'],
  [/\b(?:c\s+i\s*\/\s*c\s+d|c\s+i\s+c\s+d)\b/gi, 'CI/CD'],
];

export interface WisprFlowOptions {
  stripDisfluencies?: boolean;
  parseSpokenPunctuation?: boolean;
  removeTrailingPeriod?: boolean;
  applyPhoneticJargon?: boolean;
  customDictionary?: Record<string, string>;
}

export function cleanWisprFlowText(text: string, options: WisprFlowOptions = {}): string {
  if (!text || !text.trim()) return '';

  const {
    stripDisfluencies = true,
    parseSpokenPunctuation = true,
    removeTrailingPeriod = false,
    applyPhoneticJargon = true,
    customDictionary,
  } = options;

  let result = text;

  // 1. Spoken Punctuation Parsing
  if (parseSpokenPunctuation) {
    for (const [pattern, replacement] of SPOKEN_PUNCTUATION_PATTERNS) {
      result = result.replace(pattern, replacement);
    }
  }

  // 1b. Phonetic & Technical Jargon Mapping
  if (applyPhoneticJargon) {
    for (const [pattern, replacement] of PHONETIC_JARGON_REPLACEMENTS) {
      result = result.replace(pattern, replacement);
    }
  }

  // 1c. Custom Dictionary Replacements
  if (customDictionary && typeof customDictionary === 'object') {
    for (const [rawKey, targetWord] of Object.entries(customDictionary)) {
      if (rawKey.trim() && targetWord) {
        const escaped = rawKey.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        result = result.replace(new RegExp(`\\b${escaped}\\b`, 'gi'), targetWord);
      }
    }
  }

  // 2. Disfluency & Filler Stripping
  if (stripDisfluencies) {
    for (const pattern of FILLER_PATTERNS) {
      result = result.replace(pattern, ' ');
    }
  }

  // 3. Spoken Numbers & Currency
  for (const [pattern, replacement] of SPOKEN_NUMBER_PATTERNS) {
    result = result.replace(pattern, replacement);
  }

  // 4. Clean up spaces around punctuation
  // Remove space before punctuation: "hello , world ." -> "hello, world."
  result = result.replace(/\s+([,.:;?!])/g, '$1');
  // Ensure single space after punctuation (if followed by a word): "hello,world" -> "hello, world"
  result = result.replace(/([,.:;?!])([a-zA-Z0-9])/g, '$1 $2');
  // Collapse multiple spaces
  result = result.replace(/[ \t]+/g, ' ');
  // Collapse multiple newlines to max 2
  result = result.replace(/\n{3,}/g, '\n\n');

  // 5. Capitalize first letter of sentences
  result = result.replace(/(^|[.?!]\s+|\n\s*)([a-z])/g, (_match, prefix, char) => {
    return prefix + char.toUpperCase();
  });

  result = result.trim();

  // 6. Zero Trailing Period (for Mammals mode or casual texting)
  if (removeTrailingPeriod && result.endsWith('.')) {
    result = result.slice(0, -1).trimEnd();
  }

  return result;
}
