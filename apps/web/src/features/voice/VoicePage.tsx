import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Mic, ArrowRight, RotateCcw, Volume2, Globe } from 'lucide-react';
import { VoiceModal } from './VoiceModal.js';

export const VoicePage: React.FC = () => {
  const navigate = useNavigate();
  const [isModalOpen, setIsModalOpen] = useState(true);
  const [lastTranscript, setLastTranscript] = useState('');

  const handleTranscriptReady = (text: string) => {
    setLastTranscript(text);
    sessionStorage.setItem('sayn-voice-draft', text);
    navigate('/workspace');
  };

  const handleGoToWorkspace = () => {
    sessionStorage.setItem('sayn-voice-draft', lastTranscript);
    navigate('/workspace');
  };

  return (
    <div className="flex-1 max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8 flex flex-col items-center justify-center">
      <div className="text-center max-w-lg mb-8">
        <div className="w-16 h-16 rounded-full bg-sayn-dark-accent/15 border border-sayn-dark-accent/30 text-sayn-dark-accent flex items-center justify-center mx-auto mb-4">
          <Mic className="w-8 h-8 text-sayn-audio" />
        </div>
        <h1 className="text-2xl font-bold tracking-tight text-sayn-dark-text mb-2">
          Voice Dictation Studio
        </h1>
        <p className="text-xs sm:text-sm text-sayn-dark-secondary">
          Speak your thoughts naturally. SAYN transcribes, punctuates, and refines them into articulate writing.
        </p>
      </div>

      {lastTranscript ? (
        <div className="w-full max-w-lg p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4">
          <div className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted">
            Captured Speech
          </div>
          <div className="p-4 rounded-ios-sm bg-sayn-dark-surface2 text-sm text-sayn-dark-text leading-relaxed">
            "{lastTranscript}"
          </div>
          <div className="flex items-center justify-between pt-2">
            <button
              onClick={() => setIsModalOpen(true)}
              className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-ios-sm text-xs font-medium text-sayn-dark-secondary hover:text-sayn-dark-text border border-sayn-dark-divider"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Record Again</span>
            </button>
            <button
              onClick={handleGoToWorkspace}
              className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-ios-sm text-xs font-semibold text-white bg-sayn-dark-accent hover:opacity-90"
            >
              <span>Refine in Workspace</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      ) : (
        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center space-x-2 px-6 py-3 rounded-ios-sm text-sm font-semibold text-white bg-sayn-dark-accent hover:opacity-90 shadow-md transition-all active:scale-95"
        >
          <Mic className="w-4 h-4 text-sayn-audio" />
          <span>Launch Microphone</span>
        </button>
      )}

      <VoiceModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onTranscriptReady={handleTranscriptReady}
      />
    </div>
  );
};
