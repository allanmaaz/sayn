import { z } from 'zod';
import { Env } from './types.js';
import { getCorsHeaders, handleOptions } from './middleware/cors.js';
import { authenticateRequest } from './middleware/auth.js';
import { ProviderRouter } from './providers/router.js';
import { handleTranscription } from './speech/transcribe.js';
import { cleanWisprFlowText } from './speech/wisprFlowCleaner.js';
import { detectAiContent } from './detector/aiDetector.js';
import { generateCitation } from './citation/citationEngine.js';
import { lookupWordDefinition } from './dictionary/dictionaryService.js';
import {
  HealthCheckResponse,
  RefineResponse,
  UsageStatusResponse,
  WritingMode,
} from '@sayn/shared-types';

const router = new ProviderRouter();

// Input Validation Schemas
const RefineSchema = z.object({
  text: z.string().min(1, 'Text cannot be empty').max(8000, 'Text exceeds 8000 character maximum'),
  mode: z.enum([
    'flow',
    'professional',
    'humanize',
    'mammals',
    'standard',
    'fluent',
    'natural',
    'casual',
    'shorten',
    'expand',
    'formal',
    'custom',
    'grammar',
    'paraphrase',
    'concise',
    'summarize',
    'clarity',
    'friendly',
    'confident',
    'academic',
    'translate',
  ] as const),
  angle: z.enum(['normal', 'professional', 'alternative_english'] as const).optional(),
  tone: z
    .enum(['neutral', 'professional', 'casual', 'friendly', 'confident', 'academic', 'direct'] as const)
    .optional(),
  targetLanguage: z.string().optional(),
  customInstruction: z.string().max(500).optional(),
  preserveFormatting: z.boolean().optional(),
  synonymLevel: z.union([z.literal(0), z.literal(1), z.literal(2), z.literal(3), z.literal(4)]).optional(),
  freezeWords: z.array(z.string()).optional(),
  includeGrammarIssues: z.boolean().optional(),
  includeAlternatives: z.boolean().optional(),
});

const DetectAiSchema = z.object({
  text: z.string().min(1, 'Text cannot be empty').max(100000, 'Text exceeds 100,000 character maximum'),
});

const CitationSchema = z.object({
  sourceTextOrUrl: z.string().min(1, 'Source cannot be empty').max(2000),
  style: z.enum(['apa', 'mla', 'chicago', 'harvard'] as const).default('apa'),
  sourceType: z.enum(['website', 'journal', 'book', 'article', 'auto'] as const).optional(),
});

const DictionarySchema = z.object({
  word: z.string().min(1, 'Word cannot be empty').max(100, 'Word exceeds 100 character maximum'),
  contextSentence: z.string().max(1000).optional(),
});

function jsonResponse(data: unknown, status = 200, origin: string | null = '*'): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...getCorsHeaders(origin),
    },
  });
}

