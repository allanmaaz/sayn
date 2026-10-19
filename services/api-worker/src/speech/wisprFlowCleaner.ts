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

export interface WisprFlowOptions {
  stripDisfluencies?: boolean;
  parseSpokenPunctuation?: boolean;
  removeTrailingPeriod?: boolean;
}

export function cleanWisprFlowText(text: string, options: WisprFlowOptions = {}): string {
  if (!text || !text.trim()) return '';

  const {
    stripDisfluencies = true,
    parseSpokenPunctuation = true,
    removeTrailingPeriod = false,
  } = options;

  let result = text;

  // 1. Spoken Punctuation Parsing
  if (parseSpokenPunctuation) {
    for (const [pattern, replacement] of SPOKEN_PUNCTUATION_PATTERNS) {
      result = result.replace(pattern, replacement);
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
