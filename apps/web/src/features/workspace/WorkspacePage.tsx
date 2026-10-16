import React, { useState, useEffect, useMemo, useRef } from 'react';
import {
  WRITING_MODES,
  WritingMode,
  WritingTone,
  RefineResponse,
  SynonymIntensity,
  WordAlternative,
  GrammarIssue,
} from '@sayn/shared-types';
import { apiClient } from '../../services/api.js';
import { DiffViewer } from '../../components/ui/DiffViewer.js';
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
  Copy,
  Check,
  RotateCcw,
  Sliders,
  Layers,
  Sparkles,
  AlertCircle,
  ShieldAlert,
  Snowflake,
  Download,
  Trash2,
  CheckCheck,
  ExternalLink,
  ChevronRight,
  Flame,
} from 'lucide-react';

export const WorkspacePage: React.FC = () => {
  const [sourceText, setSourceText] = useState('');
  const [refinedText, setRefinedText] = useState('');
  const [selectedMode, setSelectedMode] = useState<WritingMode>('standard');
  const [selectedTone, setSelectedTone] = useState<WritingTone>('neutral');
  const [synonymLevel, setSynonymLevel] = useState<SynonymIntensity>(2);
  const [freezeWords, setFreezeWords] = useState<string[]>(['SAYN', 'API']);
  const [newFreezeWord, setNewFreezeWord] = useState('');
  const [showFreezeDrawer, setShowFreezeDrawer] = useState(false);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);
  const [showDiff, setShowDiff] = useState(false);
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [viewMode, setViewMode] = useState<'edit' | 'inspect'>('edit');

  // Grammarly Issues state
  const [grammarIssues, setGrammarIssues] = useState<GrammarIssue[]>([]);
  // QuillBot Alternatives state
  const [wordAlternatives, setWordAlternatives] = useState<WordAlternative[]>([]);
  const [activeAlternative, setActiveAlternative] = useState<{
    alternative: WordAlternative;
    position: { top: number; left: number };
  } | null>(null);

  // Performance metrics
  const metrics = useMemo(() => {
    return calculateDocumentMetrics(sourceText, grammarIssues);
  }, [sourceText, grammarIssues]);

  // Run 0ms local heuristic grammar check whenever sourceText changes
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

  const handleAddFreezeWord = (e: React.FormEvent) => {
    e.preventDefault();
    const clean = newFreezeWord.trim();
    if (clean && !freezeWords.includes(clean)) {
      setFreezeWords([...freezeWords, clean]);
      setNewFreezeWord('');
    }
  };

  const handleRemoveFreezeWord = (word: string) => {
    setFreezeWords(freezeWords.filter((w) => w !== word));
  };

  // Paraphrase execution using Groq LPU / Cloudflare
  const handleParaphrase = async () => {
    if (!sourceText.trim()) {
      setError('Please enter or dictate some text to paraphrase.');
      return;
    }

    setIsLoading(true);
    setError(null);
    setActiveAlternative(null);

    try {
      const res = await apiClient.refineText({
        text: sourceText,
        mode: selectedMode,
        tone: selectedTone,
        synonymLevel,
        freezeWords,
        includeGrammarIssues: true,
        includeAlternatives: true,
      });

      setRefinedText(res.refinedText);

      // Synthesize QuillBot alternatives if not provided by backend
      if (res.alternatives && res.alternatives.length > 0) {
        setWordAlternatives(res.alternatives);
      } else {
        generateClientAlternatives(sourceText, res.refinedText);
      }

      if (res.issues && res.issues.length > 0) {
        setGrammarIssues(res.issues);
      }
    } catch (err: any) {
      // Local Fallback Paraphraser
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
    return out;
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
    // Apply in reverse offset order so earlier offsets remain valid
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
      {/* Top Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center space-x-2">
            <h1 className="text-2xl font-black tracking-tight text-sayn-dark-text">
              SAYN AI Studio
            </h1>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider bg-sayn-dark-accent/15 text-sayn-dark-accent border border-sayn-dark-accent/30">
              QuillBot + Grammarly + Wispr
            </span>
          </div>
          <p className="text-xs text-sayn-dark-secondary mt-1">
            Real-time multi-pillar grammar linting, synonym depth control, and sub-second speech intelligence.
          </p>
        </div>

        {/* Global Dictate & Actions */}
        <div className="flex items-center space-x-3">
          <button
            onClick={() => setIsVoiceOpen(true)}
            className="inline-flex items-center space-x-2 px-4 py-2 rounded-xl text-xs font-bold text-black bg-sayn-dark-accent hover:brightness-110 shadow-lg shadow-sayn-dark-accent/20 transition-all"
          >
            <Mic className="w-4 h-4 text-black stroke-[2.5]" />
            <span>Voice Dictation (Fn)</span>
          </button>
        </div>
      </div>

      {/* QuillBot Controls Bar (Modes + Synonym Slider + Freeze Words) */}
      <div className="p-4 rounded-2xl bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider glass-obsidian space-y-4">
        {/* Modes Pills */}
        <div className="flex items-center justify-between gap-4 overflow-x-auto pb-1 scrollbar-none">
          <div className="flex items-center gap-1.5 flex-nowrap">
            {Object.values(WRITING_MODES).slice(0, 10).map((mode) => {
              const isSelected = selectedMode === mode.id;
              return (
                <button
                  key={mode.id}
                  onClick={() => {
                    setSelectedMode(mode.id);
                    if (sourceText.trim()) handleParaphrase();
                  }}
                  className={`px-3 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
                    isSelected
                      ? 'bg-sayn-dark-accent text-black shadow-md shadow-sayn-dark-accent/25'
                      : 'bg-sayn-dark-surface2 text-sayn-dark-secondary border border-white/5 hover:text-white'
                  }`}
                >
                  {mode.label}
                </button>
              );
            })}
          </div>

          {/* Freeze Words Drawer Toggle */}
          <button
            onClick={() => setShowFreezeDrawer(!showFreezeDrawer)}
            className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap border transition-all ${
              freezeWords.length > 0
                ? 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30'
                : 'bg-sayn-dark-surface2 text-sayn-dark-muted border-sayn-dark-divider'
            }`}
          >
            <Snowflake className="w-3.5 h-3.5" />
            <span>Freeze Words ({freezeWords.length})</span>
          </button>
        </div>

        {/* Synonym Slider & Tone Selector */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-3 border-t border-sayn-dark-divider text-xs">
          {/* Synonym Slider */}
          <div className="flex items-center space-x-4">
            <div className="flex items-center space-x-1.5 text-sayn-dark-secondary font-semibold">
              <Flame className="w-4 h-4 text-sayn-dark-accent" />
              <span>Synonym Depth:</span>
            </div>
            <div className="flex items-center space-x-2">
              <span className="text-[10px] text-sayn-dark-muted">Basic</span>
              <input
                type="range"
                min="0"
                max="4"
                step="1"
                value={synonymLevel}
                onChange={(e) => {
                  setSynonymLevel(Number(e.target.value) as SynonymIntensity);
                  if (sourceText.trim()) handleParaphrase();
                }}
                className="w-32 h-1.5 bg-sayn-dark-surface2 rounded-lg appearance-none cursor-pointer accent-sayn-dark-accent"
              />
              <span className="text-[10px] text-sayn-dark-muted">Extreme</span>
              <span className="px-2 py-0.5 rounded-md bg-sayn-dark-accent/15 text-sayn-dark-accent font-bold text-[10px]">
                {['Minimal', 'Low', 'Medium', 'High', 'Maximum'][synonymLevel]}
              </span>
            </div>
          </div>

          {/* Tone Selector */}
          <div className="flex items-center space-x-2">
            <span className="text-sayn-dark-muted font-medium">Tone:</span>
            <select
              value={selectedTone}
              onChange={(e) => {
                setSelectedTone(e.target.value as WritingTone);
                if (sourceText.trim()) handleParaphrase();
              }}
              className="px-3 py-1.5 rounded-lg bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text focus:outline-none font-medium"
            >
              <option value="neutral">Neutral Flow</option>
              <option value="professional">Professional</option>
              <option value="casual">Casual & Relaxed</option>
              <option value="friendly">Friendly & Warm</option>
              <option value="confident">Direct & Confident</option>
              <option value="academic">Academic & Formal</option>
            </select>
          </div>
        </div>

        {/* Freeze Words Drawer Content */}
        {showFreezeDrawer && (
          <div className="p-3 rounded-xl bg-sayn-dark-surface2/60 border border-sayn-dark-divider space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-sayn-dark-text flex items-center space-x-1.5">
                <Snowflake className="w-3.5 h-3.5 text-cyan-400" />
                <span>Protected / Freeze Words (QuillBot will NOT alter these)</span>
              </span>
            </div>
            <div className="flex flex-wrap gap-1.5">
              {freezeWords.map((word) => (
                <span
                  key={word}
                  className="inline-flex items-center space-x-1.5 px-2.5 py-1 rounded-lg bg-cyan-500/10 border border-cyan-500/30 text-cyan-300 text-xs font-mono font-medium"
                >
                  <span>{word}</span>
                  <button
                    onClick={() => handleRemoveFreezeWord(word)}
                    className="hover:text-red-400 transition-colors"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
            <form onSubmit={handleAddFreezeWord} className="flex gap-2">
              <input
                type="text"
                placeholder="Lock a word or acronym (e.g. Kubernetes, SAYN)..."
                value={newFreezeWord}
                onChange={(e) => setNewFreezeWord(e.target.value)}
                className="flex-1 px-3 py-1.5 rounded-lg bg-sayn-dark-surface border border-sayn-dark-divider text-xs text-sayn-dark-text focus:outline-none"
              />
              <button
                type="submit"
                className="px-3 py-1.5 rounded-lg bg-cyan-500/20 text-cyan-300 border border-cyan-500/30 text-xs font-bold hover:bg-cyan-500/30 transition-all"
              >
                + Lock Word
              </button>
            </form>
          </div>
        )}
      </div>

      {/* Main Dual-Pane Workstation */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left Pane: Input & Grammarly 4-Pillar Linter */}
        <div className="flex flex-col rounded-2xl bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider glass-obsidian overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-sayn-dark-divider bg-sayn-dark-surface2/30">
            <div className="flex items-center space-x-2">
              <span className="text-xs font-black uppercase tracking-wider text-sayn-dark-secondary">
                Input Text
              </span>
              {grammarIssues.length > 0 && (
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-red-500/15 text-red-400 border border-red-500/30">
                  {grammarIssues.length} issues
                </span>
              )}
            </div>

            <div className="flex items-center space-x-2 text-xs">
              {grammarIssues.length > 0 && (
                <button
                  onClick={handleAcceptAllIssues}
                  className="inline-flex items-center space-x-1 px-2.5 py-1 rounded-lg bg-sayn-dark-accent/15 text-sayn-dark-accent border border-sayn-dark-accent/30 font-bold hover:bg-sayn-dark-accent/25 transition-all"
                >
                  <CheckCheck className="w-3.5 h-3.5" />
                  <span>Accept All ({grammarIssues.length})</span>
                </button>
              )}
              <button
                onClick={() => setSourceText('')}
                className="text-sayn-dark-muted hover:text-red-400 p-1"
                title="Clear input"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Text Area */}
          <div className="p-4 flex-1 min-h-[300px] flex flex-col">
            <textarea
              value={sourceText}
              onChange={(e) => setSourceText(e.target.value)}
              placeholder="Paste or dictate your text here to begin paraphrasing and grammar inspection..."
              className="w-full flex-1 bg-transparent resize-none border-none outline-none text-sayn-dark-text text-sm sm:text-base leading-relaxed placeholder:text-sayn-dark-muted font-sans"
              rows={11}
            />
          </div>

          {/* Grammarly Issues Drawer (if issues present) */}
          {grammarIssues.length > 0 && (
            <div className="p-4 border-t border-sayn-dark-divider bg-sayn-dark-surface2/20 space-y-2.5 max-h-64 overflow-y-auto">
              <div className="flex items-center justify-between text-xs font-bold text-sayn-dark-muted uppercase tracking-wider">
                <span>Grammarly Suggestions ({grammarIssues.length})</span>
              </div>
              <div className="space-y-2">
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

          {/* Bottom Action Bar */}
          <div className="flex items-center justify-between px-4 py-3 border-t border-sayn-dark-divider bg-sayn-dark-surface2/40 text-xs">
            <span className="text-sayn-dark-muted">
              {metrics.wordCount} words • {metrics.characterCount} chars
            </span>
            <button
              onClick={handleParaphrase}
              disabled={isLoading || !sourceText.trim()}
              className="inline-flex items-center space-x-2 px-5 py-2 rounded-xl bg-sayn-dark-accent text-black font-extrabold shadow-md hover:brightness-110 disabled:opacity-40 transition-all"
            >
              <Sparkles className="w-4 h-4 stroke-[2.5]" />
              <span>{isLoading ? 'Paraphrasing...' : 'Paraphrase (Groq 21ms)'}</span>
            </button>
          </div>
        </div>

        {/* Right Pane: Paraphrased Output + QuillBot Word Synonyms */}
        <div className="flex flex-col rounded-2xl bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider glass-obsidian overflow-hidden">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-sayn-dark-divider bg-sayn-dark-surface2/30">
            <div className="flex items-center space-x-2">
              <span className="text-xs font-black uppercase tracking-wider text-sayn-dark-accent">
                Paraphrased Output
              </span>
              <span className="text-[10px] text-sayn-dark-muted">
                (Click highlighted words to view synonyms)
              </span>
            </div>

            <div className="flex items-center space-x-2 text-xs">
              <button
                onClick={handleCopy}
                disabled={!refinedText}
                className="inline-flex items-center space-x-1 px-3 py-1 rounded-lg bg-sayn-dark-surface2 border border-sayn-dark-divider hover:border-sayn-dark-accent text-sayn-dark-text font-medium disabled:opacity-40 transition-all"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-sayn-dark-accent" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copied ? 'Copied' : 'Copy'}</span>
              </button>

              <button
                onClick={handleExportText}
                disabled={!refinedText}
                className="p-1 text-sayn-dark-muted hover:text-sayn-dark-text transition-colors"
                title="Export as Text File"
              >
                <Download className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Interactive Output Area */}
          <div className="p-4 flex-1 min-h-[300px] flex flex-col relative text-sm sm:text-base leading-relaxed text-sayn-dark-text">
            {refinedText ? (
              <div className="space-y-3">
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
              <div className="flex-1 flex flex-col items-center justify-center text-center p-8 text-sayn-dark-muted">
                <Sparkles className="w-10 h-10 text-sayn-dark-accent/30 mb-3" />
                <p className="text-sm font-semibold">Your paraphrased prose will appear here</p>
                <p className="text-xs text-sayn-dark-muted mt-1">
                  Adjust the Synonym Slider or choose any mode above to transform your text.
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

          {/* Bottom Actions Bar */}
          <div className="flex items-center justify-between px-4 py-3 border-t border-sayn-dark-divider bg-sayn-dark-surface2/40 text-xs">
            <span className="text-sayn-dark-muted">
              {refinedText ? `${refinedText.split(/\s+/).filter(Boolean).length} words` : '0 words'}
            </span>

            <button
              onClick={() => setSourceText(refinedText)}
              disabled={!refinedText}
              className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text font-semibold hover:border-sayn-dark-accent disabled:opacity-40 transition-all"
            >
              <RotateCcw className="w-3.5 h-3.5 text-sayn-dark-accent" />
              <span>Use as Input</span>
            </button>
          </div>
        </div>
      </div>

      {/* Document Performance Score & Metrics Dock */}
      <ScoreMetricsDock metrics={metrics} />

      {/* Voice Dictation Modal */}
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
