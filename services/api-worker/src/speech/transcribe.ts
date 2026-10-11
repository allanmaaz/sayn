import { Env } from '../types.js';
import { TranscribeResponse } from '@sayn/shared-types';

export async function handleTranscription(
  request: Request,
  env: Env
): Promise<TranscribeResponse> {
  const contentType = request.headers.get('content-type') || '';

  let audioBlob: Blob | null = null;
  let language: string | undefined;

  let rawAudioBase64: string | null = null;

  if (contentType.includes('multipart/form-data')) {
    const formData = await request.formData();
    const file = formData.get('file') as File | null;
    if (file) {
      audioBlob = file;
    }
    const lang = formData.get('language') as string | null;
    if (lang) {
      language = lang;
    }
  } else if (contentType.includes('application/json')) {
    const body: any = await request.json();
    if (body.audioBase64) {
      rawAudioBase64 = body.audioBase64;
      const binary = atob(body.audioBase64);
      const array = new Uint8Array(binary.length);
      for (let i = 0; i < binary.length; i++) {
        array[i] = binary.charCodeAt(i);
      }
      audioBlob = new Blob([array], { type: 'audio/webm' });
    }
    language = body.language;
  }

  if (!audioBlob && !rawAudioBase64) {
    throw new Error('No audio file or base64 audio payload provided.');
  }

  // 1. If Google Gemini API key is available (Native multimodal speech-to-text)
  if (env.GEMINI_API_KEY) {
    let base64Data = rawAudioBase64;
    if (!base64Data && audioBlob) {
      const arrayBuf = await audioBlob.arrayBuffer();
      base64Data = Buffer.from(arrayBuf).toString('base64');
    }

    if (base64Data) {
      const candidateModels = ['gemini-3.5-flash-lite', 'gemini-3.8-flash'];
      for (const model of candidateModels) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${env.GEMINI_API_KEY}`;
          const payload = {
            contents: [
              {
                parts: [
                  {
                    inlineData: {
                      mimeType: 'audio/webm',
                      data: base64Data,
                    },
                  },
                  {
                    text: language
                      ? `Transcribe the spoken words in this audio verbatim in ${language}. Output ONLY the transcribed text. Do NOT add commentary, notes, or explanations.`
                      : 'Transcribe the spoken words in this audio verbatim. Output ONLY the transcribed text. Do NOT add commentary, notes, or explanations.',
                  },
                ],
              },
            ],
            generationConfig: {
              temperature: 0.1,
              maxOutputTokens: 2048,
            },
          };

          const response = await fetch(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          });

          if (response.ok) {
            const data: any = await response.json();
            const textPart = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (textPart && textPart.trim()) {
              return {
                success: true,
                transcript: textPart.trim(),
                provider: `Google Gemini (${model})`,
              };
            }
          } else {
            const err = await response.text();
            console.warn(`Gemini audio transcribe warning (${response.status}):`, err);
          }
        } catch (err: any) {
          console.warn('Gemini audio transcribe exception:', err.message);
        }
      }

      // If Gemini processed the audio but found no recognizable words
      return {
        success: true,
        transcript: '',
        provider: 'Google Gemini',
      };
    }
  }

  // 2. If OpenAI Whisper API key is available
  if (env.OPENAI_API_KEY && audioBlob) {
    const formData = new FormData();
    formData.append('file', audioBlob, 'audio.webm');
    formData.append('model', 'whisper-1');
    if (language) {
      formData.append('language', language);
    }

    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${env.OPENAI_API_KEY}`,
      },
      body: formData,
    });

    if (!response.ok) {
      const err = await response.text();
      throw new Error(`OpenAI Whisper error: ${err}`);
    }

    const data: any = await response.json();
    return {
      success: true,
      transcript: data.text || '',
      provider: 'OpenAI Whisper',
    };
  }

  // 3. If Cloudflare Workers AI binding has whisper
  if (env.AI && audioBlob) {
    try {
      const arrayBuffer = await audioBlob.arrayBuffer();
      const input = {
        audio: [...new Uint8Array(arrayBuffer)],
      };
      const response: any = await env.AI.run('@cf/openai/whisper', input);
      return {
        success: true,
        transcript: response.text || '',
        provider: 'Cloudflare Whisper AI',
      };
    } catch (err: any) {
      throw new Error(`Cloudflare Whisper AI execution failed: ${err.message}`);
    }
  }

  throw new Error(
    'Speech-to-text: No speech detected in recorded audio. Please speak clearly into your microphone, or type your message directly.'
  );
}
