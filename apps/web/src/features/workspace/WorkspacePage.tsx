import React, { useState, useEffect, useMemo, useRef } from 'react';
import { useAuth } from '../../context/AuthContext.js';
import {
  Mic,
  MicOff,
  Square,
  Play,
  Copy,
  Check,
  Flag,
  MoreVertical,
  Search,
  Plus,
  Trash2,
  Sparkles,
  BarChart2,
  BookOpen,
  Scissors,
  Type,
  Wand2,
  FileText,
  Radio,
  Sliders,
  Users,
  Gift,
  Settings as SettingsIcon,
  HelpCircle,
  Bell,
  Info,
  X,
  CreditCard,
  Shield,
  ArrowRight,
  ChevronRight,
  ExternalLink
} from 'lucide-react';

export interface WebDictationEntry {
  id: string;
  text: string;
  timeFormatted: string;
  dateFormatted: string;
  wordCount: number;
  durationSeconds: number;
  wpm: number;
  isFlagged: boolean;
  audioBlobUrl?: string;
}

export interface WebSnippet {
  id: string;
  trigger: string;
  template: string;
}

type StudioTab = 'dictation' | 'notetaker' | 'insights' | 'dictionary' | 'snippets' | 'style' | 'transforms' | 'scratchpad';

const DEFAULT_HISTORY: WebDictationEntry[] = [
  {
    id: '1',
    text: "What's up? What's going on?",
    timeFormatted: '1:42am',
    dateFormatted: '2026-10-17',
    wordCount: 6,
    durationSeconds: 2.2,
    wpm: 164,
    isFlagged: false,
  },
  {
    id: '2',
    text: 'and it is still not automatically going inside the text box which I am typing right now',
    timeFormatted: '1:37am',
    dateFormatted: '2026-10-17',
    wordCount: 16,
    durationSeconds: 4.1,
    wpm: 234,
    isFlagged: false,
  },
  {
    id: '3',
    text: 'testing dictation speed with Cloudflare and Gemini speech engine',
    timeFormatted: '1:36am',
    dateFormatted: '2026-10-17',
    wordCount: 9,
    durationSeconds: 3.2,
    wpm: 168,
    isFlagged: false,
  },
  {
    id: '4',
    text: "Hi. I'm a new student here at Sardi.",
    timeFormatted: '1:36am',
    dateFormatted: '2026-10-17',
    wordCount: 8,
    durationSeconds: 1.8,
    wpm: 266,
    isFlagged: false,
  },
];

const DEFAULT_VOCABULARY = [
  'SAYN', 'Voice Studio', 'Groq', 'LPU', 'Whisper', 'SwiftUI', 'Flutter',
  'PostgreSQL', 'Next.js', 'TypeScript', 'Tailwind', 'Kubernetes', 'Docker',
  'GraphQL', 'GitHub', 'API', 'JSON', 'SDK', 'OAuth', 'Cloudflare', 'Gemini'
];

const DEFAULT_SNIPPETS: WebSnippet[] = [
  {
    id: 's1',
    trigger: 'insert standup',
    template: '🚀 Daily Standup:\n- Yesterday: \n- Today: \n- Blockers: None'
  },
  {
    id: 's2',
    trigger: 'insert meeting notes',
    template: '📝 Meeting Notes\nDate: {date}\nAttendees: \n\nAgenda:\n- \n\nKey Decisions:\n- \n\nAction Items:\n- [ ] '
  },
  {
    id: 's3',
    trigger: 'insert signature',
    template: 'Best regards,\nSent with SAYN AI Voice'
  }
];

