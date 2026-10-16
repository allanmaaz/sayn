import React, { useState, useEffect, useMemo, useRef } from 'react';
import {
  WritingMode,
  WritingTone,
  SynonymIntensity,
  WordAlternative,
  GrammarIssue,
} from '@sayn/shared-types';
import { apiClient } from '../../services/api.js';
import { VoiceModal } from '../voice/VoiceModal.js';
import { SynonymPopover } from './SynonymPopover.js';
import { GrammarlyIssueCard } from './GrammarlyIssueCard.js';
import { ScoreMetricsDock } from './ScoreMetricsDock.js';
import {
  calculateDocumentMetrics,
  analyzeLocalGrammarIssues,
} from './readability.js';
import {
  Mic,
  FileText,
  Sparkles,
  Trash2,
  Copy,
  Check,
  Download,
  ArrowRight,
  ChevronDown,
  RotateCcw,
  Sliders,
  AlertCircle,
  X,
} from 'lucide-react';

/**
 * Custom 4-pointed AI Sparkle Star matching the official SAYN mockup
 */
const SparkleStarIcon: React.FC<{ className?: string }> = ({ className = 'w-12 h-12' }) => (
  <svg
    viewBox="0 0 48 48"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    className={className}
  >
    {/* Main 4-point star with pinched waist */}
    <path
      d="M24 4C24 15 15 24 4 24C15 24 24 33 24 44C24 33 33 24 44 24C33 24 24 15 24 4Z"
      stroke="currentColor"
      strokeWidth="2.2"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    {/* Satellite star top-right */}
    <path
      d="M38 6C38 9 36 11 33 11C36 11 38 13 38 16C38 13 40 11 43 11C40 11 38 9 38 6Z"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
    {/* Satellite star bottom-left */}
    <path
      d="M11 33C11 35.5 9.5 37 7 37C9.5 37 11 38.5 11 41C11 38.5 12.5 37 15 37C12.5 37 11 35.5 11 33Z"
      stroke="currentColor"
      strokeWidth="1.6"
      strokeLinecap="round"
      strokeLinejoin="round"
    />
  </svg>
);

