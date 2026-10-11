import React, { useState, useEffect } from 'react';
import {
  WRITING_MODES,
  WritingMode,
  WritingTone,
  RefineResponse,
} from '@sayn/shared-types';
import { apiClient } from '../../services/api.js';
import { DiffViewer } from '../../components/ui/DiffViewer.js';
import { VoiceModal } from '../voice/VoiceModal.js';
import {
  Mic,
  Copy,
  Check,
  RotateCcw,
  Sliders,
  Layers,
  ArrowRightLeft,
  Trash2,
  ClipboardPaste,
  Sparkles,
  AlertCircle,
  HelpCircle,
} from 'lucide-react';

export const WorkspacePage: React.FC = () => {
  const [sourceText, setSourceText] = useState('');
  const [refinedText, setRefinedText] = useState('');
  const [selectedMode, setSelectedMode] = useState<WritingMode>('standard');
  const [selectedTone, setSelectedTone] = useState<WritingTone>('neutral');
  const [targetLanguage, setTargetLanguage] = useState('Spanish');
  const [customInstruction, setCustomInstruction] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [showDiff, setShowDiff] = useState(false);
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [lastStats, setLastStats] = useState<RefineResponse['stats'] | null>(null);
  const [providerInfo, setProviderInfo] = useState<string | null>(null);

  // Live counts
  const wordCount = sourceText.trim() ? sourceText.trim().split(/\s+/).length : 0;
  const charCount = sourceText.length;

  // Load drafted transcript from Voice Studio if navigated here
  useEffect(() => {
    const draft = sessionStorage.getItem('sayn-voice-draft');
    if (draft) {
      setSourceText(draft);
      sessionStorage.removeItem('sayn-voice-draft');
    }
  }, []);

  const handleClear = () => {
    if (sourceText.length > 50 && !window.confirm('Clear your text?')) {
      return;
    }
    setSourceText('');
    setRefinedText('');
    setError(null);
    setLastStats(null);
  };

  const handlePaste = async () => {
    try {
      const text = await navigator.clipboard.readText();
      if (text) {
        setSourceText((prev) => (prev ? prev + '\n' + text : text));
      }
    } catch {
      setError('Could not access clipboard. Please paste manually.');
    }
  };

  const handleCopy = async () => {
    if (!refinedText) return;
    try {
      await navigator.clipboard.writeText(refinedText);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      setError('Failed to copy to clipboard.');
    }
  };

  const handleReplaceInput = () => {
    if (!refinedText) return;
    setSourceText(refinedText);
  };

  const handleRefine = async () => {
    if (!sourceText.trim()) {
      setError('Please enter or dictate some text to refine.');
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const res = await apiClient.refineText({
        text: sourceText,
        mode: selectedMode,
        tone: selectedTone,
        targetLanguage: selectedMode === 'translate' ? targetLanguage : undefined,
        customInstruction: selectedMode === 'custom' ? customInstruction : undefined,
      });

      setRefinedText(res.refinedText);
      setLastStats(res.stats);
      setProviderInfo(`${res.provider} (${res.model})`);

      // Store in writing history if enabled
      const historyEnabled = localStorage.getItem('sayn-history-enabled') !== 'false';
      if (historyEnabled) {
        const existingHistory = JSON.parse(localStorage.getItem('sayn-history') || '[]');
        const newEntry = {
          id: Date.now().toString(),
          source_text: sourceText,
          result_text: res.refinedText,
          writing_mode: selectedMode,
          created_at: new Date().toISOString(),
        };
        localStorage.setItem('sayn-history', JSON.stringify([newEntry, ...existingHistory.slice(0, 49)]));
      }
    } catch (err: any) {
      setError(err.message || 'An error occurred while refining your text.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-6">
      {/* Top Workspace Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text">
            Writing Workspace
          </h1>
          <p className="text-xs sm:text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary mt-0.5">
            Speak or type naturally, refine with precision, and communicate with clarity.
          </p>
        </div>

        {/* Global Dictate & Actions Button */}
        <div className="flex items-center space-x-2">
          <button
            onClick={() => setIsVoiceOpen(true)}
            className="inline-flex items-center space-x-2 px-3.5 py-2 rounded-ios-sm text-xs font-semibold text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider hover:border-sayn-dark-accent transition-all"
          >
            <Mic className="w-4 h-4 text-sayn-audio" />
            <span>Voice Dictation</span>
          </button>
        </div>
      </div>

      {/* Writing Modes Pill Selector */}
      <div className="mb-6">
        <label className="block text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-2">
          Refinement Mode
        </label>
        <div className="flex items-center gap-1.5 overflow-x-auto pb-2 scrollbar-none">
          {Object.values(WRITING_MODES).map((mode) => {
            const isSelected = selectedMode === mode.id;
            return (
              <button
                key={mode.id}
                onClick={() => setSelectedMode(mode.id)}
                className={`px-3 py-1.5 rounded-ios-pill text-xs font-medium whitespace-nowrap transition-all ${
                  isSelected
                    ? 'bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent text-white shadow-sm'
                    : 'bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider hover:text-sayn-dark-text'
                }`}
              >
                {mode.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Mode Extra Options (Tone, Translation Language, or Custom Prompt) */}
      <div className="mb-6 flex flex-wrap items-center gap-4 p-3 rounded-ios-sm bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-xs">
        {/* Tone Selector */}
        <div className="flex items-center space-x-2">
          <span className="text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted font-medium">
            Tone:
          </span>
          <select
            value={selectedTone}
            onChange={(e) => setSelectedTone(e.target.value as WritingTone)}
            className="px-2.5 py-1 rounded-ios-sm bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider text-sayn-dark-text focus:outline-none"
          >
            <option value="neutral">Neutral (Default)</option>
            <option value="professional">Professional</option>
            <option value="casual">Casual</option>
            <option value="friendly">Friendly</option>
            <option value="confident">Confident</option>
            <option value="academic">Academic</option>
            <option value="direct">Direct & Punchy</option>
          </select>
        </div>

        {/* Translation Language Selector */}
        {selectedMode === 'translate' && (
          <div className="flex items-center space-x-2">
            <span className="text-sayn-dark-muted font-medium">Target Language:</span>
            <select
              value={targetLanguage}
              onChange={(e) => setTargetLanguage(e.target.value)}
              className="px-2.5 py-1 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text focus:outline-none"
            >
              <option value="Spanish">Spanish</option>
              <option value="French">French</option>
              <option value="German">German</option>
              <option value="Italian">Italian</option>
              <option value="Japanese">Japanese</option>
              <option value="Hindi">Hindi</option>
              <option value="Portuguese">Portuguese</option>
              <option value="Chinese (Simplified)">Chinese (Simplified)</option>
            </select>
          </div>
        )}

        {/* Custom Instruction Box */}
        {selectedMode === 'custom' && (
          <div className="flex-1 min-w-[240px]">
            <input
              type="text"
              value={customInstruction}
              onChange={(e) => setCustomInstruction(e.target.value)}
              placeholder="e.g., Rewrite so it sounds courteous but firm..."
              className="w-full px-3 py-1 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text placeholder:text-sayn-dark-muted focus:outline-none focus:border-sayn-dark-accent"
            />
          </div>
        )}

        <div className="ml-auto text-sayn-dark-muted text-[11px] hidden sm:block">
          {WRITING_MODES[selectedMode]?.description}
        </div>
      </div>

      {/* Editor & Output Dual-Pane */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
        {/* Left Column: Source Text Area */}
        <div className="flex flex-col rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider overflow-hidden transition-colors">
          <div className="flex items-center justify-between px-4 py-3 border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-xs">
            <div className="flex items-center space-x-2 text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary font-medium">
              <span>Source Text</span>
            </div>
            <div className="flex items-center space-x-2">
              <button
                onClick={handlePaste}
                className="p-1.5 rounded-ios-sm text-sayn-dark-secondary hover:text-sayn-dark-text hover:bg-sayn-dark-surface2 transition-colors"
                title="Paste from clipboard"
              >
                <ClipboardPaste className="w-3.5 h-3.5" />
              </button>
              {sourceText && (
                <button
                  onClick={handleClear}
                  className="p-1.5 rounded-ios-sm text-sayn-dark-secondary hover:text-sayn-dark-error hover:bg-sayn-dark-surface2 transition-colors"
                  title="Clear text"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          </div>

          <textarea
            value={sourceText}
            onChange={(e) => setSourceText(e.target.value)}
            placeholder="Type, paste, or dictate what you want to communicate..."
            rows={12}
            className="w-full p-4 bg-transparent text-sm leading-relaxed text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text placeholder:text-sayn-dark-muted dark:placeholder:text-sayn-dark-muted light:placeholder:text-sayn-light-muted resize-none focus:outline-none"
          />

          <div className="flex items-center justify-between px-4 py-3 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted">
            <div className="space-x-3">
              <span>{wordCount} {wordCount === 1 ? 'word' : 'words'}</span>
              <span>•</span>
              <span>{charCount} characters</span>
            </div>
            <button
              onClick={handleRefine}
              disabled={isLoading || !sourceText.trim()}
              className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-ios-sm text-xs font-semibold text-white bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent hover:opacity-90 disabled:opacity-40 disabled:cursor-not-allowed transition-all shadow-sm"
            >
              {isLoading ? (
                <>
                  <div className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Refining...</span>
                </>
              ) : (
                <>
                  <span>Refine Text</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Right Column: Refined Output Area */}
        <div className="flex flex-col rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider overflow-hidden transition-colors">
          <div className="flex items-center justify-between px-4 py-3 border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-xs">
            <div className="flex items-center space-x-2 text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent font-medium">
              <span>Refined Result</span>
              {providerInfo && (
                <span className="text-[10px] text-sayn-dark-muted font-normal">
                  ({providerInfo})
                </span>
              )}
            </div>

            {refinedText && (
              <div className="flex items-center space-x-1.5">
                <button
                  onClick={() => setShowDiff(!showDiff)}
                  className={`px-2.5 py-1 rounded-ios-sm text-xs font-medium border transition-colors ${
                    showDiff
                      ? 'bg-sayn-dark-surface2 text-sayn-dark-accent border-sayn-dark-accent'
                      : 'text-sayn-dark-secondary border-sayn-dark-divider hover:text-sayn-dark-text'
                  }`}
                >
                  <span className="flex items-center space-x-1">
                    <Layers className="w-3 h-3" />
                    <span>Compare</span>
                  </span>
                </button>
                <button
                  onClick={handleReplaceInput}
                  className="px-2.5 py-1 rounded-ios-sm text-xs font-medium text-sayn-dark-secondary border border-sayn-dark-divider hover:text-sayn-dark-text transition-colors"
                  title="Replace source with this result"
                >
                  <span className="flex items-center space-x-1">
                    <ArrowRightLeft className="w-3 h-3" />
                    <span>Replace Input</span>
                  </span>
                </button>
              </div>
            )}
          </div>

          <div className="relative min-h-[300px]">
            {showDiff && refinedText ? (
              <div className="p-4">
                <DiffViewer original={sourceText} refined={refinedText} />
              </div>
            ) : (
              <textarea
                readOnly
                value={refinedText}
                placeholder={
                  isLoading
                    ? 'Refining your text with precision...'
                    : 'The refined output will appear here. Tap Refine Text to transform.'
                }
                rows={12}
                className="w-full p-4 bg-transparent text-sm leading-relaxed text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text placeholder:text-sayn-dark-muted dark:placeholder:text-sayn-dark-muted light:placeholder:text-sayn-light-muted resize-none focus:outline-none"
              />
            )}
          </div>

          <div className="flex items-center justify-between px-4 py-3 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted">
            <div>
              {lastStats && (
                <div className="space-x-3 text-[11px]">
                  <span>{lastStats.refinedWords} words</span>
                  <span>•</span>
                  <span>{lastStats.latencyMs}ms</span>
                </div>
              )}
            </div>

            <div className="flex items-center space-x-2">
              {refinedText && (
                <>
                  <button
                    onClick={handleRefine}
                    disabled={isLoading}
                    className="p-1.5 rounded-ios-sm text-sayn-dark-secondary hover:text-sayn-dark-text hover:bg-sayn-dark-surface2 transition-colors"
                    title="Regenerate"
                  >
                    <RotateCcw className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={handleCopy}
                    className={`inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-ios-sm text-xs font-medium transition-all ${
                      copied
                        ? 'bg-sayn-dark-success text-white'
                        : 'bg-sayn-dark-surface2 text-sayn-dark-text hover:bg-sayn-dark-accent hover:text-white border border-sayn-dark-divider'
                    }`}
                  >
                    {copied ? (
                      <>
                        <Check className="w-3.5 h-3.5" />
                        <span>Copied</span>
                      </>
                    ) : (
                      <>
                        <Copy className="w-3.5 h-3.5" />
                        <span>Copy Output</span>
                      </>
                    )}
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Error / Setup Notice Box */}
      {error && (
        <div className="mt-6 p-4 rounded-ios-sm bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-error/40 text-xs text-sayn-dark-error flex items-start space-x-3">
          <AlertCircle className="w-5 h-5 shrink-0 mt-0.5" />
          <div className="flex-1 space-y-1">
            <div className="font-semibold text-sm">Action Required</div>
            <p className="text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary leading-relaxed">
              {error}
            </p>
          </div>
        </div>
      )}

      {/* Voice Dictation Studio Modal */}
      <VoiceModal
        isOpen={isVoiceOpen}
        onClose={() => setIsVoiceOpen(false)}
        onTranscriptReady={(transcript) => {
          setSourceText((prev) => (prev ? prev + ' ' + transcript : transcript));
        }}
      />
    </div>
  );
};