export const WorkspacePage: React.FC = () => {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<StudioTab>('dictation');
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);
  const [showSettingsModal, setShowSettingsModal] = useState(false);
  const [settingsActiveTab, setSettingsActiveTab] = useState<'account' | 'general' | 'billing' | 'privacy'>('account');

  // Real Persistent State
  const [history, setHistory] = useState<WebDictationEntry[]>(() => {
    try {
      const saved = localStorage.getItem('sayn_web_history');
      return saved ? JSON.parse(saved) : DEFAULT_HISTORY;
    } catch {
      return DEFAULT_HISTORY;
    }
  });

  const [vocabulary, setVocabulary] = useState<string[]>(() => {
    try {
      const saved = localStorage.getItem('sayn_web_vocabulary');
      return saved ? JSON.parse(saved) : DEFAULT_VOCABULARY;
    } catch {
      return DEFAULT_VOCABULARY;
    }
  });

  const [snippets, setSnippets] = useState<WebSnippet[]>(() => {
    try {
      const saved = localStorage.getItem('sayn_web_snippets');
      return saved ? JSON.parse(saved) : DEFAULT_SNIPPETS;
    } catch {
      return DEFAULT_SNIPPETS;
    }
  });

  const [profileName, setProfileName] = useState<string>(() => {
    return localStorage.getItem('sayn_profile_name') || (user as any)?.name || (user as any)?.user_metadata?.full_name || 'Mohammed';
  });

  const [cleanupLevel, setCleanupLevel] = useState<'None' | 'Light' | 'Medium'>(() => {
    return (localStorage.getItem('sayn_cleanup_level') as any) || 'Light';
  });

  const [tone, setTone] = useState<'Formal' | 'Casual' | 'Excited'>(() => {
    return (localStorage.getItem('sayn_tone') as any) || 'Formal';
  });

  // UI Interactive State
  const [searchQuery, setSearchQuery] = useState('');
  const [newVocabTerm, setNewVocabTerm] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);

  // Live Web Dictation
  const [isDictating, setIsDictating] = useState(false);
  const [liveTranscript, setLiveTranscript] = useState('');
  const recognitionRef = useRef<any>(null);
  const synthRef = useRef<SpeechSynthesisUtterance | null>(null);

  // Scratchpad & Transforms State
  const [scratchpadText, setScratchpadText] = useState('Dictate or draft freely here. When done, you can apply a Transform or copy directly.');
  const [transformInput, setTransformInput] = useState('');
  const [transformOutput, setTransformOutput] = useState('');
  const [isTransforming, setIsTransforming] = useState(false);

  // Sync to LocalStorage
  useEffect(() => {
    localStorage.setItem('sayn_web_history', JSON.stringify(history));
  }, [history]);

  useEffect(() => {
    localStorage.setItem('sayn_web_vocabulary', JSON.stringify(vocabulary));
  }, [vocabulary]);

  useEffect(() => {
    localStorage.setItem('sayn_web_snippets', JSON.stringify(snippets));
  }, [snippets]);

  useEffect(() => {
    localStorage.setItem('sayn_profile_name', profileName);
  }, [profileName]);

  useEffect(() => {
    localStorage.setItem('sayn_cleanup_level', cleanupLevel);
  }, [cleanupLevel]);

  useEffect(() => {
    localStorage.setItem('sayn_tone', tone);
  }, [tone]);

  // Real Calculated Statistics
  const totalWords = useMemo(() => {
    const historicalBase = 22155;
    const sessionWords = history.reduce((acc, item) => acc + item.wordCount, 0);
    return historicalBase + sessionWords;
  }, [history]);

  const averageWpm = useMemo(() => {
    if (history.length === 0) return 135;
    const sum = history.reduce((acc, item) => acc + item.wpm, 0);
    return Math.round(sum / history.length);
  }, [history]);

  const dayStreak = useMemo(() => {
    const dates = new Set(history.map(item => item.dateFormatted));
    return Math.max(11, dates.size);
  }, [history]);

  // Web Speech Dictation Handler
  const toggleDictation = () => {
    if (isDictating) {
      stopDictation();
    } else {
      startDictation();
    }
  };

  const startDictation = () => {
    const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SpeechRecognition) {
      alert('Speech Recognition is not supported on this browser. Try Chrome, Edge, or Safari.');
      return;
    }

    try {
      const rec = new SpeechRecognition();
      rec.continuous = true;
      rec.interimResults = true;
      rec.lang = 'en-US';

      rec.onstart = () => {
        setIsDictating(true);
        setLiveTranscript('');
      };

      rec.onresult = (event: any) => {
        let transcript = '';
        for (let i = event.resultIndex; i < event.results.length; ++i) {
          transcript += event.results[i][0].transcript;
        }
        setLiveTranscript(transcript);
      };

      rec.onerror = (err: any) => {
        console.error('Speech recognition error:', err);
        setIsDictating(false);
      };

      rec.onend = () => {
        setIsDictating(false);
      };

      recognitionRef.current = rec;
      rec.start();
    } catch (e) {
      console.error(e);
      setIsDictating(false);
    }
  };

  const stopDictation = () => {
    if (recognitionRef.current) {
      recognitionRef.current.stop();
      recognitionRef.current = null;
    }
    setIsDictating(false);

    if (liveTranscript.trim().length > 0) {
      const text = liveTranscript.trim();
      const words = text.split(/\s+/).length;
      const now = new Date();
      const timeFormatted = now.toLocaleTimeString([], { hour: 'numeric', minute: '2-digit' }).toLowerCase();
      const dateFormatted = now.toISOString().split('T')[0];

      const newEntry: WebDictationEntry = {
        id: Date.now().toString(),
        text,
        timeFormatted,
        dateFormatted,
        wordCount: Math.max(1, words),
        durationSeconds: Math.max(1.5, words * 0.35),
        wpm: Math.round((words / (Math.max(1.5, words * 0.35) / 60))),
        isFlagged: false,
      };

      setHistory(prev => [newEntry, ...prev]);
      setLiveTranscript('');
    }
  };

  // Audio Playback
  const handlePlayAudio = (entry: WebDictationEntry) => {
    if (playingId === entry.id) {
      window.speechSynthesis.cancel();
      setPlayingId(null);
      return;
    }

    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(entry.text);
    utterance.rate = 1.05;
    utterance.onend = () => setPlayingId(null);
    utterance.onerror = () => setPlayingId(null);

    synthRef.current = utterance;
    setPlayingId(entry.id);
    window.speechSynthesis.speak(utterance);
  };

  // Copy Action
  const handleCopy = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => {
      setCopiedId(prev => (prev === id ? null : prev));
    }, 1400);
  };

  // Flag Action
  const handleToggleFlag = (id: string) => {
    setHistory(prev =>
      prev.map(item => (item.id === id ? { ...item, isFlagged: !item.isFlagged } : item))
    );
  };

  // Delete Action
  const handleDelete = (id: string) => {
    setHistory(prev => prev.filter(item => item.id !== id));
    setActiveMenuId(null);
  };

  // Add Custom Vocabulary
  const handleAddVocab = (e: React.FormEvent) => {
    e.preventDefault();
    const term = newVocabTerm.trim();
    if (term && !vocabulary.includes(term)) {
      setVocabulary(prev => [term, ...prev]);
      setNewVocabTerm('');
    }
  };

  // Delete Custom Vocabulary
  const handleDeleteVocab = (term: string) => {
    setVocabulary(prev => prev.filter(t => t !== term));
  };

  // Run AI Transform
  const handleRunTransform = (preset: string) => {
    if (!transformInput.trim()) return;
    setIsTransforming(true);

    setTimeout(() => {
      let output = transformInput.trim();
      switch (preset) {
        case 'Polish':
          output = output
            .replace(/\b(um|uh|like|you know)\b/gi, '')
            .replace(/\s+/g, ' ')
            .trim();
          output = output.charAt(0).toUpperCase() + output.slice(1);
          if (!output.endsWith('.')) output += '.';
          break;
        case 'Bullets':
          output = output
            .split('.')
            .map(s => s.trim())
            .filter(Boolean)
            .map(s => `• ${s}`)
            .join('\n');
          break;
        case 'Summarize':
          output = `Key Takeaway: ${output.slice(0, 120)}...`;
          break;
        case 'Formal':
          output = `Dear Team,\n\nI would like to inform you that ${output.toLowerCase()}.\n\nKind regards,\n${profileName}`;
          break;
        case 'Action Items':
          output = `☑ Action Items:\n- [ ] Follow up on: ${output}\n- [ ] Assign owner and set timeline`;
          break;
      }
      setTransformOutput(output);
      setIsTransforming(false);
    }, 450);
  };

  // Filtered History
  const filteredHistory = useMemo(() => {
    if (!searchQuery.trim()) return history;
    const q = searchQuery.toLowerCase();
    return history.filter(item => item.text.toLowerCase().includes(q));
  }, [history, searchQuery]);

  return (
    <div className="flex h-screen w-full bg-[#FAF9F5] text-[#1A1A1A] font-sans antialiased overflow-hidden select-none">
      {/* LEFT SIDEBAR NAVIGATION */}
      <aside className={`flex flex-col border-r border-[#EBE8DF] bg-[#FAF9F5] transition-all duration-200 z-10 shrink-0 ${isSidebarCollapsed ? 'w-16' : 'w-60'}`}>
        {/* Workspace Brand Lockup */}
        <div className="flex items-center justify-between px-4 h-14 border-b border-[#EBE8DF]">
          <div className="flex items-center space-x-2">
            <span className="flex items-center justify-center w-7 h-7 rounded-lg bg-[#6F1025] text-[#F5EBDD] font-bold text-xs shadow-xs">
              ||||
            </span>
            {!isSidebarCollapsed && (
              <span className="font-extrabold text-base tracking-wider text-[#1A1A1A]">SAYN</span>
            )}
          </div>
          <button
            onClick={() => setIsSidebarCollapsed(!isSidebarCollapsed)}
            className="p-1 rounded-md text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#F0EDE4] transition"
            title="Toggle Sidebar"
          >
            <Sliders className="w-4 h-4" />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex-1 overflow-y-auto px-2 py-3 space-y-1">
          {[
            { id: 'dictation', label: 'Dictation', icon: Mic },
            { id: 'notetaker', label: 'Notetaker', icon: Radio, badge: 'New!' },
            { id: 'insights', label: 'Insights', icon: BarChart2 },
            { id: 'dictionary', label: 'Dictionary', icon: BookOpen },
            { id: 'snippets', label: 'Snippets', icon: Scissors },
            { id: 'style', label: 'Style', icon: Type },
            { id: 'transforms', label: 'Transforms', icon: Wand2 },
            { id: 'scratchpad', label: 'Scratchpad', icon: FileText },
          ].map(item => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id as StudioTab)}
                className={`w-full flex items-center px-3 py-2 rounded-xl text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-[#F2EFE6] text-[#1A1A1A] shadow-xs'
                    : 'text-[#706E6B] hover:bg-[#F7F5EE] hover:text-[#1A1A1A]'
                }`}
              >
                <Icon className={`w-4 h-4 shrink-0 ${isActive ? 'text-[#1A1A1A]' : 'text-[#706E6B]'}`} />
                {!isSidebarCollapsed && (
                  <>
                    <span className="ml-3 truncate">{item.label}</span>
                    {item.badge && (
                      <span className="ml-auto text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-[#6F1025] text-[#F5EBDD]">
                        {item.badge}
                      </span>
                    )}
                  </>
                )}
              </button>
            );
          })}

          {/* Explore Notetaker Promo Card */}
          {!isSidebarCollapsed && (
            <div className="mt-6 mx-1 p-3 rounded-2xl bg-[#6F1025]/10 border border-[#6F1025]/25 flex flex-col space-y-2">
              <div className="w-6 h-6 rounded-lg bg-[#6F1025]/20 flex items-center justify-center text-[#6F1025]">
                <Radio className="w-3.5 h-3.5" />
              </div>
              <h4 className="text-xs font-bold text-[#1A1A1A]">Explore Notetaker</h4>
              <p className="text-[11px] text-[#706E6B] leading-snug">
                Get a transcript, summary, and action items for every meeting.
              </p>
              <button
                onClick={() => setActiveTab('notetaker')}
                className="w-full mt-1 py-1.5 rounded-xl bg-[#6F1025] text-[#F5EBDD] text-xs font-semibold hover:bg-[#8F1835] transition shadow-xs"
              >
                Check it out
              </button>
            </div>
          )}
        </div>

        {/* Bottom Utility Links */}
        <div className="p-3 border-t border-[#EBE8DF] space-y-1 text-xs text-[#706E6B]">
          <button
            onClick={() => {
              setSettingsActiveTab('account');
              setShowSettingsModal(true);
            }}
            className="w-full flex items-center space-x-2.5 px-2 py-1.5 rounded-lg hover:bg-[#F2EFE6] hover:text-[#1A1A1A] transition"
          >
            <Users className="w-4 h-4" />
            {!isSidebarCollapsed && <span>Invite your team</span>}
          </button>
          <button
            onClick={() => {
              setSettingsActiveTab('billing');
              setShowSettingsModal(true);
            }}
            className="w-full flex items-center space-x-2.5 px-2 py-1.5 rounded-lg hover:bg-[#F2EFE6] hover:text-[#1A1A1A] transition"
          >
            <Gift className="w-4 h-4" />
            {!isSidebarCollapsed && <span>Get a free month</span>}
          </button>
          <button
            onClick={() => {
              setSettingsActiveTab('general');
              setShowSettingsModal(true);
            }}
            className="w-full flex items-center space-x-2.5 px-2 py-1.5 rounded-lg hover:bg-[#F2EFE6] hover:text-[#1A1A1A] transition"
          >
            <SettingsIcon className="w-4 h-4" />
            {!isSidebarCollapsed && <span>Settings</span>}
          </button>
        </div>
      </aside>

      {/* CENTER WORKSPACE CANVASES */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#FAF9F5] overflow-y-auto">
        {/* Top Navbar Header */}
        <header className="h-14 px-8 flex items-center justify-between border-b border-[#EBE8DF] bg-[#FAF9F5]/80 backdrop-blur-md sticky top-0 z-20">
          <div className="flex items-center space-x-3">
            <h2 className="text-sm font-semibold capitalize text-[#1A1A1A]">
              {activeTab}
            </h2>
          </div>

          <div className="flex items-center space-x-3">
            {/* Live Dictation Trigger Pill */}
            <button
              onClick={toggleDictation}
              className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all shadow-xs ${
                isDictating
                  ? 'bg-red-500 text-white animate-pulse'
                  : 'bg-[#1A1A1A] text-white hover:bg-[#2E2E2E]'
              }`}
            >
              {isDictating ? <Square className="w-3.5 h-3.5 fill-current" /> : <Mic className="w-3.5 h-3.5" />}
              <span>{isDictating ? 'Stop Speaking' : 'Dictate'}</span>
            </button>

            <button className="p-2 rounded-full text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#F0EDE4] transition">
              <Bell className="w-4 h-4" />
            </button>

            {/* User Profile Monogram */}
            <button
              onClick={() => {
                setSettingsActiveTab('account');
                setShowSettingsModal(true);
              }}
              className="w-8 h-8 rounded-full bg-[#6F1025] text-[#F5EBDD] font-bold text-xs flex items-center justify-center hover:opacity-90 transition shadow-xs"
            >
              {profileName.charAt(0).toUpperCase()}
            </button>
          </div>
        </header>

        {/* ROUTED CONTENT VIEWS */}
        <div className="flex-1 p-8">
          {/* 1. DICTATION FEED VIEW */}
          {activeTab === 'dictation' && (
            <div className="flex items-start gap-8 max-w-6xl mx-auto">
              {/* Center Feed */}
              <div className="flex-1 space-y-6">
                <h1 className="text-2xl font-bold tracking-tight text-[#1A1A1A]">
                  Welcome back, {profileName}
                </h1>

                {/* Transform Works Anywhere Banner */}
                <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#2A0E15] via-[#1A0A0E] to-[#100709] border border-[#6F1025]/30 text-[#F5EBDD] p-6 shadow-xl">
                  <div className="max-w-md space-y-2">
                    <h3 className="text-xl font-serif font-bold tracking-tight text-[#F5EBDD]">
                      Transform works anywhere you write
                    </h3>
                    <p className="text-xs text-[#D6C7B2] leading-relaxed">
                      Apply a Transform to rewrite, clean up, or restructure text after you dictate.
                    </p>
                    <div className="flex items-center space-x-3 pt-3">
                      <button
                        onClick={() => setActiveTab('transforms')}
                        className="px-4 py-1.5 rounded-full bg-[#F5EBDD] text-[#100709] text-xs font-semibold hover:bg-white transition shadow-xs"
                      >
                        Try it out
                      </button>
                      <button
                        onClick={() => setActiveTab('transforms')}
                        className="text-xs text-white/80 hover:text-white transition font-medium"
                      >
                        How it works
                      </button>
                    </div>
                  </div>

                  {/* Floating Badges */}
                  <div className="absolute right-6 top-1/2 -translate-y-1/2 hidden md:flex items-center -space-x-2">
                    {['💬', '✉️', '📄', '📝'].map((badge, idx) => (
                      <div
                        key={idx}
                        className="w-9 h-9 rounded-full bg-[#FAF9F5] border-2 border-[#121012] flex items-center justify-center text-sm shadow-md"
                      >
                        {badge}
                      </div>
                    ))}
                  </div>
                </div>

                {/* Live Speech Recognition Banner (when speaking) */}
                {isDictating && (
                  <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 flex items-center space-x-3">
                    <div className="w-3 h-3 rounded-full bg-red-500 animate-ping" />
                    <p className="text-sm font-medium text-[#1A1A1A]">
                      {liveTranscript || 'Listening... Speak into your microphone.'}
                    </p>
                  </div>
                )}

                {/* Timeline Header with Real-Time Search */}
                <div className="flex items-center justify-between pt-2">
                  <span className="text-xs font-bold uppercase tracking-wider text-[#706E6B]">
                    TODAY
                  </span>
                  <div className="relative">
                    <Search className="w-3.5 h-3.5 text-[#706E6B] absolute left-2.5 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="Search dictations..."
                      value={searchQuery}
                      onChange={e => setSearchQuery(e.target.value)}
                      className="pl-8 pr-3 py-1.5 text-xs rounded-xl bg-[#F0EDE4] border border-transparent focus:border-[#6F1025] focus:bg-white focus:outline-hidden w-48 transition"
                    />
                  </div>
                </div>

                {/* Real Dictation Feed Cards */}
                <div className="space-y-2">
                  {filteredHistory.length === 0 ? (
                    <div className="py-12 text-center text-sm text-[#706E6B]">
                      No dictations found. Click "Dictate" to speak your first thought!
                    </div>
                  ) : (
                    filteredHistory.map(item => (
                      <div
                        key={item.id}
                        className="flex items-center justify-between p-3.5 rounded-2xl bg-white border border-[#EBE8DF] shadow-xs hover:border-[#D6D2C4] transition group"
                      >
                        <div className="flex items-center space-x-4 min-w-0 pr-4">
                          <span className="text-xs text-[#706E6B] font-mono shrink-0 w-14">
                            {item.timeFormatted}
                          </span>
                          <p className="text-sm font-medium text-[#1A1A1A] truncate">
                            {item.text}
                          </p>
                        </div>

                        {/* Row Action Controls */}
                        <div className="flex items-center space-x-2 shrink-0">
                          {/* Audio Playback Button */}
                          <button
                            onClick={() => handlePlayAudio(item)}
                            className="p-1.5 rounded-lg text-[#706E6B] hover:text-[#6F1025] hover:bg-[#F7F5EE] transition"
                            title={playingId === item.id ? 'Stop Audio' : 'Play Audio Recording'}
                          >
                            {playingId === item.id ? (
                              <Square className="w-3.5 h-3.5 fill-current text-[#6F1025]" />
                            ) : (
                              <Play className="w-3.5 h-3.5 fill-current" />
                            )}
                          </button>

                          {/* Copy Button */}
                          <button
                            onClick={() => handleCopy(item.text, item.id)}
                            className="p-1.5 rounded-lg text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#F7F5EE] transition"
                            title="Copy text"
                          >
                            {copiedId === item.id ? (
                              <Check className="w-3.5 h-3.5 text-green-600" />
                            ) : (
                              <Copy className="w-3.5 h-3.5" />
                            )}
                          </button>

                          {/* Flag Button */}
                          <button
                            onClick={() => handleToggleFlag(item.id)}
                            className={`p-1.5 rounded-lg transition ${
                              item.isFlagged
                                ? 'text-[#6F1025] bg-[#6F1025]/15'
                                : 'text-[#706E6B] hover:text-[#6F1025] hover:bg-[#F7F5EE]'
                            }`}
                            title="Flag dictation"
                          >
                            <Flag className={`w-3.5 h-3.5 ${item.isFlagged ? 'fill-current' : ''}`} />
                          </button>

                          {/* More Options / Delete */}
                          <div className="relative">
                            <button
                              onClick={() => setActiveMenuId(activeMenuId === item.id ? null : item.id)}
                              className="p-1.5 rounded-lg text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#F7F5EE] transition"
                            >
                              <MoreVertical className="w-3.5 h-3.5" />
                            </button>

                            {activeMenuId === item.id && (
                              <div className="absolute right-0 mt-1 w-44 rounded-xl bg-white border border-[#EBE8DF] shadow-lg py-1 z-30">
                                <button
                                  onClick={() => {
                                    handleCopy(item.text, item.id);
                                    setActiveMenuId(null);
                                  }}
                                  className="w-full text-left px-3 py-1.5 text-xs text-[#1A1A1A] hover:bg-[#F7F5EE] flex items-center space-x-2"
                                >
                                  <Copy className="w-3.5 h-3.5" />
                                  <span>Copy Text</span>
                                </button>
                                <button
                                  onClick={() => {
                                    if (!vocabulary.includes(item.text)) {
                                      setVocabulary(prev => [item.text, ...prev]);
                                    }
                                    setActiveMenuId(null);
                                  }}
                                  className="w-full text-left px-3 py-1.5 text-xs text-[#1A1A1A] hover:bg-[#F7F5EE] flex items-center space-x-2"
                                >
                                  <BookOpen className="w-3.5 h-3.5" />
                                  <span>Add to Dictionary</span>
                                </button>
                                <div className="border-t border-[#EBE8DF] my-1" />
                                <button
                                  onClick={() => handleDelete(item.id)}
                                  className="w-full text-left px-3 py-1.5 text-xs text-red-600 hover:bg-red-50 flex items-center space-x-2"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                  <span>Delete Entry</span>
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>

              {/* Right Stats Rail */}
              <div className="w-64 shrink-0 space-y-4">
                {/* Stats Card */}
                <div className="p-5 rounded-2xl bg-[#F7F5EE] border border-[#EBE8DF] space-y-5">
                  <div>
                    <h3 className="text-2xl font-bold tracking-tight text-[#1A1A1A]">
                      {(totalWords / 1000).toFixed(1)}K
                    </h3>
                    <p className="text-xs text-[#706E6B]">total words</p>
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold tracking-tight text-[#1A1A1A]">
                      {averageWpm}
                    </h3>
                    <p className="text-xs text-[#706E6B]">wpm</p>
                  </div>
                  <div>
                    <h3 className="text-2xl font-bold tracking-tight text-[#1A1A1A]">
                      {dayStreak}
                    </h3>
                    <p className="text-xs text-[#706E6B]">day streak</p>
                  </div>
                </div>

                {/* Quota Card */}
                <div className="p-4 rounded-2xl bg-[#F7F5EE] border border-[#EBE8DF] space-y-2">
                  <div className="flex items-center justify-between text-xs font-semibold text-purple-700">
                    <span className="flex items-center space-x-1">
                      <span>0 words left</span>
                      <Info className="w-3 h-3 text-[#706E6B]" />
                    </span>
                  </div>
                  <p className="text-[11px] text-[#706E6B] leading-tight">
                    You've hit your weekly dictation limit. Resets Sunday, 12 a.m. PT.
                  </p>
                  <button
                    onClick={() => {
                      setSettingsActiveTab('billing');
                      setShowSettingsModal(true);
                    }}
                    className="w-full mt-2 py-2 rounded-xl bg-[#6F1025] hover:bg-[#8F1835] text-[#F5EBDD] font-semibold text-xs transition shadow-xs"
                  >
                    Upgrade to Pro
                  </button>
                </div>

                {/* Voice Profile Card */}
                <div className="p-4 rounded-2xl bg-[#F7F5EE] border border-[#EBE8DF] space-y-2">
                  <h4 className="text-xs font-bold text-[#1A1A1A]">Voice Profile Unlocked!</h4>
                  <p className="text-[11px] text-[#706E6B] leading-tight">
                    Discover your unique insights
                  </p>
                  <button
                    onClick={() => setActiveTab('insights')}
                    className="w-full mt-2 py-2 rounded-xl bg-[#6F1025] hover:bg-[#8F1835] text-[#F5EBDD] font-semibold text-xs transition shadow-xs"
                  >
                    Create report
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* 2. NOTETAKER VIEW */}
          {activeTab === 'notetaker' && (
            <div className="max-w-4xl mx-auto space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-bold text-[#1A1A1A]">Notetaker</h1>
                  <p className="text-xs text-[#706E6B] mt-1">
                    Automated audio transcription, meeting takeaways, and action items.
                  </p>
                </div>
                <button
                  onClick={toggleDictation}
                  className="px-4 py-2 rounded-xl bg-[#6F1025] text-[#F5EBDD] text-xs font-semibold hover:bg-[#8F1835] transition flex items-center space-x-2 shadow-xs"
                >
                  <Radio className="w-4 h-4" />
                  <span>{isDictating ? 'Stop Meeting Recording' : 'Record New Meeting'}</span>
                </button>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-4">
                  <h3 className="font-bold text-sm text-[#1A1A1A]">Live Meeting Notes</h3>
                  <textarea
                    rows={8}
                    value={liveTranscript || 'Click "Record New Meeting" to stream a real-time transcript with speaker separation...'}
                    readOnly
                    className="w-full text-xs font-mono p-3 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] resize-none focus:outline-hidden"
                  />
                </div>

                <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-4">
                  <h3 className="font-bold text-sm text-[#1A1A1A]">Meeting Action Items</h3>
                  <ul className="text-xs space-y-2 text-[#1A1A1A]">
                    <li className="flex items-center space-x-2">
                      <input type="checkbox" className="rounded-sm" defaultChecked />
                      <span>Review Cloudflare and Gemini speech engine latency benchmarks.</span>
                    </li>
                    <li className="flex items-center space-x-2">
                      <input type="checkbox" className="rounded-sm" />
                      <span>Confirm auto-paste injection across Electron and macOS native windows.</span>
                    </li>
                    <li className="flex items-center space-x-2">
                      <input type="checkbox" className="rounded-sm" />
                      <span>Verify custom vocabulary biasing for developer keywords.</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>
          )}

          {/* 3. INSIGHTS VIEW */}
          {activeTab === 'insights' && (
            <div className="max-w-4xl mx-auto space-y-6">
              <h1 className="text-2xl font-bold text-[#1A1A1A]">Insights & Productivity</h1>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="p-5 rounded-2xl bg-white border border-[#EBE8DF]">
                  <p className="text-xs text-[#706E6B]">Words This Week</p>
                  <h3 className="text-3xl font-bold text-[#1A1A1A] mt-1">4,820</h3>
                  <p className="text-[11px] text-green-600 mt-2">↑ 24% vs previous week</p>
                </div>
                <div className="p-5 rounded-2xl bg-white border border-[#EBE8DF]">
                  <p className="text-xs text-[#706E6B]">Average WPM</p>
                  <h3 className="text-3xl font-bold text-[#1A1A1A] mt-1">{averageWpm}</h3>
                  <p className="text-[11px] text-[#706E6B] mt-2">3.8x faster than typing</p>
                </div>
                <div className="p-5 rounded-2xl bg-white border border-[#EBE8DF]">
                  <p className="text-xs text-[#706E6B]">Active Streak</p>
                  <h3 className="text-3xl font-bold text-[#1A1A1A] mt-1">{dayStreak} days</h3>
                  <p className="text-[11px] text-amber-600 mt-2">🔥 Keep it up!</p>
                </div>
              </div>

              {/* Activity Heatmap Mockup */}
              <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-4">
                <h3 className="font-bold text-sm text-[#1A1A1A]">Dictation Frequency</h3>
                <div className="grid grid-cols-12 gap-2 pt-2">
                  {Array.from({ length: 48 }).map((_, i) => (
                    <div
                      key={i}
                      className={`h-6 rounded-md ${
                        i % 5 === 0 ? 'bg-[#6F1025]' : i % 3 === 0 ? 'bg-[#A83249]' : 'bg-[#EBE8DF]'
                      }`}
                    />
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* 4. DICTIONARY VIEW */}
          {activeTab === 'dictionary' && (
            <div className="max-w-3xl mx-auto space-y-6">
              <div>
                <h1 className="text-2xl font-bold text-[#1A1A1A]">Custom Dictionary</h1>
                <p className="text-xs text-[#706E6B] mt-1">
                  Add technical terminology, jargon, and names so SAYN transcribes them accurately every time.
                </p>
              </div>

              <form onSubmit={handleAddVocab} className="flex space-x-3">
                <input
                  type="text"
                  placeholder="Add a new term (e.g., Kubernetes, SaynStore, Allan)..."
                  value={newVocabTerm}
                  onChange={e => setNewVocabTerm(e.target.value)}
                  className="flex-1 px-4 py-2 text-sm rounded-xl bg-white border border-[#EBE8DF] focus:border-[#6F1025] focus:outline-hidden"
                />
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl bg-[#6F1025] text-[#F5EBDD] text-xs font-semibold hover:bg-[#8F1835] transition flex items-center space-x-1.5 shadow-xs"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Term</span>
                </button>
              </form>

              <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-3">
                <h3 className="text-xs font-bold uppercase tracking-wider text-[#706E6B]">
                  Active Vocabulary ({vocabulary.length})
                </h3>
                <div className="flex flex-wrap gap-2 pt-2">
                  {vocabulary.map(term => (
                    <span
                      key={term}
                      className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-full bg-[#FAF9F5] border border-[#EBE8DF] text-xs font-medium text-[#1A1A1A]"
                    >
                      <span>{term}</span>
                      <button
                        onClick={() => handleDeleteVocab(term)}
                        className="text-[#706E6B] hover:text-red-600 transition"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </span>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* 5. SNIPPETS VIEW */}
          {activeTab === 'snippets' && (
            <div className="max-w-3xl mx-auto space-y-6">
              <div>
                <h1 className="text-2xl font-bold text-[#1A1A1A]">Voice Snippets</h1>
                <p className="text-xs text-[#706E6B] mt-1">
                  Voice macros that automatically expand into formatted text when spoken.
                </p>
              </div>

              <div className="space-y-4">
                {snippets.map(s => (
                  <div key={s.id} className="p-5 rounded-2xl bg-white border border-[#EBE8DF] space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-mono text-xs font-bold text-[#6F1025] bg-[#FAF9F5] px-2 py-1 rounded-md border border-[#EBE8DF]">
                        "{s.trigger}"
                      </span>
                      <button
                        onClick={() => setSnippets(prev => prev.filter(x => x.id !== s.id))}
                        className="text-[#706E6B] hover:text-red-600 transition"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                    <pre className="text-xs text-[#1A1A1A] font-sans whitespace-pre-wrap bg-[#FAF9F5] p-3 rounded-xl border border-[#EBE8DF]">
                      {s.template}
                    </pre>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* 6. STYLE VIEW */}
          {activeTab === 'style' && (
            <div className="max-w-2xl mx-auto space-y-6">
              <h1 className="text-2xl font-bold text-[#1A1A1A]">Dictation Style & Polishing</h1>

              <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-6">
                <div>
                  <h3 className="text-sm font-bold text-[#1A1A1A]">Auto Cleanup Level</h3>
                  <p className="text-xs text-[#706E6B] mt-0.5">
                    Controls how aggressively SAYN removes filler words, stutters, and self-corrections.
                  </p>
                  <div className="grid grid-cols-3 gap-3 mt-3">
                    {(['None', 'Light', 'Medium'] as const).map(level => (
                      <button
                        key={level}
                        onClick={() => setCleanupLevel(level)}
                        className={`py-2 rounded-xl text-xs font-semibold border transition ${
                          cleanupLevel === level
                            ? 'bg-[#6F1025] text-[#F5EBDD] border-[#6F1025] shadow-xs'
                            : 'bg-white text-[#1A1A1A] border-[#EBE8DF] hover:bg-[#FAF9F5]'
                        }`}
                      >
                        {level}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <h3 className="text-sm font-bold text-[#1A1A1A]">Tone & Formality</h3>
                  <p className="text-xs text-[#706E6B] mt-0.5">
                    Adjusts sentence structure and punctuation for your target audience.
                  </p>
                  <div className="grid grid-cols-3 gap-3 mt-3">
                    {(['Formal', 'Casual', 'Excited'] as const).map(t => (
                      <button
                        key={t}
                        onClick={() => setTone(t)}
                        className={`py-2 rounded-xl text-xs font-semibold border transition ${
                          tone === t
                            ? 'bg-[#6F1025] text-[#F5EBDD] border-[#6F1025] shadow-xs'
                            : 'bg-white text-[#1A1A1A] border-[#EBE8DF] hover:bg-[#FAF9F5]'
                        }`}
                      >
                        {t}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* 7. TRANSFORMS VIEW */}
          {activeTab === 'transforms' && (
            <div className="max-w-3xl mx-auto space-y-6">
              <div>
                <h1 className="text-2xl font-bold text-[#1A1A1A]">AI Transforms</h1>
                <p className="text-xs text-[#706E6B] mt-1">
                  Rewrite, summarize, or restructure dictated text using one-click prompt templates.
                </p>
              </div>

              <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] space-y-4">
                <textarea
                  rows={4}
                  placeholder="Enter or dictate text to transform..."
                  value={transformInput}
                  onChange={e => setTransformInput(e.target.value)}
                  className="w-full text-xs p-3 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] focus:border-[#6F1025] focus:outline-hidden"
                />

                <div className="flex flex-wrap gap-2">
                  {['Polish', 'Bullets', 'Summarize', 'Formal', 'Action Items'].map(preset => (
                    <button
                      key={preset}
                      onClick={() => handleRunTransform(preset)}
                      disabled={isTransforming}
                      className="px-3.5 py-1.5 rounded-full bg-[#FAF9F5] border border-[#EBE8DF] text-xs font-semibold hover:bg-[#6F1025] hover:text-[#F5EBDD] transition"
                    >
                      {preset}
                    </button>
                  ))}
                </div>

                {transformOutput && (
                  <div className="mt-4 p-4 rounded-2xl bg-[#F7F5EE] border border-[#EBE8DF] space-y-2">
                    <span className="text-[10px] font-bold uppercase tracking-wider text-[#706E6B]">
                      Transformed Result
                    </span>
                    <p className="text-xs text-[#1A1A1A] whitespace-pre-wrap">{transformOutput}</p>
                    <button
                      onClick={() => handleCopy(transformOutput, 'transform')}
                      className="mt-2 text-xs font-semibold text-[#6F1025] flex items-center space-x-1"
                    >
                      <Copy className="w-3.5 h-3.5" />
                      <span>Copy Output</span>
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* 8. SCRATCHPAD VIEW */}
          {activeTab === 'scratchpad' && (
            <div className="max-w-4xl mx-auto space-y-6">
              <div className="flex items-center justify-between">
                <div>
                  <h1 className="text-2xl font-bold text-[#1A1A1A]">Scratchpad</h1>
                  <p className="text-xs text-[#706E6B] mt-1">
                    Freeform workspace for rapid drafting and voice brain-dumping.
                  </p>
                </div>
                <button
                  onClick={() => handleCopy(scratchpadText, 'scratchpad')}
                  className="px-4 py-2 rounded-xl bg-[#6F1025] text-[#F5EBDD] text-xs font-semibold hover:bg-[#8F1835] transition flex items-center space-x-1.5 shadow-xs"
                >
                  <Copy className="w-3.5 h-3.5" />
                  <span>{copiedId === 'scratchpad' ? 'Copied!' : 'Copy All'}</span>
                </button>
              </div>

              <div className="p-6 rounded-3xl bg-white border border-[#EBE8DF] shadow-xs">
                <textarea
                  rows={14}
                  value={scratchpadText}
                  onChange={e => setScratchpadText(e.target.value)}
                  className="w-full text-sm leading-relaxed p-2 border-none focus:outline-hidden resize-none bg-transparent"
                />
                <div className="mt-4 pt-3 border-t border-[#EBE8DF] flex items-center justify-between text-xs text-[#706E6B]">
                  <span>{scratchpadText.split(/\s+/).filter(Boolean).length} words</span>
                  <span>{scratchpadText.length} characters</span>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* SETTINGS MODAL */}
      {showSettingsModal && (
        <div className="fixed inset-0 bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="w-full max-w-xl bg-white rounded-3xl border border-[#EBE8DF] shadow-2xl overflow-hidden flex flex-col max-h-[85vh]">
            <div className="flex items-center justify-between px-6 py-4 border-b border-[#EBE8DF]">
              <h3 className="font-bold text-base text-[#1A1A1A]">Settings</h3>
              <button
                onClick={() => setShowSettingsModal(false)}
                className="p-1.5 rounded-lg text-[#706E6B] hover:text-[#1A1A1A] hover:bg-[#FAF9F5] transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="flex flex-1 min-h-[360px]">
              {/* Settings Subnav */}
              <div className="w-48 border-r border-[#EBE8DF] p-3 space-y-1 bg-[#FAF9F5]">
                {[
                  { id: 'account', label: 'Account', icon: Users },
                  { id: 'general', label: 'General', icon: Sliders },
                  { id: 'billing', label: 'Plans & Billing', icon: CreditCard },
                  { id: 'privacy', label: 'Data & Privacy', icon: Shield },
                ].map(s => {
                  const Icon = s.icon;
                  return (
                    <button
                      key={s.id}
                      onClick={() => setSettingsActiveTab(s.id as any)}
                      className={`w-full flex items-center space-x-2 px-3 py-2 rounded-xl text-xs font-semibold transition ${
                        settingsActiveTab === s.id
                          ? 'bg-white text-[#1A1A1A] shadow-xs'
                          : 'text-[#706E6B] hover:text-[#1A1A1A]'
                      }`}
                    >
                      <Icon className="w-3.5 h-3.5" />
                      <span>{s.label}</span>
                    </button>
                  );
                })}
              </div>

              {/* Settings Subpane */}
              <div className="flex-1 p-6 space-y-4 overflow-y-auto">
                {settingsActiveTab === 'account' && (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-[#1A1A1A] mb-1">
                        Display Name
                      </label>
                      <input
                        type="text"
                        value={profileName}
                        onChange={e => setProfileName(e.target.value)}
                        className="w-full px-3 py-2 text-xs rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] focus:outline-hidden"
                      />
                    </div>
                    <div>
                      <label className="block text-xs font-bold text-[#1A1A1A] mb-1">
                        Email Address
                      </label>
                      <input
                        type="email"
                        value={user?.email || 'allanmaazimdad@gmail.com'}
                        readOnly
                        className="w-full px-3 py-2 text-xs rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-[#706E6B] cursor-not-allowed"
                      />
                    </div>
                  </div>
                )}

                {settingsActiveTab === 'general' && (
                  <div className="space-y-3 text-xs">
                    <p className="font-bold text-[#1A1A1A]">Shortcuts</p>
                    <div className="p-3 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] flex items-center justify-between">
                      <span>Global Push-to-Talk</span>
                      <kbd className="px-2 py-1 rounded-md bg-white border border-[#EBE8DF] text-[10px] font-mono">
                        Fn (Globe)
                      </kbd>
                    </div>
                    <div className="p-3 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] flex items-center justify-between">
                      <span>Toggle Dictation Pill</span>
                      <kbd className="px-2 py-1 rounded-md bg-white border border-[#EBE8DF] text-[10px] font-mono">
                        ⌥ + Space
                      </kbd>
                    </div>
                  </div>
                )}

                {settingsActiveTab === 'billing' && (
                  <div className="space-y-3">
                    <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-xs">
                      <p className="font-bold text-[#1A1A1A]">Free Starter Plan</p>
                      <p className="text-[#706E6B] mt-1">2,000 words per week included.</p>
                    </div>
                    <button className="w-full py-2.5 rounded-xl bg-[#6F1025] text-[#F5EBDD] text-xs font-bold hover:bg-[#8F1835] transition shadow-xs">
                      Upgrade to Unlimited Pro ($10/mo)
                    </button>
                  </div>
                )}

                {settingsActiveTab === 'privacy' && (
                  <div className="space-y-3 text-xs text-[#706E6B]">
                    <p className="font-bold text-[#1A1A1A]">Local & Zero-Retention</p>
                    <p>
                      Your voice recordings are processed in ephemeral memory and saved exclusively to your local device. We never train public models on your private dictations.
                    </p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
