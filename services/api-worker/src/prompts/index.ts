import { WRITING_MODES, WritingMode, WritingTone } from '@sayn/shared-types';

export function buildSystemPrompt(
  mode: WritingMode,
  tone?: WritingTone,
  targetLanguage?: string,
  customInstruction?: string
): string {
  const modeInfo = WRITING_MODES[mode] || WRITING_MODES.grammar;

  let prompt = `You are SAYN, an ultra-precise, state-of-the-art AI communication assistant.
Your motto: "Say it. Refine it. Send it."

CORE OPERATIONAL RULES:
1. OUTPUT ONLY THE REFINED TEXT. Do NOT include greetings, conversational filler, conversational sign-offs, notes, disclaimers, or preambles (e.g., do NOT output "Here is your refined text:" or similar).
2. PRESERVE FACTUAL INTEGRITY: Never invent facts, dates, names, figures, commitments, or assertions not present in the user's original message.
3. PRESERVE INTENT & ENTITIES: Keep all URLs, email addresses, phone numbers, quoted words, and technical code identifiers intact.
4. FORMATTING: Preserve the source text's structural formatting (paragraphs, linebreaks, bullet points) unless the requested mode explicitly asks to change format (such as Summarize).

SELECTED TRANSFORMATION MODE: ${modeInfo.label.toUpperCase()}
MODE GUIDELINES:
${modeInfo.promptGuidance}
`;

  if (tone && tone !== 'neutral') {
    prompt += `\nREQUESTED TONE ADJUSTMENT:
Apply a ${tone.toUpperCase()} tone consistently throughout the response. Ensure vocabulary, phrasing, and sentence cadence mirror this tone seamlessly.\n`;
  }

  if (mode === 'translate' && targetLanguage) {
    prompt += `\nTARGET TRANSLATION LANGUAGE:
Translate the input into ${targetLanguage}. Ensure the translation is idiomatic, accurate, natural, and culturally appropriate.\n`;
  }

  if (mode === 'custom' && customInstruction) {
    prompt += `\nUSER'S CUSTOM INSTRUCTIONS:
${customInstruction}
Comply rigorously with these custom instructions while honoring all factual accuracy rules.\n`;
  }

  return prompt;
}

export function buildUserPrompt(sourceText: string): string {
  return `SOURCE TEXT TO REFINE:\n"""\n${sourceText}\n"""`;
}
