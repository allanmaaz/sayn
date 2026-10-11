import React, { useState, useEffect, useRef } from 'react';
import { Mic, Square, X, ArrowRight, RotateCcw, AlertCircle, RefreshCw } from 'lucide-react';
import { apiClient } from '../../services/api.js';

interface VoiceModalProps {
  isOpen: boolean;
  onClose: () => void;
  onTranscriptReady: (transcript: string) => void;
}

export const VoiceModal: React.FC<VoiceModalProps> = ({
  isOpen,
  onClose,
  onTranscriptReady,
}) => {
  const [isRecording, setIsRecording] = useState(false);
  const [isTranscribingServer, setIsTranscribingServer] = useState(false);
  const [isUsingAudioFallback, setIsUsingAudioFallback] = useState(false);
  const [transcript, setTranscript] = useState('');
  const [duration, setDuration] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [selectedLanguage, setSelectedLanguage] = useState('en-US');

  const recognitionRef = useRef<any>(null);
  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksListRef = useRef<Blob[]>([]);
  const timerRef = useRef<any>(null);
  const intentionalStopRef = useRef(false);

  useEffect(() => {
    if (!isOpen) {
      stopRecording();
      setTranscript('');
      setDuration(0);
      setError(null);
      setIsUsingAudioFallback(false);
    }
  }, [isOpen]);

  const startRecording = async () => {
    setError(null);
    setTranscript('');
    setDuration(0);
    setIsUsingAudioFallback(false);
    intentionalStopRef.current = false;
    audioChunksListRef.current = [];

    // 1. Request microphone access via getUserMedia for reliable audio capture & permissions
    let mediaStream: MediaStream | null = null;
    try {
      if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
        mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
        const mediaRecorder = new MediaRecorder(mediaStream);
        mediaRecorder.ondataavailable = (e) => {
          if (e.data.size > 0) {
            audioChunksListRef.current.push(e.data);
          }
        };
        mediaRecorderRef.current = mediaRecorder;
        mediaRecorder.start(250);
      }
    } catch (err: any) {
      if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
        setError('Microphone permission was denied. Please allow microphone access in your browser address bar.');
        return;
      }
    }

    // 2. Initialize Web Speech API
    const SpeechRecognition =
      (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

    if (!SpeechRecognition) {
      // If Web Speech API is absent (e.g. Firefox), use MediaRecorder audio + Gemini transcribe
      if (mediaStream) {
        setIsRecording(true);
        setIsUsingAudioFallback(true);
        timerRef.current = setInterval(() => setDuration((prev) => prev + 1), 1000);
        return;
      }
      setError('Speech recording is not supported in this browser. Please use Chrome, Brave, Safari, or Edge.');
      return;
    }

    try {
      const recognition = new SpeechRecognition();
      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.lang = selectedLanguage;

      recognition.onstart = () => {
        setIsRecording(true);
        if (!timerRef.current) {
          timerRef.current = setInterval(() => {
            setDuration((prev) => prev + 1);
          }, 1000);
        }
      };

      recognition.onresult = (event: any) => {
        let currentText = '';
        for (let i = 0; i < event.results.length; i++) {
          currentText += event.results[i][0].transcript;
        }
        setTranscript(currentText);
      };

      recognition.onerror = (event: any) => {
        // 'no-speech': User hasn't spoken yet; keep recording alive!
        if (event.error === 'no-speech') {
          return;
        }

        // 'aborted': User clicked stop or cancel, normal event
        if (event.error === 'aborted') {
          return;
        }

        if (event.error === 'network') {
          // Brave browser or privacy shield blocks Google speech servers.
          // MediaRecorder is recording audio; we will auto-transcribe with Gemini upon stopping!
          setIsUsingAudioFallback(true);
          return;
        }

        if (event.error === 'not-allowed') {
          setError('Microphone access was denied. Please allow microphone access in your browser settings.');
          stopRecording();
          return;
        }

        if (event.error === 'audio-capture') {
          setError('No microphone was detected. Please check your audio input settings.');
          stopRecording();
          return;
        }

        console.warn('Speech recognition notice:', event.error);
      };

      recognition.onend = () => {
        // If not intentionally stopped and still recording, restart recognition
        if (!intentionalStopRef.current && isRecording) {
          try {
            recognition.start();
          } catch {
            // ignore
          }
        }
      };

      recognitionRef.current = recognition;
      recognition.start();
      setIsRecording(true);

      if (!timerRef.current) {
        timerRef.current = setInterval(() => {
          setDuration((prev) => prev + 1);
        }, 1000);
      }
    } catch (err: any) {
      console.warn('Recognition init note:', err);
    }
  };

  const stopRecording = () => {
    intentionalStopRef.current = true;
    if (recognitionRef.current) {
      try {
        recognitionRef.current.stop();
      } catch {}
      recognitionRef.current = null;
    }

    if (mediaRecorderRef.current && mediaRecorderRef.current.state !== 'inactive') {
      try {
        mediaRecorderRef.current.stop();
        mediaRecorderRef.current.stream.getTracks().forEach((track) => track.stop());
      } catch {}
    }

    setIsRecording(false);
    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }

    // Auto-transcribe with Gemini if Web Speech didn't populate (e.g. Brave)
    setTimeout(() => {
      if (!transcript.trim() && audioChunksListRef.current.length > 0) {
        handleTranscribeAudioFallback();
      }
    }, 350);
  };

  const handleTranscribeAudioFallback = async () => {
    if (audioChunksListRef.current.length === 0) {
      return;
    }

    setIsTranscribingServer(true);
    setError(null);

    try {
      const audioBlob = new Blob(audioChunksListRef.current, { type: 'audio/webm' });
      const reader = new FileReader();
      reader.readAsDataURL(audioBlob);
      reader.onloadend = async () => {
        const base64Audio = (reader.result as string).split(',')[1];
        try {
          const res = await apiClient.transcribeAudio(base64Audio, selectedLanguage);
          if (res.transcript) {
            setTranscript(res.transcript);
          } else {
            setError('Could not detect speech in audio clip.');
          }
        } catch (err: any) {
          setError(err.message || 'AI transcription failed.');
        } finally {
          setIsTranscribingServer(false);
        }
      };
    } catch (err: any) {
      setError(err.message || 'Failed to process audio.');
      setIsTranscribingServer(false);
    }
  };

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60).toString().padStart(2, '0');
    const s = (secs % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  };

  const handleUseTranscript = () => {
    if (transcript.trim()) {
      onTranscriptReady(transcript.trim());
      onClose();
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-150">
      <div className="relative w-full max-w-lg rounded-ios p-6 bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider shadow-2xl transition-colors">
        {/* Header */}
        <div className="flex items-center justify-between pb-4 border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
          <div className="flex items-center space-x-2">
            <Mic className="w-5 h-5 text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent" />
            <h3 className="font-semibold text-base text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text">
              Voice Dictation Studio
            </h3>
          </div>
          <button
            onClick={onClose}
            aria-label="Close modal"
            className="p-1.5 rounded-ios-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-text transition-colors"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Central Audio Recording Interface */}
        <div className="py-8 flex flex-col items-center justify-center text-center">
          {/* Main Record Control Button */}
          <div className="relative mb-6">
            <button
              onClick={isRecording ? stopRecording : startRecording}
              className={`w-20 h-20 rounded-full flex items-center justify-center transition-all ${
                isRecording
                  ? 'bg-sayn-dark-error text-white shadow-lg scale-105 animate-pulse'
                  : 'bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 text-sayn-dark-text hover:bg-sayn-dark-accent hover:text-white border border-sayn-dark-divider'
              }`}
            >
              {isRecording ? <Square className="w-7 h-7 fill-current" /> : <Mic className="w-8 h-8" />}
            </button>
          </div>

          {/* Restrained Cyan Waveform Visualization (strictly for audio activity) */}
          {isRecording ? (
            <div className="flex items-center space-x-1.5 h-10 mb-3">
              {[40, 75, 100, 60, 85, 45, 90, 70, 30].map((height, idx) => (
                <div
                  key={idx}
                  className="w-1 bg-sayn-audio rounded-full animate-bounce"
                  style={{
                    height: `${height}%`,
                    animationDelay: `${idx * 0.1}s`,
                    animationDuration: '0.8s',
                  }}
                />
              ))}
            </div>
          ) : (
            <p className="text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-3">
              Tap the microphone to speak naturally
            </p>
          )}

          {/* Duration Counter */}
          <div className="font-mono text-sm font-semibold tracking-wider text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
            {formatTime(duration)}
          </div>
        </div>

        {/* Error message */}
        {error && (
          <div className="mb-4 p-3 rounded-ios-sm bg-sayn-dark-error/10 border border-sayn-dark-error/30 text-sayn-dark-error text-xs flex items-start justify-between space-x-2">
            <div className="flex items-start space-x-2">
              <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
              <div className="leading-relaxed">{error}</div>
            </div>
            <button
              onClick={() => setError(null)}
              className="text-sayn-dark-muted hover:text-sayn-dark-text p-0.5"
              aria-label="Dismiss message"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Live Transcript Preview / Editable Area */}
        <div className="mb-6">
          <div className="flex items-center justify-between mb-2">
            <label className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted">
              Transcript / Spoken Text
            </label>
            {!isRecording && audioChunksListRef.current.length > 0 && (
              <button
                onClick={handleTranscribeAudioFallback}
                disabled={isTranscribingServer}
                className="text-[11px] text-sayn-dark-accent hover:underline flex items-center space-x-1 font-medium"
              >
                {isTranscribingServer ? (
                  <span>Transcribing with AI...</span>
                ) : (
                  <>
                    <RefreshCw className="w-3 h-3" />
                    <span>Transcribe Recorded Audio</span>
                  </>
                )}
              </button>
            )}
          </div>

          <textarea
            value={transcript}
            onChange={(e) => setTranscript(e.target.value)}
            rows={4}
            placeholder={
              isRecording
                ? 'Listening to speech... speak naturally into your microphone.'
                : 'Spoken text will appear here in real time. You can also type or edit directly.'
            }
            className="w-full p-3 rounded-ios-sm bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-sm text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text placeholder:text-sayn-dark-muted focus:outline-none focus:border-sayn-dark-accent resize-none transition-colors"
          />
        </div>


        {/* Footer Actions */}
        <div className="flex items-center justify-between pt-4 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
          <select
            value={selectedLanguage}
            onChange={(e) => setSelectedLanguage(e.target.value)}
            disabled={isRecording}
            className="px-2.5 py-1.5 rounded-ios-sm text-xs font-medium bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-sayn-dark-text focus:outline-none"
          >
            <option value="en-US">English (US)</option>
            <option value="en-GB">English (UK)</option>
            <option value="es-ES">Spanish</option>
            <option value="fr-FR">French</option>
            <option value="de-DE">German</option>
            <option value="hi-IN">Hindi</option>
          </select>

          <div className="flex items-center space-x-2">
            {transcript && (
              <button
                onClick={() => setTranscript('')}
                className="p-2 rounded-ios-sm text-sayn-dark-secondary hover:text-sayn-dark-text transition-colors"
                title="Reset"
              >
                <RotateCcw className="w-4 h-4" />
              </button>
            )}
            <button
              onClick={handleUseTranscript}
              disabled={!transcript.trim()}
              className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-ios-sm text-xs font-medium text-white bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent hover:opacity-90 disabled:opacity-40 disabled:cursor-not-allowed transition-all"
            >
              <span>Refine in Workspace</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
