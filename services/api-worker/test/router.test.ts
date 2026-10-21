import { describe, it, expect } from 'vitest';
import worker from '../src/index.js';
import { Env } from '../src/types.js';

describe('SAYN Cloudflare Worker AI Gateway', () => {
  const mockEnv: Env = {
    ENVIRONMENT: 'development',
    DEFAULT_AI_PROVIDER: 'gemini',
  };

  it('handles CORS OPTIONS preflight', async () => {
    const request = new Request('http://localhost/api/v1/health', {
      method: 'OPTIONS',
      headers: { Origin: 'http://localhost:5173' },
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(204);
    expect(response.headers.get('Access-Control-Allow-Origin')).toBe('http://localhost:5173');
  });

  it('returns health check status', async () => {
    const request = new Request('http://localhost/api/v1/health', {
      method: 'GET',
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(200);

    const body: any = await response.json();
    expect(body.status).toBe('ok');
    expect(body.version).toBe('1.0.0');
    expect(body.aiProviderConfigured).toBe(true);
    expect(body.activeProvider).toBe('sayn-builtin');
  });

  it('rejects empty input text with validation error', async () => {
    const request = new Request('http://localhost/api/v1/ai/refine', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer test-token',
      },
      body: JSON.stringify({
        text: '',
        mode: 'grammar',
      }),
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(422);

    const body: any = await response.json();
    expect(body.success).toBe(false);
    expect(body.error.code).toBe('INVALID_INPUT');
  });

  it('refines text successfully using BuiltinEngine when no external AI keys are configured', async () => {
    const request = new Request('http://localhost/api/v1/ai/refine', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer test-token',
      },
      body: JSON.stringify({
        text: 'hello world this is a test',
        mode: 'grammar',
      }),
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(200);

    const body: any = await response.json();
    expect(body.success).toBe(true);
    expect(body.refinedText).toBe('Hello world this is a test.');
    expect(body.provider).toBe('SAYN Core Engine');
  });

  it('accepts synonymLevel and freezeWords in refine request', async () => {
    const request = new Request('http://localhost/api/v1/ai/refine', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer test-token',
      },
      body: JSON.stringify({
        text: 'we should definitely schedule a meeting with Supabase tomorrow',
        mode: 'professional',
        synonymLevel: 3,
        freezeWords: ['Supabase'],
      }),
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(200);

    const body: any = await response.json();
    expect(body.success).toBe(true);
    expect(body.synonymLevel).toBe(3);
  });

  it('detects AI content via heuristic fallback', async () => {
    const request = new Request('http://localhost/api/v1/ai/detect', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer test-token',
      },
      body: JSON.stringify({
        text: 'Furthermore, it is a testament to human ingenuity to delve into the tapestry of modern software architecture.',
      }),
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(200);

    const body: any = await response.json();
    expect(body.success).toBe(true);
    expect(body.overallAiPercentage).toBeGreaterThanOrEqual(50);
    expect(body.sentences.length).toBeGreaterThan(0);
    expect(body.verdict).toBeDefined();
  });

  it('generates academic citations in APA format', async () => {
    const request = new Request('http://localhost/api/v1/ai/citation', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer test-token',
      },
      body: JSON.stringify({
        sourceTextOrUrl: 'https://en.wikipedia.org/wiki/Artificial_intelligence',
        style: 'apa',
      }),
    });

    const response = await worker.fetch(request, mockEnv, {} as ExecutionContext);
    expect(response.status).toBe(200);

    const body: any = await response.json();
    expect(body.success).toBe(true);
    expect(body.style).toBe('apa');
    expect(body.fullCitation).toContain('wikipedia.org');
    expect(body.inTextCitation).toBeDefined();
  });
});
