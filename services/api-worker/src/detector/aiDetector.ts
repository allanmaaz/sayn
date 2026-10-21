import { DetectAiRequest, DetectAiResponse, SentenceAiClassification, AiDetectionVerdict } from '@sayn/shared-types';
import { Env } from '../types.js';

// Common synthetic AI vocabulary markers
const AI_MARKER_PATTERNS: RegExp[] = [
  /\bdelve\b/i,
  /\btestament\b/i,
  /\btapestry\b/i,
  /\bbeacon\b/i,
  /\bfurthermore\b/i,
  /\bmoreover\b/i,
  /\bit is important to note\b/i,
  /\bin conclusion\b/i,
  /\bvital role\b/i,
  /\binterplay\b/i,
  /\bnavigating the\b/i,
  /\blandscape of\b/i,
  /\bseamlessly\b/i,
  /\bparadigm\b/i,
  /\bholistic\b/i,
  /\bfoster(?:ing)?\b/i,
  /\bembark(?:ing)?\b/i,
];

/**
 * Deterministic Perplexity & Burstiness Statistical Heuristic
 */
function analyzeStatisticalFeatures(text: string) {
  // Split into sentences
  const rawSentences = text
    .split(/(?<=[.?!])\s+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  if (rawSentences.length === 0) {
    return {
      perplexity: 50,
      burstiness: 50,
      markerCount: 0,
      sentenceLengths: [],
    };
  }

  // Sentence lengths (in words)
  const sentenceLengths = rawSentences.map((s) => s.split(/\s+/).filter(Boolean).length);
  const avgLength = sentenceLengths.reduce((a, b) => a + b, 0) / sentenceLengths.length;

  // Variance / Standard Deviation in sentence length (Human writing has high burstiness)
  const variance =
    sentenceLengths.reduce((acc, len) => acc + Math.pow(len - avgLength, 2), 0) / sentenceLengths.length;
  const stdDev = Math.sqrt(variance);

  // Burstiness index (stdDev / avgLength): > 0.5 is typically human, < 0.25 is strongly AI
  const burstinessScore = Math.min(100, Math.max(0, Math.round((stdDev / Math.max(1, avgLength)) * 100)));

  // Count AI Marker Words
  let markerHits = 0;
  for (const pattern of AI_MARKER_PATTERNS) {
    const matches = text.match(pattern);
    if (matches) markerHits += matches.length;
  }

  // Approximate perplexity score
  // Robotic prose with uniform sentence lengths and clichés has low perplexity (high AI probability)
  const perplexityScore = Math.min(
    100,
    Math.max(10, Math.round(burstinessScore * 0.7 + (rawSentences.length > 3 ? 30 : 50) - markerHits * 8))
  );

  return {
    perplexity: perplexityScore,
    burstiness: burstinessScore,
    markerCount: markerHits,
    sentenceLengths,
  };
}

/**
 * Segment and score individual sentences
 */
function classifySentencesHeuristic(text: string, overallAiPct: number): SentenceAiClassification[] {
  const result: SentenceAiClassification[] = [];
  const regex = /([^.?!]+[.?!]+(?:\s+|$)|[^.?!]+$)/g;
  let match: RegExpExecArray | null;

  while ((match = regex.exec(text)) !== null) {
    const sText = match[0].trim();
    if (!sText) continue;

    const startOffset = match.index;
    const endOffset = startOffset + match[0].length;
    const words = sText.split(/\s+/).filter(Boolean);
    const wordCount = words.length;

    let sentenceAiScore = overallAiPct / 100;
    let reasons: string[] = [];

    // Check for AI markers
    for (const pattern of AI_MARKER_PATTERNS) {
      if (pattern.test(sText)) {
        sentenceAiScore = Math.min(0.95, sentenceAiScore + 0.25);
        reasons.push('Contains characteristic AI synthetic vocabulary');
      }
    }

    // Monotonous mid-length sentence check (14-22 words)
    if (wordCount >= 14 && wordCount <= 22) {
      sentenceAiScore = Math.min(0.9, sentenceAiScore + 0.1);
    } else if (wordCount < 6 || wordCount > 35) {
      // Extremely short or long asymmetric sentences are more typically human
      sentenceAiScore = Math.max(0.1, sentenceAiScore - 0.2);
    }

    const aiProb = Math.round(sentenceAiScore * 100) / 100;
    const verdict: 'human' | 'uncertain' | 'ai' =
      aiProb >= 0.7 ? 'ai' : aiProb >= 0.4 ? 'uncertain' : 'human';

    result.push({
      sentence: sText,
      startOffset,
      endOffset,
      aiProbability: aiProb,
      verdict,
      reason: reasons.length > 0 ? reasons.join('; ') : undefined,
    });
  }

  return result;
}

/**
 * Execute AI Detection with Gemini LLM analysis and mathematical fallback
 */
export async function detectAiContent(
  req: DetectAiRequest,
  env: Env
): Promise<DetectAiResponse> {
  const startTime = Date.now();
  const text = req.text.trim();
  const words = text.split(/\s+/).filter(Boolean);
  const wordCount = words.length;

  const stats = analyzeStatisticalFeatures(text);

  // If Gemini API is configured, use deep semantic analysis
  if (env.GEMINI_API_KEY && wordCount >= 15) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${env.GEMINI_API_KEY}`;
      const systemInstruction = `You are an expert AI linguistic forensic detector.
Analyze the user's text for markers of AI generation (perplexity, sentence burstiness, vocabulary predictability, cliché transitions).
Return ONLY a valid, raw JSON object (no markdown, no backticks, no commentary) matching this schema:
{
  "overallAiPercentage": 85,
  "verdict": "likely_ai" | "mixed_or_uncertain" | "likely_human",
  "perplexityScore": 42,
  "burstinessScore": 38,
  "analysisSummary": "1-2 sentence forensic explanation of findings",
  "sentences": [
    {
      "sentence": "Exact sentence text",
      "aiProbability": 0.85,
      "verdict": "ai" | "uncertain" | "human",
      "reason": "Brief explanation"
    }
  ]
}`;

      const payload = {
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents: [{ role: 'user', parts: [{ text: `TEXT TO DETECT:\n"""\n${text}\n"""` }] }],
        generationConfig: { temperature: 0.1, maxOutputTokens: 2048 },
      };

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        const data: any = await response.json();
        const candidateText = data.candidates?.[0]?.content?.parts?.[0]?.text;
        if (candidateText) {
          let cleaned = candidateText.trim();
          if (cleaned.startsWith('```') && cleaned.endsWith('```')) {
            cleaned = cleaned.replace(/^```[a-z]*\n?/, '').replace(/\n?```$/, '').trim();
          }

          if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
            const parsed = JSON.parse(cleaned);
            const aiPct = Math.min(100, Math.max(0, Math.round(parsed.overallAiPercentage ?? 50)));
            const sentencesWithOffsets: SentenceAiClassification[] = (parsed.sentences || []).map((s: any) => {
              const startOffset = text.indexOf(s.sentence);
              return {
                sentence: s.sentence,
                startOffset: startOffset >= 0 ? startOffset : 0,
                endOffset: startOffset >= 0 ? startOffset + s.sentence.length : s.sentence.length,
                aiProbability: Math.min(1, Math.max(0, Number(s.aiProbability ?? 0.5))),
                verdict: s.verdict || (s.aiProbability >= 0.7 ? 'ai' : s.aiProbability >= 0.4 ? 'uncertain' : 'human'),
                reason: s.reason,
              };
            });

            return {
              success: true,
              overallAiPercentage: aiPct,
              humanPercentage: 100 - aiPct,
              verdict: parsed.verdict || (aiPct >= 65 ? 'likely_ai' : aiPct >= 35 ? 'mixed_or_uncertain' : 'likely_human'),
              perplexityScore: parsed.perplexityScore || stats.perplexity,
              burstinessScore: parsed.burstinessScore || stats.burstiness,
              wordCount,
              sentenceCount: sentencesWithOffsets.length || 1,
              sentences: sentencesWithOffsets.length > 0 ? sentencesWithOffsets : classifySentencesHeuristic(text, aiPct),
              analysisSummary: parsed.analysisSummary || 'Analyzed via deep linguistic pattern detection.',
              latencyMs: Date.now() - startTime,
            };
          }
        }
      }
    } catch {
      // Fallback to deterministic heuristic if API call fails
    }
  }

  // Deterministic Heuristic Fallback
  let baseAiPct = 50;
  if (stats.burstiness < 30) baseAiPct += 25;
  else if (stats.burstiness > 65) baseAiPct -= 25;

  baseAiPct += stats.markerCount * 12;
  const overallAiPercentage = Math.min(98, Math.max(2, baseAiPct));
  const humanPercentage = 100 - overallAiPercentage;

  const verdict: AiDetectionVerdict =
    overallAiPercentage >= 65 ? 'likely_ai' : overallAiPercentage >= 35 ? 'mixed_or_uncertain' : 'likely_human';

  const sentences = classifySentencesHeuristic(text, overallAiPercentage);

  return {
    success: true,
    overallAiPercentage,
    humanPercentage,
    verdict,
    perplexityScore: stats.perplexity,
    burstinessScore: stats.burstiness,
    wordCount,
    sentenceCount: sentences.length,
    sentences,
    analysisSummary:
      verdict === 'likely_ai'
        ? 'High uniformity in sentence cadence and synthetic structural markers detected.'
        : verdict === 'likely_human'
        ? 'Natural burstiness and organic variations in sentence structure detected.'
        : 'Mixed linguistic signals: contains some repetitive structures with natural phrasing.',
    latencyMs: Date.now() - startTime,
  };
}
