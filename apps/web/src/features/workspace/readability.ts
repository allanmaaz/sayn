import { DocumentScoreMetrics, GrammarIssue } from '@sayn/shared-types';

/**
 * Counts syllables in an English word using phonetic heuristic.
 */
export function countSyllables(word: string): number {
  word = word.toLowerCase().trim().replace(/[^a-z]/g, '');
  if (!word) return 0;
  if (word.length <= 3) return 1;

  // Remove common trailing non-syllabic patterns
  word = word.replace(/(?:[^laeiouy]|ed|es|e)$/, '');
  word = word.replace(/^y/, '');

  const matches = word.match(/[aeiouy]{1,2}/g);
  return matches ? Math.max(1, matches.length) : 1;
}

/**
 * Calculates Flesch Reading Ease & Document Score Metrics in 0ms client-side.
 */
export function calculateDocumentMetrics(
  text: string,
  issues: GrammarIssue[] = []
): DocumentScoreMetrics {
  const clean = text.trim();
  if (!clean) {
    return {
      overallScore: 100,
      readabilityScore: 100,
      gradeLevel: 'Simple',
      readingTimeMinutes: 0,
      wordCount: 0,
      characterCount: 0,
      sentenceCount: 0,
      issuesCount: { correctness: 0, clarity: 0, engagement: 0, delivery: 0 },
    };
  }

  const words = clean.split(/\s+/).filter(Boolean);
  const sentences = clean.split(/[.!?]+/).filter((s) => s.trim().length > 0);
  const numWords = Math.max(1, words.length);
  const numSentences = Math.max(1, sentences.length);

  let totalSyllables = 0;
  for (const w of words) {
    totalSyllables += countSyllables(w);
  }

  // Flesch Reading Ease: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
  const wordsPerSentence = numWords / numSentences;
  const syllablesPerWord = totalSyllables / numWords;
  let flesch = 206.835 - 1.015 * wordsPerSentence - 84.6 * syllablesPerWord;
  flesch = Math.max(0, Math.min(100, Math.round(flesch)));

  // Grade level translation
  let gradeLevel = '8th-9th Grade (Standard)';
  if (flesch >= 90) gradeLevel = '5th Grade (Very Easy)';
  else if (flesch >= 80) gradeLevel = '6th Grade (Easy)';
  else if (flesch >= 70) gradeLevel = '7th Grade (Fairly Easy)';
  else if (flesch >= 60) gradeLevel = '8th-9th Grade (Plain English)';
  else if (flesch >= 50) gradeLevel = '10th-12th Grade (Fairly Difficult)';
  else if (flesch >= 30) gradeLevel = 'College Level (Difficult)';
  else gradeLevel = 'Graduate / Academic (Very Difficult)';

  // Issue Counts
  const issuesCount = {
    correctness: issues.filter((i) => i.pillar === 'correctness').length,
    clarity: issues.filter((i) => i.pillar === 'clarity').length,
    engagement: issues.filter((i) => i.pillar === 'engagement').length,
    delivery: issues.filter((i) => i.pillar === 'delivery').length,
  };

  // Penalties calculation
  const penalty =
    issuesCount.correctness * 4 +
    issuesCount.clarity * 2.5 +
    issuesCount.engagement * 1.5 +
    issuesCount.delivery * 1.0;

  const overallScore = Math.max(10, Math.min(100, Math.round(100 - penalty)));
  const readingTimeMinutes = Math.max(0.1, Number((numWords / 225).toFixed(1)));

  return {
    overallScore,
    readabilityScore: flesch,
    gradeLevel,
    readingTimeMinutes,
    wordCount: numWords,
    characterCount: clean.length,
    sentenceCount: numSentences,
    issuesCount,
  };
}

/**
 * Instant local heuristic rules for 0ms Grammarly-style checks.
 */