function errorResponse(
  code: string,
  message: string,
  status = 400,
  details?: unknown,
  origin: string | null = '*'
): Response {
  return jsonResponse(
    {
      success: false,
      error: { code, message, details },
    },
    status,
    origin
  );
}

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin');

    // Handle CORS preflight
    if (request.method === 'OPTIONS') {
      return handleOptions(request);
    }

    try {
      // 1. HEALTH CHECK
      if (url.pathname === '/api/v1/health' && request.method === 'GET') {
        const configuredProviders = router.getConfiguredProviderNames(env);
        const active = router.getActiveProvider(env);

        const health: HealthCheckResponse = {
          status: 'ok',
          version: '1.0.0',
          aiProviderConfigured: configuredProviders.length > 0,
          activeProvider: active ? active.name : 'none',
          timestamp: new Date().toISOString(),
        };

        return jsonResponse(health, 200, origin);
      }

      // 1b. PUBLIC APP VERSION CHECK & UPDATE SERVER
      if (url.pathname === '/api/v1/version' && request.method === 'GET') {
        const updatePayload = {
          version: '1.1.6',
          versionCode: 17,
          name: 'SAYN v1.1.6',
          releaseNotes: 'Samsung One UI 8.5 zero-lag touch engine, interactive word definitions & pronunciations, freeze word toggle, and polished landing page.',
          downloadUrl: 'https://github.com/allanmaaz/sayn/releases/download/v1.1.6/sayn-release.apk',
          publishedAt: new Date().toISOString(),
        };
        return jsonResponse(updatePayload, 200, origin);
      }

      // 2. USAGE STATUS
      if (url.pathname === '/api/v1/usage' && request.method === 'GET') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        const usageStatus: UsageStatusResponse = {
          userId: user.id,
          tier: 'free',
          requestsUsedToday: 4,
          dailyLimit: 50,
          remainingRequests: 46,
          resetAt: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
        };

        return jsonResponse(usageStatus, 200, origin);
      }

      // 3. AI SPEECH TRANSCRIPTION
      if (url.pathname === '/api/v1/ai/transcribe' && request.method === 'POST') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        try {
          const result = await handleTranscription(request, env);
          return jsonResponse(result, 200, origin);
        } catch (err: any) {
          const isConfig = err.message.includes('CONFIGURATION_REQUIRED');
          return errorResponse(
            isConfig ? 'CONFIGURATION_REQUIRED' : 'PROVIDER_ERROR',
            err.message,
            isConfig ? 503 : 500,
            null,
            origin
          );
        }
      }

      // 4. AI REFINEMENT (Core & Shortcuts)
      const shortcutModes: Record<string, WritingMode> = {
        '/api/v1/ai/refine': 'grammar', // default if not specified
        '/api/v1/ai/grammar': 'grammar',
        '/api/v1/ai/paraphrase': 'paraphrase',
        '/api/v1/ai/summarize': 'summarize',
        '/api/v1/ai/translate': 'translate',
        '/api/v1/ai/concise': 'concise',
      };

      if (Object.keys(shortcutModes).includes(url.pathname) && request.method === 'POST') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        let rawBody: any;
        try {
          rawBody = await request.json();
        } catch {
          return errorResponse('INVALID_INPUT', 'Malformed JSON body in request', 400, null, origin);
        }

        // Apply shortcut mode if path is specific
        if (url.pathname !== '/api/v1/ai/refine') {
          rawBody.mode = shortcutModes[url.pathname];
        }

        const parsed = RefineSchema.safeParse(rawBody);
        if (!parsed.success) {
          return errorResponse(
            'INVALID_INPUT',
            'Validation failed for refine parameters',
            422,
            parsed.error.errors,
            origin
          );
        }

        const startTime = Date.now();
        try {
          const providerResult = await router.refine(parsed.data, env);
          const latencyMs = Date.now() - startTime;

          const originalWords = parsed.data.text.trim().split(/\s+/).filter(Boolean).length;
          const refinedWords = providerResult.refinedText.trim().split(/\s+/).filter(Boolean).length;

          let finalRefinedText = cleanWisprFlowText(providerResult.refinedText, {
            removeTrailingPeriod: parsed.data.mode === 'mammals',
          });

          const responsePayload: RefineResponse = {
            success: true,
            refinedText: finalRefinedText,
            mode: parsed.data.mode,
            tone: parsed.data.tone,
            synonymLevel: parsed.data.synonymLevel,
            stats: {
              originalWords,
              originalChars: parsed.data.text.length,
              refinedWords,
              refinedChars: providerResult.refinedText.length,
              latencyMs,
            },
            provider: providerResult.provider,
            model: providerResult.model,
            alternatives: providerResult.alternatives,
            issues: providerResult.issues,
          };

          return jsonResponse(responsePayload, 200, origin);
        } catch (err: any) {
          const isConfig = err.message.includes('CONFIGURATION_REQUIRED');
          return errorResponse(
            isConfig ? 'CONFIGURATION_REQUIRED' : 'PROVIDER_ERROR',
            err.message,
            isConfig ? 503 : 500,
            null,
            origin
          );
        }
      }

      // 5. AI CONTENT DETECTION
      if (url.pathname === '/api/v1/ai/detect' && request.method === 'POST') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        let rawBody: any;
        try {
          rawBody = await request.json();
        } catch {
          return errorResponse('INVALID_INPUT', 'Malformed JSON body in request', 400, null, origin);
        }

        const parsed = DetectAiSchema.safeParse(rawBody);
        if (!parsed.success) {
          return errorResponse('INVALID_INPUT', 'Validation failed for detect parameters', 422, parsed.error.errors, origin);
        }

        try {
          const result = await detectAiContent(parsed.data, env);
          return jsonResponse(result, 200, origin);
        } catch (err: any) {
          return errorResponse('PROVIDER_ERROR', err?.message || 'Detection failed', 500, null, origin);
        }
      }

      // 6. SCHOLARLY CITATION GENERATION
      if (url.pathname === '/api/v1/ai/citation' && request.method === 'POST') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        let rawBody: any;
        try {
          rawBody = await request.json();
        } catch {
          return errorResponse('INVALID_INPUT', 'Malformed JSON body in request', 400, null, origin);
        }

        const parsed = CitationSchema.safeParse(rawBody);
        if (!parsed.success) {
          return errorResponse('INVALID_INPUT', 'Validation failed for citation parameters', 422, parsed.error.errors, origin);
        }

        try {
          const result = await generateCitation(parsed.data, env);
          return jsonResponse(result, 200, origin);
        } catch (err: any) {
          return errorResponse('PROVIDER_ERROR', err?.message || 'Citation generation failed', 500, null, origin);
        }
      }

      // 7. DICTIONARY DEFINITION & MEANING ENGINE
      if (url.pathname === '/api/v1/ai/dictionary/define' && request.method === 'POST') {
        const { user, error: authError } = await authenticateRequest(request, env);
        if (authError || !user) {
          return errorResponse('UNAUTHORIZED', authError || 'Authentication required', 401, null, origin);
        }

        let rawBody: any;
        try {
          rawBody = await request.json();
        } catch {
          return errorResponse('INVALID_INPUT', 'Malformed JSON body in request', 400, null, origin);
        }

        const parsed = DictionarySchema.safeParse(rawBody);
        if (!parsed.success) {
          return errorResponse('INVALID_INPUT', 'Validation failed for dictionary parameters', 422, parsed.error.errors, origin);
        }

        try {
          const result = await lookupWordDefinition(parsed.data, env);
          return jsonResponse(result, 200, origin);
        } catch (err: any) {
          return errorResponse('PROVIDER_ERROR', err?.message || 'Dictionary lookup failed', 500, null, origin);
        }
      }

      // Route Not Found
      return errorResponse('NOT_FOUND', `Route not found: ${request.method} ${url.pathname}`, 404, null, origin);
    } catch (err: any) {
      return errorResponse('INTERNAL_ERROR', err?.message || 'Unexpected server error', 500, null, origin);
    }
  },
};