export const WorkspacePage: React.FC = () => {
  const [sourceText, setSourceText] = useState('');
  const [refinedText, setRefinedText] = useState('');
  const [selectedMode, setSelectedMode] = useState<WritingMode>('standard');
  const [selectedTone, setSelectedTone] = useState<WritingTone>('neutral');
  // 0: Basic, 1: Medium, 2: Extreme (mapped to SynonymIntensity 0, 2, 4)
  const [synonymStep, setSynonymStep] = useState<number>(1);
  const [customInstruction, setCustomInstruction] = useState('');
  const [showCustomPrompt, setShowCustomPrompt] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [isInlineRecording, setIsInlineRecording] = useState(false);
  const [showAnalytics, setShowAnalytics] = useState(false);

  // Grammarly Issues state
  const [grammarIssues, setGrammarIssues] = useState<GrammarIssue[]>([]);
  // QuillBot Alternatives state
  const [wordAlternatives, setWordAlternatives] = useState<WordAlternative[]>([]);
  const [activeAlternative, setActiveAlternative] = useState<{
    alternative: WordAlternative;
    position: { top: number; left: number };
  } | null>(null);

  const recognitionRef = useRef<any>(null);

  // Performance metrics calculation
  const metrics = useMemo(() => {
    return calculateDocumentMetrics(sourceText, grammarIssues);
  }, [sourceText, grammarIssues]);

  const refinedWordsCount = useMemo(() => {
    if (!refinedText.trim()) return 0;
    return refinedText.trim().split(/\s+/).filter(Boolean).length;
  }, [refinedText]);

  // Run instant 0ms local heuristic grammar check whenever sourceText changes
  useEffect(() => {
    if (!sourceText.trim()) {
      setGrammarIssues([]);
      return;
    }
    const local = analyzeLocalGrammarIssues(sourceText);
    setGrammarIssues(local);
  }, [sourceText]);

  // Load drafted transcript if navigated from Voice Studio
  useEffect(() => {
    const draft = sessionStorage.getItem('sayn-voice-draft');
    if (draft) {
      setSourceText(draft);
      sessionStorage.removeItem('sayn-voice-draft');
    }
  }, []);

  // Keyboard shortcut listener for Voice Dictation (Fn / Option + V)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Fn' || (e.altKey && e.code === 'KeyV')) {
        e.preventDefault();
        setIsVoiceOpen((prev) => !prev);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, []);

  // Paraphrase execution using Groq LPU / Cloudflare
  const handleParaphrase = async () => {
    if (!sourceText.trim()) {
      setError('Please enter or dictate some text to refine.');
      return;
    }

    setIsLoading(true);
    setError(null);
    setActiveAlternative(null);

    const synonymLevel: SynonymIntensity = synonymStep === 0 ? 0 : synonymStep === 1 ? 2 : 4;

    try {
      const res = await apiClient.refineText({
        text: sourceText,
        mode: selectedMode,
        tone: selectedTone,
        synonymLevel,
        freezeWords: ['SAYN', 'API'],
        includeGrammarIssues: true,
        includeAlternatives: true,
        customInstruction: selectedMode === 'custom' ? customInstruction : undefined,
      });

      setRefinedText(res.refinedText);

      if (res.alternatives && res.alternatives.length > 0) {
        setWordAlternatives(res.alternatives);
      } else {
        generateClientAlternatives(sourceText, res.refinedText);
      }

      if (res.issues && res.issues.length > 0) {
        setGrammarIssues(res.issues);
      }
    } catch (err: any) {
      // Offline / fallback paraphraser
      const localResult = localParaphraseFallback(sourceText, synonymLevel);
      setRefinedText(localResult);
      generateClientAlternatives(sourceText, localResult);
    } finally {
      setIsLoading(false);
    }
  };

  // Client-side alternative synonym generator for interactive QuillBot word swaps
  const generateClientAlternatives = (orig: string, paraphrased: string) => {
    const origWords = orig.split(/\s+/);
    const paraWords = paraphrased.split(/\s+/);
    const alts: WordAlternative[] = [];

    const synonymsDict: Record<string, string[]> = {
      conclude: ['finish', 'end', 'wrap up', 'finalize', 'terminate'],
      finish: ['complete', 'conclude', 'finalize', 'wrap up'],
      complete: ['finalize', 'finish', 'achieve', 'fulfill'],
      meeting: ['session', 'conference', 'discussion', 'gathering'],
      important: ['crucial', 'essential', 'critical', 'vital', 'significant'],
      help: ['assist', 'support', 'aid', 'facilitate'],
      start: ['commence', 'initiate', 'launch', 'begin'],
      make: ['create', 'produce', 'generate', 'craft'],
      good: ['effective', 'beneficial', 'valuable', 'exceptional'],
      fast: ['rapid', 'swift', 'instant', 'quick', 'accelerated'],
      use: ['utilize', 'employ', 'leverage', 'adopt'],
    };

    paraWords.forEach((word, idx) => {
      const clean = word.toLowerCase().replace(/[^a-z]/g, '');
      const origWord = origWords[idx] || clean;
      if (synonymsDict[clean] && clean !== origWord.toLowerCase()) {
        alts.push({
          wordIndex: idx,
          originalWord: origWord,
          paraphrasedWord: word,
          synonyms: synonymsDict[clean],
        });
      }
    });

    setWordAlternatives(alts);
  };

  // Local fallback when offline
  const localParaphraseFallback = (text: string, level: number): string => {
    let out = text;
    const rules = [
      { from: /\bin order to\b/gi, to: 'to' },
      { from: /\butilize\b/gi, to: 'use' },
      { from: /\ba lot of\b/gi, to: 'numerous' },
      { from: /\bvery good\b/gi, to: 'exceptional' },
      { from: /\bfinish\b/gi, to: 'conclude' },
      { from: /\bmeeting\b/gi, to: 'session' },
      { from: /\bat this point in time\b/gi, to: 'currently' },
    ];

    const iterations = Math.min(rules.length, (level + 1) * 2);
    for (let i = 0; i < iterations; i++) {
      out = out.replace(rules[i].from, rules[i].to);
    }
    // Clean accidental underscores, double commas, and excessive punctuation
    out = out.replace(/_+/g, ' ');
    out = out.replace(/\s*,\s*,+/g, ',');
    out = out.replace(/\s+,/g, ',');
    out = out.replace(/\.{2,}/g, '.');
    return out.trim();
  };

  // Inline Dictation Toggle via Web Speech API
  const toggleInlineDictation = () => {
    if (isInlineRecording) {
      if (recognitionRef.current) {
        try {
          recognitionRef.current.stop();
        } catch {}
        recognitionRef.current = null;
      }
      setIsInlineRecording(false);
      return;
    }

    const SpeechRecognition =
      (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;

    if (!SpeechRecognition) {
      // Fallback to full VoiceModal
      setIsVoiceOpen(true);
      return;
    }

    try {
      const recognition = new SpeechRecognition();
      recognition.continuous = true;
      recognition.interimResults = true;
      recognition.lang = 'en-US';

      recognition.onstart = () => {
        setIsInlineRecording(true);
      };

      recognition.onresult = (event: any) => {
        let current = '';
        for (let i = 0; i < event.results.length; i++) {
          current += event.results[i][0].transcript;
        }
        setSourceText(current);
      };

      recognition.onerror = () => {
        setIsInlineRecording(false);
      };

      recognition.onend = () => {
        setIsInlineRecording(false);
      };

      recognitionRef.current = recognition;
      recognition.start();
    } catch {
      setIsVoiceOpen(true);
    }
  };

  // Grammarly Accept / Dismiss Handlers
  const handleAcceptIssue = (issue: GrammarIssue) => {
    const updated =
      sourceText.slice(0, issue.startOffset) +
      issue.suggestedReplacement +
      sourceText.slice(issue.endOffset);
    setSourceText(updated);
    setGrammarIssues((prev) => prev.filter((i) => i.id !== issue.id));
  };

  const handleDismissIssue = (issue: GrammarIssue) => {
    setGrammarIssues((prev) => prev.filter((i) => i.id !== issue.id));
  };

  const handleAcceptAllIssues = () => {
    if (grammarIssues.length === 0) return;
    let text = sourceText;
    const sorted = [...grammarIssues].sort((a, b) => b.startOffset - a.startOffset);
    for (const issue of sorted) {
      text =
        text.slice(0, issue.startOffset) +
        issue.suggestedReplacement +
        text.slice(issue.endOffset);
    }
    setSourceText(text);
    setGrammarIssues([]);
  };

  // QuillBot Substitute Synonym Swap
  const handleSwapWord = (newWord: string) => {
    if (!activeAlternative) return;
    const words = refinedText.split(/\s+/);
    if (words[activeAlternative.alternative.wordIndex]) {
      words[activeAlternative.alternative.wordIndex] = newWord;
      setRefinedText(words.join(' '));
    }
    setActiveAlternative(null);
  };

  const handleCopy = async () => {
    if (!refinedText) return;
    await navigator.clipboard.writeText(refinedText);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleExportText = () => {
    if (!refinedText) return;
    const blob = new Blob([refinedText], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `SAYN-Refined-${Date.now()}.txt`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <div className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-6 space-y-6">
      {/* Top Header Section */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD]">
            AI Studio
          </h1>
          <p className="text-xs sm:text-sm text-[#D6C7B2]/80 mt-1">
            Turn your rough thoughts into clear, refined writing.
          </p>
        </div>

        {/* Top-Right Voice Dictation Pill Button */}
        <button
          onClick={() => setIsVoiceOpen(true)}
          className="self-start sm:self-auto inline-flex items-center space-x-2 px-4 sm:px-5 py-2.5 rounded-full text-xs sm:text-sm font-semibold text-[#F5EBDD] bg-[#6F1025] hover:bg-[#8F1835] active:scale-95 shadow-[0_4px_16px_rgba(111,16,37,0.35)] transition-all"
        >
          <Mic className="w-4 h-4 stroke-[2.2]" />
          <span>Voice Dictation (Fn)</span>
        </button>
      </div>

      {/* Controls Horizontal Bar (Mode | Synonym Depth | Tone) */}
      <div className="p-3.5 sm:p-4 rounded-2xl bg-[#14080D] border border-[#2D1219] shadow-lg flex flex-col md:flex-row md:items-center justify-between gap-4">
        {/* Left Segment: Mode Selection */}
        <div className="flex items-center space-x-3">
          <span className="text-xs font-semibold text-[#8E8278]">Mode</span>
          <div className="flex items-center p-1 rounded-full bg-[#100709] border border-[#2D1219]">
            {(['standard', 'fluent', 'custom'] as const).map((mode) => {
              const isSelected = selectedMode === mode;
              const label =
                mode === 'standard' ? 'Standard' : mode === 'fluent' ? 'Fluent' : 'Custom';
              return (
                <button
                  key={mode}
                  onClick={() => {
                    setSelectedMode(mode);
                    if (mode === 'custom') {
                      setShowCustomPrompt(true);
                    } else {
                      setShowCustomPrompt(false);
                      if (sourceText.trim()) handleParaphrase();
                    }
                  }}
                  className={`px-4 py-1.5 rounded-full text-xs sm:text-sm font-medium transition-all ${
                    isSelected
                      ? 'bg-[#6F1025] text-[#F5EBDD] font-semibold shadow-sm'
                      : 'text-[#8E8278] hover:text-[#D6C7B2]'
                  }`}
                >
                  {label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Divider 1 */}
        <div className="hidden md:block h-7 w-[1px] bg-[#3D1520]" />

        {/* Center Segment: Synonym Depth Slider */}
        <div className="flex items-center space-x-3 sm:space-x-4">
          <span className="text-xs font-semibold text-[#8E8278] whitespace-nowrap">
            Synonym Depth
          </span>
          <div className="flex flex-col space-y-1.5 w-44 sm:w-56">
            {/* Range Track with white thumb */}
            <div className="relative flex items-center h-4 cursor-pointer select-none">
              <input
                type="range"
                min="0"
                max="2"
                step="1"
                value={synonymStep}
                onChange={(e) => {
                  setSynonymStep(Number(e.target.value));
                  if (sourceText.trim()) handleParaphrase();
                }}
                className="w-full h-1 bg-[#3D1520] rounded-full appearance-none cursor-pointer accent-[#F5EBDD]"
              />
            </div>
            {/* Step Labels */}
            <div className="flex justify-between text-[11px] font-medium text-[#8E8278]">
              <button
                type="button"
                onClick={() => {
                  setSynonymStep(0);
                  if (sourceText.trim()) handleParaphrase();
                }}
                className={`transition-colors ${
                  synonymStep === 0 ? 'text-[#F5EBDD] font-bold' : 'hover:text-[#D6C7B2]'
                }`}
              >
                Basic
              </button>
              <button
                type="button"
                onClick={() => {
                  setSynonymStep(1);
                  if (sourceText.trim()) handleParaphrase();
                }}
                className={`transition-colors ${
                  synonymStep === 1
                    ? 'text-[#F5EBDD] font-bold underline underline-offset-4 decoration-[#6F1025]'
                    : 'hover:text-[#D6C7B2]'
                }`}
              >
                Medium
              </button>
              <button
                type="button"
                onClick={() => {
                  setSynonymStep(2);
                  if (sourceText.trim()) handleParaphrase();
                }}
                className={`transition-colors ${
                  synonymStep === 2 ? 'text-[#F5EBDD] font-bold' : 'hover:text-[#D6C7B2]'
                }`}
              >
                Extreme
              </button>
            </div>
          </div>
        </div>

        {/* Divider 2 */}
        <div className="hidden md:block h-7 w-[1px] bg-[#3D1520]" />

        {/* Right Segment: Tone Dropdown Selector */}
        <div className="flex items-center space-x-3">
          <span className="text-xs font-semibold text-[#8E8278]">Tone</span>
          <div className="relative">
            <select
              value={selectedTone}
              onChange={(e) => {
                setSelectedTone(e.target.value as WritingTone);
                if (sourceText.trim()) handleParaphrase();
              }}
              className="appearance-none bg-[#100709] border border-[#3D1520] hover:border-[#6F1025] text-[#F5EBDD] pl-4 pr-9 py-1.5 rounded-full text-xs sm:text-sm font-medium focus:outline-none cursor-pointer transition-colors"
            >
              <option value="neutral">Neutral</option>
              <option value="professional">Professional</option>
              <option value="casual">Casual</option>
              <option value="academic">Academic</option>
              <option value="confident">Confident</option>
              <option value="friendly">Friendly</option>
              <option value="direct">Direct</option>
            </select>
            <ChevronDown className="w-3.5 h-3.5 text-[#8E8278] absolute right-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
          </div>
        </div>
      </div>

      {/* Expandable Custom Prompt Input (when Custom Mode is selected) */}
      {selectedMode === 'custom' && showCustomPrompt && (
        <div className="p-3.5 rounded-2xl bg-[#14080D] border border-[#3D1520] flex items-center gap-3 animate-in fade-in duration-150">
          <input
            type="text"
            placeholder="Enter custom instructions (e.g. make it punchy, bullet points, executive brief)..."
            value={customInstruction}
            onChange={(e) => setCustomInstruction(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') handleParaphrase();
            }}
            className="flex-1 px-4 py-2 rounded-xl bg-[#100709] border border-[#2D1219] text-xs sm:text-sm text-[#F5EBDD] placeholder:text-[#5E554C] focus:outline-none focus:border-[#6F1025]"
          />
          <button
            onClick={handleParaphrase}
            className="px-4 py-2 rounded-xl bg-[#6F1025] hover:bg-[#8F1835] text-xs font-semibold text-[#F5EBDD] transition-all"
          >
            Apply
          </button>
        </div>
      )}

      {/* Optional Error Alert Banner */}
      {error && (
        <div className="p-3 rounded-xl bg-red-950/40 border border-red-500/30 text-red-300 text-xs flex items-center justify-between">
          <div className="flex items-center space-x-2">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{error}</span>
          </div>
          <button onClick={() => setError(null)} className="p-1 text-red-300 hover:text-white">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Main Dual-Pane Workstation */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 relative items-stretch">
        {/* Left Card: Input Text */}
        <div className="flex flex-col rounded-2xl sm:rounded-3xl bg-[#14080D] border border-[#2D1219] p-5 sm:p-6 shadow-xl min-h-[460px] justify-between transition-all">
          {/* Card Top */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2 text-[#F5EBDD]">
              <FileText className="w-4 h-4 text-[#D6C7B2]" />
              <span className="font-bold text-sm sm:text-base tracking-wide">Input Text</span>
            </div>

            <button
              onClick={() => {
                setSourceText('');
                setGrammarIssues([]);
              }}
              className="inline-flex items-center space-x-1.5 text-xs text-[#8E8278] hover:text-[#FF453A] transition-colors"
              title="Clear text"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Clear</span>
            </button>
          </div>

          {/* Card Body (Text Area) */}
          <div className="my-4 flex-1 flex flex-col rounded-xl sm:rounded-2xl bg-[#0E0507]/80 border border-[#230C13] p-4 focus-within:border-[#6F1025]/50 transition-colors">
            <textarea
              value={sourceText}
              onChange={(e) => setSourceText(e.target.value)}
              placeholder="Paste or dictate your text here..."
              rows={12}
              className="w-full flex-1 bg-transparent resize-none outline-none border-none text-[#F5EBDD] placeholder:text-[#5E554C] text-sm sm:text-base leading-relaxed font-sans"
            />
          </div>

          {/* Card Footer */}
          <div className="flex items-center justify-between pt-1">
            <span className="text-xs text-[#8E8278]">
              {metrics.wordCount} {metrics.wordCount === 1 ? 'word' : 'words'}
            </span>

            <button
              onClick={toggleInlineDictation}
              className={`inline-flex items-center space-x-2 px-4 py-2 rounded-xl text-xs sm:text-sm font-semibold transition-all ${
                isInlineRecording
                  ? 'bg-[#FF453A] text-white animate-pulse'
                  : 'bg-[#6F1025] hover:bg-[#8F1835] text-[#F5EBDD] shadow-sm active:scale-95'
              }`}
            >
              <Mic className="w-3.5 h-3.5" />
              <span>{isInlineRecording ? 'Listening...' : 'Dictate'}</span>
            </button>
          </div>
        </div>

        {/* Center Floating Arrow Button (Desktop absolute, Mobile centered) */}
        <button
          onClick={handleParaphrase}
          disabled={isLoading || !sourceText.trim()}
          className="hidden lg:flex absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 z-20 w-12 h-12 rounded-full bg-[#5B101E] hover:bg-[#6F1025] text-[#F5EBDD] border border-[#7E1B2D] shadow-[0_4px_24px_rgba(111,16,37,0.5)] items-center justify-center transition-all hover:scale-110 active:scale-95 disabled:opacity-50 disabled:hover:scale-100 cursor-pointer"
          title="Refine text"
        >
          {isLoading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <ArrowRight className="w-5 h-5 stroke-[2.5]" />
          )}
        </button>

        {/* Mobile Stack Arrow */}
        <div className="flex lg:hidden justify-center my-[-8px] z-10">
          <button
            onClick={handleParaphrase}
            disabled={isLoading || !sourceText.trim()}
            className="w-11 h-11 rounded-full bg-[#5B101E] hover:bg-[#6F1025] text-[#F5EBDD] border border-[#7E1B2D] shadow-lg flex items-center justify-center transition-all active:scale-95 disabled:opacity-50"
            title="Refine text"
          >
            {isLoading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <ArrowRight className="w-4 h-4 stroke-[2.5] rotate-90" />
            )}
          </button>
        </div>

        {/* Right Card: Refined Output */}
        <div className="flex flex-col rounded-2xl sm:rounded-3xl bg-[#14080D] border border-[#2D1219] p-5 sm:p-6 shadow-xl min-h-[460px] justify-between transition-all">
          {/* Card Top */}
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2 text-[#F5EBDD]">
              <Sparkles className="w-4 h-4 text-[#A83249]" />
              <span className="font-bold text-sm sm:text-base tracking-wide">Refined Output</span>
            </div>

            <div className="flex items-center space-x-2">
              <button
                onClick={handleCopy}
                disabled={!refinedText}
                className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-[#240F16] border border-[#3D1520] hover:border-[#6F1025] text-xs font-semibold text-[#F5EBDD] disabled:opacity-40 transition-all"
              >
                {copied ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-green-400" />
                    <span className="text-green-400">Copied</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-3.5 h-3.5" />
                    <span>Copy</span>
                  </>
                )}
              </button>

              <button
                onClick={handleExportText}
                disabled={!refinedText}
                className="p-1.5 rounded-xl bg-[#240F16] border border-[#3D1520] hover:border-[#6F1025] text-[#F5EBDD] disabled:opacity-40 transition-all"
                title="Download Output"
              >
                <Download className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* Card Body */}
          <div className="my-4 flex-1 flex flex-col rounded-xl sm:rounded-2xl bg-[#0E0507]/80 border border-[#230C13] p-4 relative overflow-y-auto min-h-[300px]">
            {isLoading ? (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 space-y-3">
                <div className="w-8 h-8 rounded-full border-2 border-[#6F1025] border-t-[#F5EBDD] animate-spin" />
                <p className="text-sm font-medium text-[#F5EBDD]">Refining your writing with AI...</p>
                <p className="text-xs text-[#8E8278]">
                  Enhancing vocabulary, cadence, and grammatical clarity
                </p>
              </div>
            ) : refinedText ? (
              <div className="text-sm sm:text-base leading-relaxed text-[#F5EBDD] select-text">
                <p>
                  {refinedText.split(/\s+/).map((word, idx) => {
                    const altMatch = wordAlternatives.find((a) => a.wordIndex === idx);
                    if (altMatch) {
                      return (
                        <span
                          key={idx}
                          onClick={(e) => {
                            const rect = e.currentTarget.getBoundingClientRect();
                            setActiveAlternative({
                              alternative: altMatch,
                              position: { top: rect.top, left: rect.left + rect.width / 2 },
                            });
                          }}
                          className="quill-word-replaced mr-1 inline-block"
                        >
                          {word}
                        </span>
                      );
                    }
                    return <span key={idx} className="mr-1">{word}</span>;
                  })}
                </p>
              </div>
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 text-[#8E8278] my-auto">
                <SparkleStarIcon className="w-12 h-12 text-[#D6C7B2]/40 mb-3" />
                <p className="text-sm sm:text-base font-semibold text-[#F5EBDD]">
                  Your refined text will appear here
                </p>
                <p className="text-xs sm:text-sm text-[#8E8278] mt-1">
                  Enter or dictate your text to get started.
                </p>
              </div>
            )}

            {/* Floating Synonym Popover */}
            {activeAlternative && (
              <SynonymPopover
                alternative={activeAlternative.alternative}
                position={activeAlternative.position}
                onSelectSynonym={handleSwapWord}
                onClose={() => setActiveAlternative(null)}
              />
            )}
          </div>

          {/* Card Footer */}
          <div className="flex items-center justify-between pt-1">
            <span className="text-xs text-[#8E8278]">
              {refinedWordsCount} {refinedWordsCount === 1 ? 'word' : 'words'}
            </span>

            {refinedText && (
              <button
                onClick={() => setSourceText(refinedText)}
                className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-[#240F16] border border-[#3D1520] hover:border-[#6F1025] text-xs font-semibold text-[#F5EBDD] transition-all"
                title="Use refined text as input"
              >
                <RotateCcw className="w-3.5 h-3.5 text-[#A83249]" />
                <span>Use as Input</span>
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Expandable Writing Quality & Diagnostics Strip */}
      <div className="pt-2">
        <button
          onClick={() => setShowAnalytics(!showAnalytics)}
          className="flex items-center space-x-2 text-xs font-semibold text-[#8E8278] hover:text-[#F5EBDD] transition-colors"
        >
          <Sliders className="w-3.5 h-3.5" />
          <span>
            Writing Quality & Diagnostics (Score {metrics.overallScore} • {grammarIssues.length}{' '}
            {grammarIssues.length === 1 ? 'suggestion' : 'suggestions'})
          </span>
          <ChevronDown
            className={`w-3.5 h-3.5 transition-transform ${showAnalytics ? 'rotate-180' : ''}`}
          />
        </button>

        {showAnalytics && (
          <div className="mt-4 space-y-4 animate-in fade-in duration-200">
            <ScoreMetricsDock metrics={metrics} />
            {grammarIssues.length > 0 && (
              <div className="p-4 rounded-2xl bg-[#14080D] border border-[#2D1219] space-y-3">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-[#F5EBDD] uppercase tracking-wider">
                    Grammar & Flow Suggestions ({grammarIssues.length})
                  </span>
                  <button
                    onClick={handleAcceptAllIssues}
                    className="text-xs font-bold text-[#A83249] hover:underline"
                  >
                    Accept All
                  </button>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
                  {grammarIssues.map((issue) => (
                    <GrammarlyIssueCard
                      key={issue.id}
                      issue={issue}
                      onAccept={handleAcceptIssue}
                      onDismiss={handleDismissIssue}
                    />
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>

      {/* Full Voice Dictation Modal */}
      {isVoiceOpen && (
        <VoiceModal
          isOpen={isVoiceOpen}
          onClose={() => setIsVoiceOpen(false)}
          onTranscriptReady={(transcript: string) => {
            setSourceText((prev) => (prev ? prev + ' ' + transcript : transcript));
            setIsVoiceOpen(false);
          }}
        />
      )}
    </div>
  );
};