export function analyzeLocalGrammarIssues(text: string): GrammarIssue[] {
  const issues: GrammarIssue[] = [];
  if (!text.trim()) return issues;

  // 1. Wordy Phrases (Clarity)
  const wordyRules = [
    { pattern: /\bin order to\b/gi, replacement: 'to', title: 'Wordiness', explanation: 'Consider simplifying to make the sentence more direct.' },
    { pattern: /\bat this point in time\b/gi, replacement: 'now', title: 'Redundant phrasing', explanation: 'Use "now" or "currently" for concise delivery.' },
    { pattern: /\bdue to the fact that\b/gi, replacement: 'because', title: 'Wordy construction', explanation: 'Replace with "because" to improve clarity.' },
    { pattern: /\bfor the purpose of\b/gi, replacement: 'for', title: 'Wordiness', explanation: 'Simplify to "for" or "to".' },
    { pattern: /\butilize\b/gi, replacement: 'use', title: 'Unnecessary jargon', explanation: '"Use" is almost always clearer than "utilize".' },
    { pattern: /\bhas the ability to\b/gi, replacement: 'can', title: 'Wordy verb', explanation: 'Simplify "has the ability to" to "can".' },
    { pattern: /\ba number of\b/gi, replacement: 'several', title: 'Vague quantity', explanation: 'Use "several" or "many" for directness.' },
  ];

  for (const rule of wordyRules) {
    let match: RegExpExecArray | null;
    while ((match = rule.pattern.exec(text)) !== null) {
      issues.push({
        id: `clarity-${match.index}`,
        pillar: 'clarity',
        title: rule.title,
        explanation: rule.explanation,
        startOffset: match.index,
        endOffset: match.index + match[0].length,
        originalText: match[0],
        suggestedReplacement: rule.replacement,
      });
    }
  }

  // 2. Overused Adjectives & Bland Words (Engagement)
  const engagementRules = [
    { pattern: /\bvery good\b/gi, replacement: 'exceptional', title: 'Vivid word choice', explanation: 'Replace "very good" with a more vivid, impactful adjective.' },
    { pattern: /\bvery bad\b/gi, replacement: 'terrible', title: 'Stronger adjective', explanation: 'Consider a more evocative word than "very bad".' },
    { pattern: /\breally important\b/gi, replacement: 'critical', title: 'Emphasis', explanation: '"Critical", "essential", or "vital" carries stronger weight.' },
    { pattern: /\ba lot of\b/gi, replacement: 'abundant', title: 'Casual modifier', explanation: 'Use "substantial", "numerous", or "abundant".' },
  ];

  for (const rule of engagementRules) {
    let match: RegExpExecArray | null;
    while ((match = rule.pattern.exec(text)) !== null) {
      issues.push({
        id: `engagement-${match.index}`,
        pillar: 'engagement',
        title: rule.title,
        explanation: rule.explanation,
        startOffset: match.index,
        endOffset: match.index + match[0].length,
        originalText: match[0],
        suggestedReplacement: rule.replacement,
      });
    }
  }

  // 3. Timid & Hedging Delivery (Delivery)
  const deliveryRules = [
    { pattern: /\bI just wanted to check\b/gi, replacement: 'I am checking', title: 'Hedging language', explanation: 'Removing "just wanted to" makes your communication more confident.' },
    { pattern: /\bI think that maybe\b/gi, replacement: 'Perhaps', title: 'Over-hedging', explanation: 'State ideas directly without excessive qualification.' },
    { pattern: /\bSorry to bother you\b/gi, replacement: 'Thank you for your time', title: 'Apologetic opening', explanation: 'Replace preemptive apologies with a courteous closing or direct question.' },
  ];

  for (const rule of deliveryRules) {
    let match: RegExpExecArray | null;
    while ((match = rule.pattern.exec(text)) !== null) {
      issues.push({
        id: `delivery-${match.index}`,
        pillar: 'delivery',
        title: rule.title,
        explanation: rule.explanation,
        startOffset: match.index,
        endOffset: match.index + match[0].length,
        originalText: match[0],
        suggestedReplacement: rule.replacement,
      });
    }
  }

  // 4. Basic Mechanical Typos & Spacing (Correctness)
  const doubleSpace = /[ ]{2,}/g;
  let spaceMatch: RegExpExecArray | null;
  while ((spaceMatch = doubleSpace.exec(text)) !== null) {
    issues.push({
      id: `correctness-space-${spaceMatch.index}`,
      pillar: 'correctness',
      title: 'Extra spacing',
      explanation: 'Multiple spaces detected. Standardize to a single space.',
      startOffset: spaceMatch.index,
      endOffset: spaceMatch.index + spaceMatch[0].length,
      originalText: spaceMatch[0],
      suggestedReplacement: ' ',
    });
  }

  return issues;
}
