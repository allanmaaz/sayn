import {
  HealthCheckResponse,
  RefineRequest,
  RefineResponse,
  TranscribeResponse,
  UsageStatusResponse,
} from '@sayn/shared-types';

const API_BASE_URL = import.meta.env.VITE_API_GATEWAY_URL || '';

export class SaynApiClient {
  private token: string | null = null;

  setToken(token: string | null) {
    this.token = token;
  }

  private async request<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const url = `${API_BASE_URL.replace(/\/$/, '')}${endpoint}`;
    const headers = new Headers(options.headers || {});

    if (this.token) {
      headers.set('Authorization', `Bearer ${this.token}`);
    }

    if (!headers.has('Content-Type') && !(options.body instanceof FormData)) {
      headers.set('Content-Type', 'application/json');
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (!response.ok) {
      let errorMsg = `API Error (${response.status})`;
      try {
        const errorJson = await response.json();
        if (errorJson.error?.message) {
          errorMsg = errorJson.error.message;
        }
      } catch {
        const text = await response.text();
        if (text) errorMsg = text;
      }
      throw new Error(errorMsg);
    }

    return response.json() as Promise<T>;
  }

  async checkHealth(): Promise<HealthCheckResponse> {
    return this.request<HealthCheckResponse>('/api/v1/health', { method: 'GET' });
  }

  async getUsageStatus(): Promise<UsageStatusResponse> {
    return this.request<UsageStatusResponse>('/api/v1/usage', { method: 'GET' });
  }

  async refineText(payload: RefineRequest): Promise<RefineResponse> {
    return this.request<RefineResponse>('/api/v1/ai/refine', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  }

  async transcribeAudio(audioBase64: string, language?: string): Promise<TranscribeResponse> {
    return this.request<TranscribeResponse>('/api/v1/ai/transcribe', {
      method: 'POST',
      body: JSON.stringify({ audioBase64, language }),
    });
  }
}

export const apiClient = new SaynApiClient();
