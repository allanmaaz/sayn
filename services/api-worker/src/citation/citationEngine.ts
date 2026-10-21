import { CitationRequest, CitationResponse, CitationStyle } from '@sayn/shared-types';
import { Env } from '../types.js';

export async function generateCitation(
  req: CitationRequest,
  env: Env
): Promise<CitationResponse> {
  const startTime = Date.now();
  const source = req.sourceTextOrUrl.trim();
  const style: CitationStyle = req.style || 'apa';

  // If Gemini API is available, use semantic formatting
  if (env.GEMINI_API_KEY) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash-lite:generateContent?key=${env.GEMINI_API_KEY}`;
      const systemInstruction = `You are a scholarly bibliographic citation engine.
Generate an accurate, standard academic citation according to the requested style: ${style.toUpperCase()}.
Respond ONLY in valid, raw JSON format (no markdown, no backticks, no commentary) matching:
{
  "fullCitation": "Formatted reference string",
  "inTextCitation": "Parenthetical in-text citation, e.g. (Author, Year)",
  "metadata": {
    "title": "Title of work",
    "authors": ["First Last"],
    "year": "2024",
    "publisherOrSite": "Publisher or Website Name",
    "url": "https://...",
    "accessDate": "Month Day, Year"
  }
}`;

      const payload = {
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: `SOURCE TO CITE:\n"""\n${source}\n"""\nSTYLE: ${style.toUpperCase()}`,
              },
            ],
          },
        ],
        generationConfig: { temperature: 0.1, maxOutputTokens: 1024 },
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
            return {
              success: true,
              style,
              fullCitation: parsed.fullCitation || source,
              inTextCitation: parsed.inTextCitation || '(Source)',
              metadata: parsed.metadata || {},
              latencyMs: Date.now() - startTime,
            };
          }
        }
      }
    } catch {
      // fallback to rule-based formatter
    }
  }

  // Fallback Rule-Based Citation Formatter
  const currentYear = new Date().getFullYear().toString();
  const todayFormatted = new Date().toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  const isUrl = /^https?:\/\//i.test(source);
  let domain = 'Website';
  let cleanUrl = source;

  if (isUrl) {
    try {
      const u = new URL(source);
      domain = u.hostname.replace(/^www\./, '');
    } catch {
      // ignore url error
    }
  }

  let fullCitation = '';
  let inTextCitation = '';

  switch (style) {
    case 'mla':
      fullCitation = isUrl
        ? `"${domain}." ${domain}, ${cleanUrl}. Accessed ${todayFormatted}.`
        : `"${source}." (${currentYear}).`;
      inTextCitation = `("${isUrl ? domain : source.slice(0, 15)}")`;
      break;

    case 'chicago':
      fullCitation = isUrl
        ? `${domain}. "${cleanUrl}." Accessed ${todayFormatted}. ${cleanUrl}.`
        : `${source}. ${currentYear}.`;
      inTextCitation = `(${isUrl ? domain : 'Source'} ${currentYear})`;
      break;

    case 'harvard':
      fullCitation = isUrl
        ? `${domain} (${currentYear}) Available at: ${cleanUrl} (Accessed: ${todayFormatted}).`
        : `${source} (${currentYear}).`;
      inTextCitation = `(${isUrl ? domain : 'Source'}, ${currentYear})`;
      break;

    case 'apa':
    default:
      fullCitation = isUrl
        ? `${domain}. (${currentYear}). Retrieved ${todayFormatted}, from ${cleanUrl}`
        : `${source}. (${currentYear}).`;
      inTextCitation = `(${isUrl ? domain : 'Source'}, ${currentYear})`;
      break;
  }

  return {
    success: true,
    style,
    fullCitation,
    inTextCitation,
    metadata: {
      title: isUrl ? domain : source,
      authors: [domain],
      year: currentYear,
      publisherOrSite: domain,
      url: isUrl ? cleanUrl : undefined,
      accessDate: todayFormatted,
    },
    latencyMs: Date.now() - startTime,
  };
}
