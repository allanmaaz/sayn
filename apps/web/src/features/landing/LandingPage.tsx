import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import saynLogo from '../../assets/logo.png';
import {
  Mic,
  PenTool,
  Layers,
  Keyboard,
  Laptop,
  ShieldCheck,
  ArrowRight,
  CheckCircle2,
  Copy,
  Check,
  Download,
  Sparkles,
  Square,
  Play,
  Globe,
  Sliders,
  Maximize2,
  Minimize2,
  Smartphone,
  Monitor,
  Settings,
  Zap,
  Info,
} from 'lucide-react';
import { useTheme } from '../../context/ThemeContext.js';
import { detectDevice, DeviceInfo } from '../../utils/deviceDetector.js';
import { DownloadModal } from '../../components/download/DownloadModal.js';
import { useScrollAnimation } from '../../hooks/useScrollAnimation.js';

export type StudioModeKey = 'ai-writer' | 'voice-mode' | 'grammar' | 'shorten' | 'expand';

export interface StudioModeConfig {
  key: StudioModeKey;
  label: string;
  icon: React.ElementType;
  description: string;
  duration: string;
  rawWords: number;
  refinedWords: number;
  metricBadge: string;
  rawText: string;
  rawHighlightedHtml: React.ReactNode;
  refinedText: string;
}

const STUDIO_MODES: Record<StudioModeKey, StudioModeConfig> = {
  'ai-writer': {
    key: 'ai-writer',
    label: 'AI Writer',
    icon: PenTool,
    description: 'Transforms messy conversational brain-dump into structured, publication-ready prose',
    duration: '00:04',
    rawWords: 34,
    refinedWords: 19,
    metricBadge: '-44% brevity',
    rawText: 'uh yeah basically hey team so um I kind of went through the latest sprint stuff and like the design system thing is pretty much on track to wrap up this Thursday I think',
    rawHighlightedHtml: (
      <>
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">uh yeah</span>{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">basically</span> hey team{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">so um</span> I{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">kind of</span> went through the latest sprint{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">stuff</span> and{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">like</span> the design system{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">thing</span> is{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">pretty much</span> on track to wrap up this Thursday{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">I think</span>.
      </>
    ),
    refinedText:
      'Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday.',
  },
  'voice-mode': {
    key: 'voice-mode',
    label: 'Voice Mode',
    icon: Mic,
    description: 'Ultra-low-latency real-time voice dictation with intelligent auto-punctuation',
    duration: '00:03',
    rawWords: 17,
    refinedWords: 18,
    metricBadge: '220 WPM • 0 latency',
    rawText: 'schedule sync with product design tomorrow 10 am to go over mobile pill window animations and hotkey latency',
    rawHighlightedHtml: (
      <>
        schedule sync with <span className="text-[#F5EBDD] font-medium">Product Design</span>{' '}
        <span className="bg-[#4A1522]/50 px-1 py-0.5 rounded text-[#D9385A]">tomorrow at 10:00 AM</span> to go over mobile pill window animations and hotkey latency.
      </>
    ),
    refinedText:
      'Schedule sync with Product Design tomorrow at 10:00 AM to review mobile pill window animations and hotkey latency.',
  },
  grammar: {
    key: 'grammar',
    label: 'Grammar',
    icon: Sliders,
    description: 'Tone-preserving grammatical refinement fixing agreements, syntax, and commas',
    duration: '00:05',
    rawWords: 17,
    refinedWords: 18,
    metricBadge: '3 syntax errors fixed',
    rawText: 'their is several issues with the auth tokens they doesnt refresh when user is idle for twenty minute',
    rawHighlightedHtml: (
      <>
        <span className="line-through decoration-[#C83E5B] text-[#C83E5B] bg-[#4A1522]/50 px-1 py-0.5 rounded">their is</span> several issues with the auth tokens;{' '}
        <span className="line-through decoration-[#C83E5B] text-[#C83E5B] bg-[#4A1522]/50 px-1 py-0.5 rounded">they doesnt</span> refresh when user is idle for{' '}
        <span className="line-through decoration-[#C83E5B] text-[#C83E5B] bg-[#4A1522]/50 px-1 py-0.5 rounded">twenty minute</span>.
      </>
    ),
    refinedText:
      'There are several issues with the auth tokens; they do not refresh when a user is idle for twenty minutes.',
  },
  shorten: {
    key: 'shorten',
    label: 'Shorten',
    icon: Minimize2,
    description: 'High-density compression for Slack updates, standup notes, and executive summaries',
    duration: '00:06',
    rawWords: 44,
    refinedWords: 16,
    metricBadge: '-64% fluff removed',
    rawText: 'I was thinking that maybe we could potentially look into whether or not we should reduce the amount of dependencies in our node modules because it takes like 4 minutes to install every single time we run a new build pipeline and that slows everyone down',
    rawHighlightedHtml: (
      <>
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">I was thinking that maybe we could potentially look into whether or not we should</span> reduce the amount of dependencies in our node modules{' '}
        <span className="line-through decoration-[#C83E5B] text-[#B59CA2] bg-[#4A1522]/40 px-1 py-0.5 rounded">because it takes like 4 minutes to install every single time we run a new build pipeline and that slows everyone down</span>.
      </>
    ),
    refinedText:
      'Proposal: Audit and prune unused dependencies. Current 4-minute CI install times significantly degrade developer velocity.',
  },
  expand: {
    key: 'expand',
    label: 'Expand',
    icon: Maximize2,
    description: 'Elaborates concise voice bullet points into comprehensive, thoughtful messages',
    duration: '00:02',
    rawWords: 10,
    refinedWords: 29,
    metricBadge: '+190% contextual detail',
    rawText: 'cant make the retro today write up my notes in notion',
    rawHighlightedHtml: (
      <>
        <span className="text-[#C83E5B] font-semibold">cant make</span> the retro today{' '}
        <span className="text-[#C83E5B] font-semibold">write up my notes</span> in notion
      </>
    ),
    refinedText:
      "Hi everyone, I won't be able to attend today's retrospective meeting due to a scheduling conflict. I have documented all my project updates and key blockers directly in Notion for the team to review.",
  },
};

export const LandingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'refine' | 'voice' | 'overlay'>('refine');
  const [copiedDemo, setCopiedDemo] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const [device, setDevice] = useState<DeviceInfo | null>(null);
  const canvasRef = React.useRef<HTMLCanvasElement | null>(null);
  const [manualLaserProg, setManualLaserProg] = useState<number | null>(null);
  const [activeWorkflowStep, setActiveWorkflowStep] = useState<0 | 1 | 2>(0);
  const [typingSimText, setTypingSimText] = useState('Hey team, I revie');
  const { scrollY, scrollProgress } = useScrollAnimation();
  const { actualTheme } = useTheme();
  const isLight = actualTheme === 'light';

  // Interactive Hero Studio States
  const [activeStudioMode, setActiveStudioMode] = useState<StudioModeKey>('ai-writer');
  const [comparisonView, setComparisonView] = useState<'refined' | 'original'>('refined');
  const [isListening, setIsListening] = useState(true);
  const [audioSeconds, setAudioSeconds] = useState(4);
  const [barHeights, setBarHeights] = useState([20, 45, 80, 100, 65, 90, 40, 75, 30]);

  // Chapters & Spine Node dynamic scaling
  const chapterText =
    scrollProgress < 22
      ? 'CH.01 — ACOUSTIC IGNITION'
      : scrollProgress < 58
      ? 'CH.02 — NEURAL LASER PRISM'
      : scrollProgress < 78
      ? 'CH.03 — GROQ LPU CONSTELLATION'
      : 'CH.04 — EPHEMERAL INCINERATOR';

  const spineScale =
    scrollProgress < 22
      ? 1
      : scrollProgress < 58
      ? 1.45
      : scrollProgress < 78
      ? 1.15
      : 0.85;

  // Reversible Pinned Scrollytelling Tracks (Ch.02 Laser Prism, Ch.03 LPU Constellation, Ch.04 Incinerator)
  const prismTrackRef = React.useRef<HTMLElement | null>(null);
  const [scrollLaserProg, setScrollLaserProg] = useState(0);

  const lpuTrackRef = React.useRef<HTMLElement | null>(null);
  const [lpuProg, setLpuProg] = useState(0);

  const privacyTrackRef = React.useRef<HTMLElement | null>(null);
  const [privacyProg, setPrivacyProg] = useState(0);

  React.useEffect(() => {
    const calcTrackProgress = (trackEl: HTMLElement | null, pinTop: number) => {
      if (!trackEl) return 0;
      const rect = trackEl.getBoundingClientRect();
      const stickyChild = trackEl.firstElementChild as HTMLElement | null;
      const cardHeight = stickyChild ? stickyChild.offsetHeight : window.innerHeight * 0.7;
      const totalStickyTravel = Math.max(100, (rect.height - cardHeight) * 0.88);
      return Math.min(1, Math.max(0, (pinTop - rect.top) / totalStickyTravel));
    };

    const onScroll = () => {
      const pinTop = window.innerWidth >= 640 ? 96 : 80;

      // Chapter 02: Neural Laser Prism (180vh track)
      setScrollLaserProg(calcTrackProgress(prismTrackRef.current, pinTop));

      // Chapter 03: Groq LPU Constellation (180vh track)
      setLpuProg(calcTrackProgress(lpuTrackRef.current, pinTop));

      // Chapter 04: Zero Cloud Retention (170vh track)
      setPrivacyProg(calcTrackProgress(privacyTrackRef.current, pinTop));
    };

    window.addEventListener('scroll', onScroll, { passive: true });
    window.addEventListener('resize', onScroll, { passive: true });
    onScroll();
    return () => {
      window.removeEventListener('scroll', onScroll);
      window.removeEventListener('resize', onScroll);
    };
  }, []);

  const prismProg = manualLaserProg !== null ? manualLaserProg : scrollLaserProg;
  const laserLeftPct = 8 + prismProg * 84;

  React.useEffect(() => {
    setDevice(detectDevice());
  }, []);

  // Background Crimson Harmonic Wave Canvas
  React.useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    let animId: number;
    let phase = 0;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();
    window.addEventListener('resize', resize);

    const renderSonicLoom = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      phase += 0.025;
      const curScroll = window.scrollY || 0;

      for (let w = 0; w < 3; w++) {
        ctx.beginPath();
        ctx.strokeStyle =
          w === 0
            ? isLight
              ? 'rgba(168, 50, 73, 0.22)'
              : 'rgba(217, 56, 90, 0.24)'
            : isLight
            ? 'rgba(111, 16, 37, 0.14)'
            : 'rgba(94, 19, 36, 0.25)';
        ctx.lineWidth = w === 0 ? 2 : 1;

        for (let y = 0; y < canvas.height; y += 12) {
          const amp = 28 + w * 18 + Math.sin((y + curScroll) * 0.005) * 20;
          const x = canvas.width / 2 + Math.sin(y * 0.012 + phase + w * 1.4 + curScroll * 0.008) * amp;
          if (y === 0) ctx.moveTo(x, y);
          else ctx.lineTo(x, y);
        }
        ctx.stroke();
      }
      animId = requestAnimationFrame(renderSonicLoom);
    };
    renderSonicLoom();

    return () => {
      window.removeEventListener('resize', resize);
      cancelAnimationFrame(animId);
    };
  }, [isLight]);

  // Typing ticker effect for standard keyboard comparison
  React.useEffect(() => {
    const fullText = 'Hey team, I reviewed the sprint deliverables...';
    let index = 14;
    let forward = true;
    const interval = setInterval(() => {
      if (forward) {
        index++;
        if (index >= fullText.length) {
          forward = false;
        }
      } else {
        index -= 2;
        if (index <= 12) {
          forward = true;
        }
      }
      setTypingSimText(fullText.slice(0, index));
    }, 120);
    return () => clearInterval(interval);
  }, []);


  // Dynamic equalizer soundwave animation (Timer remains fixed on 4 sec as requested)
  React.useEffect(() => {
    if (!isListening) return;
    const interval = setInterval(() => {
      setBarHeights([
        Math.floor(20 + Math.random() * 40),
        Math.floor(35 + Math.random() * 55),
        Math.floor(60 + Math.random() * 40),
        Math.floor(80 + Math.random() * 20),
        Math.floor(50 + Math.random() * 45),
        Math.floor(70 + Math.random() * 30),
        Math.floor(30 + Math.random() * 50),
        Math.floor(55 + Math.random() * 45),
        Math.floor(25 + Math.random() * 40),
      ]);
    }, 450);
    return () => clearInterval(interval);
  }, [isListening]);

  const handleSelectMode = (key: StudioModeKey) => {
    setActiveStudioMode(key);
    setAudioSeconds(4);
    setIsListening(true);
  };

  const currentModeConfig = STUDIO_MODES[activeStudioMode];

  const handleCopyDemo = () => {
    const textToCopy =
      comparisonView === 'original'
        ? currentModeConfig.rawText
        : currentModeConfig.refinedText;
    navigator.clipboard.writeText(textToCopy);
    setCopiedDemo(true);
    setTimeout(() => setCopiedDemo(false), 2000);
  };

  return (
    <div
      className={`flex-1 flex flex-col relative overflow-x-clip transition-colors duration-300 ${
        isLight ? 'bg-[#FAF7F2] text-[#2D0A12]' : 'bg-[#100205] text-[#F6EFE8]'
      }`}
    >
      {/* Background Crimson Harmonic Wave Canvas */}
      <canvas
        ref={canvasRef}
        className="fixed inset-0 w-screen h-screen pointer-events-none z-0"
      />

      {/* Central Traveling Spine Line */}
      <div
        className={`fixed top-0 left-1/2 -translate-x-1/2 w-[1px] h-screen pointer-events-none z-[1] transition-opacity duration-300 ${
          isLight
            ? 'bg-gradient-to-b from-transparent via-[#A83249]/20 to-transparent'
            : 'bg-gradient-to-b from-transparent via-[#D9385A]/25 to-transparent'
        }`}
      />

      {/* Glowing Sonic Core Node */}
      <div
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-3.5 h-3.5 rounded-full pointer-events-none z-[2] transition-transform duration-300 ease-out"
        style={{
          backgroundColor: isLight ? '#6F1025' : '#F6EFE8',
          boxShadow: isLight
            ? '0 0 20px 6px rgba(168,50,73,0.45), 0 0 50px 14px rgba(111,16,37,0.25)'
            : '0 0 25px 8px #D9385A, 0 0 60px 18px #5E1324',
          transform: `translate(-50%, -50%) scale(${spineScale})`,
        }}
      />

      {/* 1. HERO SECTION (Responsive: Mobile iPhone Mockup & Desktop Laptop Showcase) */}
      <section className="relative pt-20 pb-16 sm:pt-24 sm:pb-24 md:pt-28 md:pb-28 overflow-hidden">
        {/* Flowing Crimson/Maroon Silk Wave Ribbons (matching mobile mockup) */}
        <div className="absolute inset-0 pointer-events-none overflow-hidden select-none">
          <svg
            className="w-full h-full opacity-65 sm:opacity-40"
            viewBox="0 0 430 932"
            fill="none"
            preserveAspectRatio="xMidYMid slice"
            xmlns="http://www.w3.org/2000/svg"
          >
            <defs>
              <linearGradient id="silk-ribbon-1" x1="100%" y1="10%" x2="0%" y2="90%">
                <stop offset="0%" stopColor="#A83249" stopOpacity="0.75" />
                <stop offset="30%" stopColor="#6F1025" stopOpacity="0.5" />
                <stop offset="70%" stopColor="#8A1731" stopOpacity="0.3" />
                <stop offset="100%" stopColor="#100709" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="silk-ribbon-2" x1="100%" y1="25%" x2="10%" y2="85%">
                <stop offset="0%" stopColor="#FF4D6D" stopOpacity="0.55" />
                <stop offset="45%" stopColor="#A83249" stopOpacity="0.4" />
                <stop offset="100%" stopColor="#100709" stopOpacity="0" />
              </linearGradient>
              <linearGradient id="silk-ribbon-3" x1="0%" y1="40%" x2="100%" y2="80%">
                <stop offset="0%" stopColor="#A83249" stopOpacity="0.35" />
                <stop offset="50%" stopColor="#6F1025" stopOpacity="0.5" />
                <stop offset="100%" stopColor="#100709" stopOpacity="0" />
              </linearGradient>
              <filter id="ribbon-blur" x="-20%" y="-20%" width="140%" height="140%">
                <feGaussianBlur stdDeviation="1.5" />
              </filter>
            </defs>

            {/* Primary flowing ribbon curves */}
            <path
              d="M 450,180 C 370,270 240,320 280,470 C 330,620 420,670 380,920"
              stroke="url(#silk-ribbon-1)"
              strokeWidth="2"
              filter="url(#ribbon-blur)"
            />
            <path
              d="M 460,210 C 350,300 220,350 260,500 C 310,650 390,710 350,950"
              stroke="url(#silk-ribbon-2)"
              strokeWidth="1.2"
            />
            <path
              d="M 480,240 C 330,340 200,390 240,540 C 290,690 370,750 330,980"
              stroke="url(#silk-ribbon-1)"
              strokeWidth="1.5"
            />
            <path
              d="M 430,140 C 300,240 180,360 220,580 C 260,760 360,820 300,1020"
              stroke="url(#silk-ribbon-2)"
              strokeWidth="1.8"
            />
            
            {/* Left-side subtle cross-ribbons */}
            <path
              d="M -30,380 C 80,480 140,600 90,780 C 50,920 180,990 320,1050"
              stroke="url(#silk-ribbon-3)"
              strokeWidth="1.5"
            />
            <path
              d="M -50,420 C 60,520 110,640 70,820 C 30,960 160,1020 300,1080"
              stroke="url(#silk-ribbon-1)"
              strokeWidth="1"
            />
          </svg>
        </div>

        {/* Ambient Maroon Specular Lighting Glows with Scroll Parallax */}
        <div
          className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[550px] h-[550px] bg-[#6F1025]/25 rounded-full blur-[140px] pointer-events-none transition-transform duration-100 ease-out"
          style={{ transform: `translate(-50%, calc(-50% + ${scrollY * 0.12}px))` }}
        />
        <div
          className="absolute bottom-10 right-10 w-[600px] h-[600px] bg-[#A83249]/20 rounded-full blur-[160px] pointer-events-none transition-transform duration-100 ease-out"
          style={{ transform: `translateY(${-scrollY * 0.15}px)` }}
        />
        <div
          className="absolute top-1/2 right-1/4 w-[400px] h-[400px] bg-[#6F1025]/15 rounded-full blur-[120px] pointer-events-none transition-transform duration-100 ease-out"
          style={{ transform: `translateY(${scrollY * 0.08}px)` }}
        />

        <div className="max-w-7xl mx-auto px-5 sm:px-6 lg:px-8 relative z-10">
          {/* ========================================================================= */}
          {/* 1A. MOBILE VIEW (Matches user's iPhone screenshot on mobile viewports) */}
          {/* ========================================================================= */}
          <div className="lg:hidden text-left max-w-sm mx-auto">
            {/* Tagline Pill */}
            <div className="inline-flex items-center space-x-2 px-3 py-1.5 rounded-full bg-[#18080E]/90 border border-[#A83249]/40 shadow-[0_0_15px_rgba(168,50,73,0.25)] mb-6">
              <span className="flex items-center space-x-0.5 text-[#A83249]">
                <span className="w-0.5 h-2.5 bg-[#A83249] rounded-full animate-pulse" />
                <span className="w-0.5 h-3.5 bg-[#F5EBDD] rounded-full animate-pulse delay-75" />
                <span className="w-0.5 h-2 bg-[#A83249] rounded-full animate-pulse delay-150" />
              </span>
              <span className="text-[11px] font-semibold tracking-wide text-[#A83249]">
                Say it. Refine it. Send it.
              </span>
            </div>

            {/* Primary Headline */}
            <h1 className="text-5xl font-extrabold tracking-tight text-[#F5EBDD] leading-[1.05] mb-5">
              Your voice.<br />
              Your words.<br />
              <span className="font-serif-instrument italic text-[#C83E5B] text-[1.12em] block sm:inline">Better.</span>
            </h1>

            {/* Subtitle */}
            <p className="text-[15px] text-[#D6C7B2] leading-relaxed mb-6 font-normal">
              Speak naturally. Write better.<br />
              Get your time back.
            </p>

            {/* Primary Pill Button */}
            <button
              onClick={() => setIsDownloadOpen(true)}
              className="w-full inline-flex items-center justify-between px-6 py-3.5 rounded-full font-bold text-sm bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_24px_rgba(245,235,221,0.25)] mb-3"
            >
              <span>Try SAYN Free</span>
              <ArrowRight className="w-4 h-4 stroke-[2.5]" />
            </button>

            {/* Secondary Text Link */}
            <div className="mb-8">
              <a
                href="#how-it-works"
                className="inline-flex items-center space-x-1.5 text-xs text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors group"
              >
                <span className="underline underline-offset-4 decoration-[#D6C7B2]/40 group-hover:decoration-[#F5EBDD]">See how it works</span>
                <span className="group-hover:translate-x-0.5 transition-transform">→</span>
              </a>
            </div>

            {/* Smartphone Showcase (iPhone in 3D Perspective) */}
            <div
              className="relative w-full max-w-[340px] mx-auto mt-2 transition-transform duration-300 ease-out"
              style={{
                transform: `perspective(1000px) rotateX(${Math.max(0, Math.min(6, 4 - scrollY * 0.01))}deg) rotateY(-3deg) rotateZ(-1deg)`,
              }}
            >
              {/* Outer Phone Bezel Chassis */}
              <div className="relative rounded-[38px] bg-[#17080F] border-[3.5px] border-[#3D1520] shadow-[0_24px_60px_rgba(0,0,0,0.9),0_0_35px_rgba(111,16,37,0.35)] p-2.5 pb-0 overflow-hidden">
                {/* Specular Rim Glow */}
                <div className="absolute inset-0 rounded-[35px] pointer-events-none ring-1 ring-inset ring-[#F5EBDD]/10" />

                {/* Screen Area */}
                <div className="p-3 pt-2 pb-5 rounded-[30px] bg-gradient-to-b from-[#18080E] via-[#100709] to-[#15070B] min-h-[460px] flex flex-col justify-between relative overflow-hidden">
                  {/* Dynamic Island */}
                  <div className="w-24 h-4 bg-black rounded-full mx-auto mb-3 shadow-inner flex items-center justify-center">
                    <div className="w-2 h-2 rounded-full bg-[#181818] mr-2" />
                  </div>

                  {/* Screen Header Row */}
                  <div className="flex items-center justify-between px-2 mb-3">
                    <div className="flex items-center space-x-1.5">
                      <img src={saynLogo} alt="SAYN" className="w-5 h-5 rounded-md" />
                      <span className="font-extrabold text-xs tracking-wider text-[#F5EBDD]">SAYN</span>
                    </div>
                    <div className="p-1 rounded-full text-[#D6C7B2]/70 hover:text-[#F5EBDD]">
                      <Settings className="w-4 h-4 stroke-[2]" />
                    </div>
                  </div>

                  {/* Timer */}
                  <div className="text-center text-xs font-mono font-medium text-[#D6C7B2] tracking-wider mb-2">
                    00:04
                  </div>

                  {/* Pulsing Audio Waveform Equalizer */}
                  <div className="flex items-center justify-center space-x-1 h-11 mb-3 px-3">
                    {[16, 26, 38, 52, 68, 84, 96, 100, 92, 100, 96, 84, 68, 52, 38, 26, 16].map((h, i) => (
                      <div
                        key={i}
                        className="w-[2.5px] rounded-full bg-[#A83249]"
                        style={{
                          height: `${h}%`,
                          animation: 'pulse 1.3s ease-in-out infinite',
                          animationDelay: `${Math.abs(8 - i) * 75}ms`,
                        }}
                      />
                    ))}
                  </div>

                  {/* Pause Button */}
                  <div className="flex justify-center mb-5">
                    <div className="w-9 h-9 rounded-full bg-[#6F1025] shadow-[0_0_18px_rgba(111,16,37,0.7)] flex items-center justify-center text-[#F5EBDD] cursor-pointer hover:bg-[#8F1835] active:scale-95 transition-all">
                      <div className="flex items-center space-x-1">
                        <div className="w-1 h-3 bg-[#F5EBDD] rounded-sm" />
                        <div className="w-1 h-3 bg-[#F5EBDD] rounded-sm" />
                      </div>
                    </div>
                  </div>

                  {/* Floating Card Overlapping Lower Screen */}
                  <div className="rounded-2xl bg-[#180B10]/92 backdrop-blur-xl border border-[#A83249]/50 shadow-[0_16px_40px_rgba(16,7,9,0.95),0_0_20px_rgba(111,16,37,0.25)] p-4 relative z-10">
                    {/* Original Section */}
                    <div className="mb-2">
                      <div className="text-[10px] uppercase font-semibold tracking-wider text-[#A89F91] mb-1">
                        Original
                      </div>
                      <p className="text-xs text-[#9E9085] leading-relaxed font-normal">
                        hey so basically i checked the sprint tasks and design stuff is pretty much done by thursday probably
                      </p>
                    </div>

                    {/* Downward Arrow Divider */}
                    <div className="flex justify-center my-1.5">
                      <span className="text-[#A83249] text-xs font-bold">↓</span>
                    </div>

                    {/* Refined Section */}
                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <div className="text-xs font-bold tracking-wide">
                          <span className="text-[#F5EBDD]">Re</span>
                          <span className="text-[#C83E58]">fined by SAYN</span>
                        </div>
                        <button
                          onClick={handleCopyDemo}
                          className="p-1 rounded text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors"
                          title="Copy refined text"
                          aria-label="Copy refined text"
                        >
                          {copiedDemo ? (
                            <Check className="w-3.5 h-3.5 text-[#30D158]" />
                          ) : (
                            <Copy className="w-3.5 h-3.5" />
                          )}
                        </button>
                      </div>
                      <p className="text-xs text-[#F5EBDD] leading-relaxed font-normal">
                        Hey team, I reviewed the latest sprint deliverables. The design system work is largely complete by Thursday.
                      </p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* ========================================================================= */}
          {/* 1B. DESKTOP VIEW (Two-column layout with 3D Laptop Studio on lg screens) */}
          {/* ========================================================================= */}
          <div className="hidden lg:grid grid-cols-12 gap-8 items-center">
            {/* Left Hero Column: Typography & CTAs */}
            <div className="col-span-6 text-left">
              {/* Tagline Pill */}
              <div className="inline-flex items-center space-x-2.5 px-4 py-1.5 rounded-full bg-[#180B0F] border border-[#A83249]/50 shadow-[0_0_20px_rgba(111,16,37,0.3)] mb-8 animate-in fade-in slide-in-from-bottom-2 duration-300">
                <span className="flex items-center space-x-0.5 text-[#A83249]">
                  <span className="w-1 h-3 bg-[#A83249] rounded-full animate-pulse" />
                  <span className="w-1 h-4 bg-[#F5EBDD] rounded-full animate-pulse delay-75" />
                  <span className="w-1 h-2 bg-[#A83249] rounded-full animate-pulse delay-150" />
                </span>
                <span className="text-xs font-semibold tracking-wide text-[#A83249]">
                  Say it. Refine it. Send it.
                </span>
              </div>

              {/* Primary Headline */}
              <h1 className="text-6xl lg:text-7xl font-extrabold tracking-tight text-[#F5EBDD] leading-[1.06] mb-6">
                Your voice.<br />
                Your words.<br />
                <span className="font-serif-instrument italic text-[#C83E5B] text-[1.12em] block">Better.</span>
              </h1>

              {/* Supporting Copy */}
              <p className="max-w-xl text-base sm:text-lg text-[#D6C7B2] leading-relaxed mb-9">
                Speak naturally. Write better. Get your time back. Communicate effortlessly across Mac, Windows, Android, and Web.
              </p>

              {/* Dynamic Auto-Detected Action CTAs */}
              <div className="flex items-center gap-4 mb-8">
                {/* Primary Warm Cream Button */}
                <button
                  onClick={() => setIsDownloadOpen(true)}
                  className={`inline-flex items-center justify-center space-x-2.5 px-7 py-3.5 rounded-full font-bold text-sm active:scale-95 transition-all shadow-md ${
                    isLight
                      ? 'bg-[#6F1025] hover:bg-[#85162E] text-[#F5EBDD] shadow-[0_4px_24px_rgba(111,16,37,0.25)]'
                      : 'bg-[#F5EBDD] hover:bg-[#FAF4EB] text-[#100709] shadow-[0_4px_24px_rgba(245,235,221,0.25)]'
                  }`}
                >
                  <Download className="w-4 h-4 stroke-[2.5]" />
                  <span>
                    Download for {device?.osName || 'macOS'}
                  </span>
                </button>

                {/* Secondary Maroon Bordered Button */}
                <a
                  href="#how-it-works"
                  className={`inline-flex items-center justify-center space-x-2 px-7 py-3.5 rounded-full font-semibold text-sm transition-all shadow-xs ${
                    isLight
                      ? 'text-[#2D0A12] bg-white border border-[#E2D9CD] hover:border-[#6F1025]'
                      : 'text-[#F5EBDD] bg-[#100709] border border-[#A83249] hover:bg-[#6F1025]/30 hover:border-[#F5EBDD]/40'
                  }`}
                >
                  <span>See How It Works</span>
                  <ArrowRight className="w-4 h-4" />
                </a>
              </div>

              {/* Platform Badges Row */}
              <div className="flex items-center space-x-6 text-xs text-[#D6C7B2] font-medium pt-2">
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <Laptop className="w-3.5 h-3.5 text-[#A83249]" />
                  <span>macOS</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <Monitor className="w-3.5 h-3.5 text-[#A83249]" />
                  <span>Windows</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <Smartphone className="w-3.5 h-3.5 text-[#A83249]" />
                  <span>Android</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <Globe className="w-3.5 h-3.5 text-[#A83249]" />
                  <span>Web</span>
                </span>
              </div>
            </div>

            {/* Right Hero Column: 3D Laptop Studio Showcase with Scroll Tilt */}
            <div
              className="col-span-6 relative transition-transform duration-200 ease-out"
              style={{
                transform: `perspective(1000px) rotateX(${Math.max(-4, Math.min(8, (scrollY - 100) * 0.02))}deg) translateY(${Math.min(30, scrollY * 0.06)}px)`,
              }}
            >
              {/* Laptop Chassis Outer Frame */}
              <div className="relative mx-auto max-w-[560px] rounded-t-[20px] bg-[#1D0C13] border-4 border-[#3D1520] shadow-[0_24px_60px_rgba(111,16,37,0.45)] overflow-hidden">
                {/* Screen Top Bezel with Camera Dot */}
                <div className="h-6 bg-[#14080D] flex items-center justify-center px-4 border-b border-[#3D1520]/50 relative">
                  <div className="w-2 h-2 rounded-full bg-[#3D1520] flex items-center justify-center">
                    <div className="w-1 h-1 rounded-full bg-[#100709]" />
                  </div>
                </div>

                {/* Inner Screen Display (SAYN Studio App) */}
                <div className="p-4 bg-[#14080D] min-h-[340px] flex flex-col justify-between">
                  {/* Top Studio Header */}
                  <div className="flex items-center justify-between pb-3 border-b border-[#3D1520]/60 mb-3">
                    <div className="flex items-center space-x-2">
                      <img src={saynLogo} alt="SAYN Logo" className="w-6 h-6 rounded-md" />
                      <span className="font-bold text-sm tracking-wide text-[#F5EBDD]">SAYN</span>
                    </div>
                    <div className="flex items-center space-x-1.5">
                      <div className="w-2.5 h-2.5 rounded-full bg-[#3D1520]" />
                      <div className="w-2.5 h-2.5 rounded-full bg-[#3D1520]" />
                      <div className="w-2.5 h-2.5 rounded-full bg-[#3D1520]" />
                    </div>
                  </div>

                  {/* Studio Main Workspace Grid */}
                  <div className="grid grid-cols-12 gap-3 items-stretch">
                    {/* Left Mini Sidebar - Interactive Navigation */}
                    <div className="col-span-3 space-y-1.5 text-left text-[11px]">
                      {(Object.keys(STUDIO_MODES) as StudioModeKey[]).map((modeKey) => {
                        const mode = STUDIO_MODES[modeKey];
                        const Icon = mode.icon;
                        const isSelected = activeStudioMode === modeKey;
                        return (
                          <button
                            key={modeKey}
                            onClick={() => handleSelectMode(modeKey)}
                            className={`w-full flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg font-semibold text-left transition-all active:scale-95 ${
                              isSelected
                                ? 'bg-[#6F1025] text-[#F5EBDD] shadow-md ring-1 ring-[#A83249]/60'
                                : 'text-[#D6C7B2] hover:bg-[#240F16] hover:text-[#F5EBDD]'
                            }`}
                          >
                            <Icon className={`w-3 h-3 ${isSelected ? 'text-[#F5EBDD]' : 'text-[#A83249]'}`} />
                            <span className="truncate">{mode.label}</span>
                          </button>
                        );
                      })}
                    </div>

                    {/* Center Voice Waveform Card with Soundwave (Timer locked at 00:04) */}
                    <div className="col-span-4 rounded-xl bg-[#1C0B12] border border-[#3D1520] p-3 flex flex-col items-center justify-between text-center shadow-inner">
                      <div className="text-[11px] font-mono font-bold text-[#F5EBDD]">
                        00:04
                      </div>

                      {/* Equalizer Soundwave Bars Reacting Dynamically */}
                      <div className="flex items-center justify-center space-x-1 h-12 my-1">
                        {barHeights.map((h, i) => (
                          <div
                            key={i}
                            className={`w-1 rounded-full transition-all duration-200 ${
                              isListening ? 'bg-[#C83E5B]' : 'bg-[#4A1522]'
                            }`}
                            style={{
                              height: isListening ? `${h}%` : '15%',
                            }}
                          />
                        ))}
                      </div>

                      <div className="text-[10px] text-[#D6C7B2] mb-1 font-medium flex items-center space-x-1.5">
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${
                            isListening ? 'bg-[#22C55E] animate-pulse' : 'bg-[#A89F91]'
                          }`}
                        />
                        <span className="truncate text-[9.5px]">
                          {isListening ? 'Listening...' : 'Paused — Tap to speak'}
                        </span>
                      </div>

                      {/* Deep Maroon Stop/Play Button */}
                      <button
                        onClick={() => setIsListening(!isListening)}
                        title={isListening ? 'Pause listening' : 'Start dictation'}
                        className={`w-7 h-7 rounded-full text-[#F5EBDD] flex items-center justify-center shadow-md transition-all hover:scale-110 active:scale-95 ${
                          isListening
                            ? 'bg-[#6F1025] hover:bg-[#8F1835]'
                            : 'bg-[#22C55E] hover:bg-[#16a34a]'
                        }`}
                      >
                        {isListening ? (
                          <Square className="w-2.5 h-2.5 fill-current" />
                        ) : (
                          <Play className="w-2.5 h-2.5 fill-current ml-0.5" />
                        )}
                      </button>
                    </div>

                    {/* Right Refined Output Card with Original & Refined Toggles */}
                    <div className="col-span-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] p-3 flex flex-col justify-between text-left">
                      {/* Segmented Original / Refined Switcher */}
                      <div className="flex items-center justify-end space-x-1 mb-2">
                        <button
                          onClick={() => setComparisonView('original')}
                          className={`px-1.5 py-0.5 rounded text-[9.5px] transition-colors ${
                            comparisonView === 'original'
                              ? 'bg-[#F5EBDD] text-[#100709] font-bold shadow-xs'
                              : 'text-[#A89F91] hover:text-[#F5EBDD]'
                          }`}
                        >
                          Original
                        </button>
                        <button
                          onClick={() => setComparisonView('refined')}
                          className={`px-1.5 py-0.5 rounded text-[9.5px] transition-colors ${
                            comparisonView === 'refined'
                              ? 'bg-[#F5EBDD] text-[#100709] font-bold shadow-xs'
                              : 'text-[#A89F91] hover:text-[#F5EBDD]'
                          }`}
                        >
                          Refined
                        </button>
                      </div>

                      {/* Output Display Based on Selected View */}
                      <div className="flex-1 flex flex-col justify-center min-h-[95px] mb-2">
                        {comparisonView === 'original' ? (
                          <div className="space-y-1">
                            <div className="flex items-center justify-between text-[9px] font-mono text-[#D9385A]">
                              <span>RAW SPOKEN STREAM</span>
                              <span className="text-[#A89F91]">{currentModeConfig.rawWords} words</span>
                            </div>
                            <p className="text-[10.5px] text-[#D6C7B2] leading-relaxed">
                              "{currentModeConfig.rawHighlightedHtml}"
                            </p>
                          </div>
                        ) : (
                          <div className="space-y-1">
                            <div className="flex items-center justify-between text-[9px] font-mono text-[#22C55E]">
                              <span>REFINED OUTPUT</span>
                              <span className="text-[#F5EBDD] bg-[#6F1025] px-1.5 py-0.5 rounded text-[8.5px] font-sans font-semibold">
                                {currentModeConfig.metricBadge}
                              </span>
                            </div>
                            <p className="text-[11px] text-[#F5EBDD] leading-relaxed font-medium">
                              "{currentModeConfig.refinedText}"
                            </p>
                          </div>
                        )}
                      </div>

                      {/* Footer Actions: Ready Indicator & Interactive Copy */}
                      <div className="flex items-center justify-between pt-1 border-t border-[#3D1520]/50 text-[10px] text-[#A83249]">
                        <span className="flex items-center space-x-1">
                          <CheckCircle2 className="w-3 h-3 text-[#30D158]" />
                          <span className="text-[#F5EBDD]/90 text-[9.5px]">
                            {comparisonView === 'original' ? 'Raw Voice' : 'Ready to paste'}
                          </span>
                        </span>
                        <button
                          onClick={handleCopyDemo}
                          className="hover:text-[#F5EBDD] flex items-center space-x-1 px-1.5 py-0.5 rounded hover:bg-[#2D0A14] transition-colors"
                        >
                          {copiedDemo ? (
                            <Check className="w-2.5 h-2.5 text-[#30D158]" />
                          ) : (
                            <Copy className="w-2.5 h-2.5" />
                          )}
                          <span>{copiedDemo ? 'Copied' : 'Copy'}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Laptop Keyboard Base & Hinge */}
              <div className="mx-auto max-w-[620px] h-3 bg-gradient-to-b from-[#2E141D] to-[#14080D] rounded-b-[14px] shadow-2xl border-t border-[#3D1520]/80 relative">
                <div className="w-20 h-1 bg-[#100709] rounded-b-sm mx-auto" />
              </div>
            </div>
          </div>
        </div>

        {/* Scroll-Driven SVG Speech Transformation Ribbon Under Hero */}
        <div className="relative w-full max-w-6xl mx-auto pt-10 pb-4 px-4 overflow-visible">
          <div className="flex justify-center mb-3">
            <div
              className={`inline-flex items-center space-x-2.5 px-5 py-2 rounded-full border shadow-lg backdrop-blur-xl text-xs font-semibold ${
                isLight
                  ? 'bg-white/95 border-[#E2D9CD] text-[#2D0A12] shadow-[0_4px_20px_rgba(111,16,37,0.1)]'
                  : 'bg-[#1C060B]/90 border-[#C83E5B]/50 text-[#F5EBDD] shadow-[0_0_30px_rgba(200,62,91,0.35)]'
              }`}
            >
              <span className="flex items-center space-x-1 text-[#A83249]">
                <span className="w-1 h-3 bg-[#A83249] rounded-full animate-pulse" />
                <span className="w-1 h-4 bg-[#F5EBDD] rounded-full animate-pulse delay-75" />
                <span className="w-1 h-2 bg-[#A83249] rounded-full animate-pulse delay-150" />
              </span>
              <span>SAYN Live Voice Stream</span>
            </div>
          </div>

          <div className="relative w-full h-[115px] overflow-visible select-none">
            <svg viewBox="0 0 1200 120" className="w-full h-full overflow-visible">
              <defs>
                <path id="rawSpeechPath" d="M -80,95 C 180,105 350,25 600,65" />
                <path id="refinedSpeechPath" d="M 600,65 C 850,105 1020,25 1280,35" />
              </defs>
              <path
                d="M -80,95 C 180,105 350,25 600,65"
                fill="none"
                stroke={isLight ? '#E2D9CD' : '#4A1522'}
                strokeWidth="1.5"
                strokeDasharray="5,5"
              />
              <path
                d="M 600,65 C 850,105 1020,25 1280,35"
                fill="none"
                stroke={isLight ? '#F0E2D4' : '#5E1324'}
                strokeWidth="24"
                strokeLinecap="round"
              />
              <text fill={isLight ? '#7A6B63' : '#B59CA2'} fontSize="13" fontStyle="italic">
                <textPath href="#rawSpeechPath" startOffset={`${-15 + ((scrollY * 0.08) % 40)}%`}>
                  uh hey team so I was looking at the sprint stuff and I think the design migration is good for Thursday...
                </textPath>
              </text>
              <text fill={isLight ? '#2D0A12' : '#F5EFE6'} fontSize="13" fontWeight="700">
                <textPath href="#refinedSpeechPath" startOffset={`${Math.max(0, 25 - ((scrollY * 0.04) % 30))}%`}>
                  "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for Thursday."
                </textPath>
              </text>
            </svg>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* CHAPTER 02: THE NEURAL LASER PRISM (Sticky Reversible Scrollytelling Track) */}
      {/* ========================================================================= */}
      <section id="laser-prism" ref={prismTrackRef} className="relative h-[180vh] max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 my-8 z-10">
        <div className="sticky top-20 sm:top-24 h-auto">
          <div
            className={`rounded-3xl sm:rounded-[38px] p-6 sm:p-12 border shadow-2xl relative overflow-hidden transition-all ${
            isLight
              ? 'bg-gradient-to-b from-[#FFFDF9] via-[#FAF4EB] to-[#F5EFE6] border-[#E2D9CD] shadow-[0_20px_50px_rgba(111,16,37,0.08)]'
              : 'bg-gradient-to-b from-[#1C060B] via-[#150408] to-[#100205] border-[#4A1522] shadow-[0_30px_80px_rgba(0,0,0,0.85)]'
          }`}
        >
          {/* Header */}
          <div className="text-center max-w-2xl mx-auto mb-10">
            <span className="text-xs font-bold uppercase tracking-widest text-[#C83E5B] mb-2 block font-mono">
              CH.02 — REAL-TIME DISFLUENCY SHREDDER
            </span>
            <h2
              className={`text-3xl sm:text-4xl font-extrabold tracking-tight mb-3 ${
                isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
              }`}
            >
              The Neural{' '}
              <span className="font-serif-instrument italic text-[#C83E5B]">
                Laser Prism
              </span>
            </h2>
            <p
              className={`text-xs sm:text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              Drag the laser scrubber below to watch filler tokens vaporize into crisp, executive prose in real time.
            </p>
          </div>

          {/* Scrubber Stage */}
          <div
            className={`relative p-8 sm:p-10 rounded-2xl sm:rounded-3xl border select-none transition-all ${
              isLight
                ? 'bg-white border-[#E2D9CD] shadow-inner'
                : 'bg-[#100205] border-[#3D1520] shadow-inner'
            }`}
          >
            {/* The Vertical Crimson Laser Line */}
            <div
              className="absolute top-0 bottom-0 w-[2px] pointer-events-none transition-all duration-75 ease-out z-20"
              style={{
                left: `${laserLeftPct}%`,
                background: 'linear-gradient(to bottom, #FF4D73, #C83E5B, #6F1025)',
                boxShadow: '0 0 16px 3px rgba(200, 62, 91, 0.8), 0 0 30px 6px rgba(200, 62, 91, 0.4)',
              }}
            >
              <div className="absolute -top-3 -translate-x-1/2 left-1/2 px-2 py-0.5 rounded-full bg-[#C83E5B] text-white text-[10px] font-mono font-bold whitespace-nowrap shadow-md">
                LASER {Math.round(prismProg * 100)}%
              </div>
            </div>

            {/* Kinetic Sentence with Vaporizing Filler Tokens */}
            <div
              className={`font-serif-instrument text-2xl sm:text-3xl md:text-4xl leading-relaxed text-center sm:text-left transition-all relative z-10 ${
                isLight ? 'text-[#2D0A12]' : 'text-[#F5EFE6]'
              }`}
            >
              “Hey team,{' '}
              <span
                className={`inline-block transition-all duration-300 ${
                  prismProg > 0.2
                    ? 'line-through text-[#C83E5B] opacity-20 scale-90 blur-[1px]'
                    : 'text-[#C83E5B] opacity-90'
                }`}
              >
                um like
              </span>{' '}
              I reviewed the latest sprint deliverables.{' '}
              <span
                className={`inline-block transition-all duration-300 ${
                  prismProg > 0.4
                    ? 'line-through text-[#C83E5B] opacity-20 scale-90 blur-[1px]'
                    : 'text-[#C83E5B] opacity-90'
                }`}
              >
                You know,
              </span>{' '}
              the design system migration is{' '}
              <span
                className={`inline-block transition-all duration-300 ${
                  prismProg > 0.6
                    ? 'line-through text-[#C83E5B] opacity-20 scale-90 blur-[1px]'
                    : 'text-[#C83E5B] opacity-90'
                }`}
              >
                basically
              </span>{' '}
              on track for Thursday.{' '}
              <span
                className={`inline-block transition-all duration-300 ${
                  prismProg > 0.8
                    ? 'line-through text-[#C83E5B] opacity-20 scale-90 blur-[1px]'
                    : 'text-[#C83E5B] opacity-90'
                }`}
              >
                uh actually
              </span>{' '}
              Zero paywalls or word limits.”
            </div>

            {/* Slider Control Bar */}
            <div className="mt-8 pt-6 border-t border-[#3D1520]/50 flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="w-full sm:w-2/3 flex items-center space-x-4">
                <span className="text-[11px] font-mono text-[#A89F91] whitespace-nowrap">
                  RAW SPEECH
                </span>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.01"
                  value={prismProg}
                  onChange={(e) => setManualLaserProg(parseFloat(e.target.value))}
                  className="w-full accent-[#C83E5B] cursor-ew-resize h-1.5 bg-[#3D1520] rounded-lg"
                />
                <span className="text-[11px] font-mono text-[#C83E5B] font-bold whitespace-nowrap">
                  REFINED
                </span>
              </div>

              <button
                onClick={() => setManualLaserProg(manualLaserProg === 1 ? 0 : 1)}
                className="px-4 py-1.5 rounded-full text-xs font-bold bg-[#C83E5B]/20 text-[#C83E5B] border border-[#C83E5B]/40 hover:bg-[#C83E5B] hover:text-white transition-all active:scale-95 whitespace-nowrap"
              >
                {prismProg > 0.85 ? 'Reset Raw' : 'Snap Refined ✨'}
              </button>
            </div>
          </div>

          {/* Three Refracted Beams */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6">
            <div
              className={`p-4 rounded-xl border text-left transition-all ${
                prismProg > 0.25
                  ? isLight
                    ? 'bg-white border-[#6F1025] shadow-md'
                    : 'bg-[#1C060B] border-[#C83E5B] shadow-[0_4px_20px_rgba(200,62,91,0.2)]'
                  : 'opacity-40 border-[#3D1520]'
              }`}
            >
              <div className="flex items-center space-x-2 text-xs font-bold text-[#C83E5B] mb-1">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                <span>BEAM 01 — PROFESSIONAL</span>
              </div>
              <p className="text-xs text-[#D6C7B2]">
                Eliminates conversational hedges, stuttered syllables, and throat clears with precision.
              </p>
            </div>

            <div
              className={`p-4 rounded-xl border text-left transition-all ${
                prismProg > 0.55
                  ? isLight
                    ? 'bg-white border-[#6F1025] shadow-md'
                    : 'bg-[#1C060B] border-[#C83E5B] shadow-[0_4px_20px_rgba(200,62,91,0.2)]'
                  : 'opacity-40 border-[#3D1520]'
              }`}
            >
              <div className="flex items-center space-x-2 text-xs font-bold text-[#C83E5B] mb-1">
                <Zap className="w-4 h-4 text-amber-500" />
                <span>BEAM 02 — CONCISE SHORTEN</span>
              </div>
              <p className="text-xs text-[#D6C7B2]">
                Reduces rambling verbal sentences into compact bullets ready for Slack or email.
              </p>
            </div>

            <div
              className={`p-4 rounded-xl border text-left transition-all ${
                prismProg > 0.85
                  ? isLight
                    ? 'bg-white border-[#6F1025] shadow-md'
                    : 'bg-[#1C060B] border-[#C83E5B] shadow-[0_4px_20px_rgba(200,62,91,0.2)]'
                  : 'opacity-40 border-[#3D1520]'
              }`}
            >
              <div className="flex items-center space-x-2 text-xs font-bold text-[#C83E5B] mb-1">
                <Sparkles className="w-4 h-4 text-emerald-500" />
                <span>BEAM 03 — ZERO-CLICK PASTE</span>
              </div>
              <p className="text-xs text-[#D6C7B2]">
                Synthesizes transformed text directly into the foreground app cursor without Cmd+V.
              </p>
            </div>
          </div>
        </div>
        </div>
      </section>



      {/* ========================================================================= */}
      {/* CHAPTER 03: THE GROQ LPU CONSTELLATION (Sticky Reversible Scrollytelling Track) */}
      {/* ========================================================================= */}
      <section id="lpu-constellation" ref={lpuTrackRef} className="relative h-[180vh] max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 my-8 z-10">
        <div className="sticky top-20 sm:top-24 h-auto">
          <div
            className={`rounded-3xl sm:rounded-[38px] p-8 sm:p-14 text-center border shadow-2xl relative overflow-hidden transition-all ${
            isLight
              ? 'bg-gradient-to-b from-[#FFFDF9] via-[#FAF4EB] to-[#F5EFE6] border-[#E2D9CD] shadow-[0_20px_50px_rgba(111,16,37,0.08)]'
              : 'bg-gradient-to-b from-[#1C060B] via-[#140508] to-[#100205] border-[#4A1522] shadow-[0_30px_80px_rgba(0,0,0,0.85)]'
          }`}
        >
          {/* Section Header */}
          <span className="text-xs font-bold uppercase tracking-widest text-[#C83E5B] mb-2 block font-mono">
            CH.03 — HARDWARE-ACCELERATED INFERENCE
          </span>
          <h2
            className={`text-3xl sm:text-5xl font-extrabold tracking-tight mb-3 ${
              isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
            }`}
          >
            The Groq LPU{' '}
            <span className="font-serif-instrument italic text-[#C83E5B]">
              Constellation
            </span>
          </h2>
          <p
            className={`max-w-xl mx-auto text-xs sm:text-sm mb-12 ${
              isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
            }`}
          >
            Sub-400ms time-to-first-token speech synthesis powered by Linear Processing Units and zero subscription barriers.
          </p>

          {/* Central Rotating Orbital Reactor Hub */}
          <div className="relative w-72 h-72 sm:w-88 sm:h-88 mx-auto my-6 flex items-center justify-center">
            {/* Outer Slow-Spinning Dashed Orbit */}
            <div
              className="absolute inset-0 rounded-full border border-dashed border-[#C83E5B]/40 animate-spin-slow pointer-events-none"
              style={{ animationDuration: '28s' }}
            />

            {/* Middle Reverse Ring */}
            <div
              className="absolute inset-8 rounded-full border border-[#6F1025]/50 animate-spin-slow pointer-events-none"
              style={{ animationDuration: '18s', animationDirection: 'reverse' }}
            />

            {/* Glowing Core Reactor */}
            <div className="relative w-36 h-36 rounded-full bg-gradient-to-br from-[#260910] to-[#120307] border-2 border-[#C83E5B] shadow-[0_0_40px_rgba(200,62,91,0.5)] flex flex-col items-center justify-center p-4 z-10">
              <Zap className="w-6 h-6 text-[#C83E5B] mb-1 animate-pulse" />
              <div className="font-mono text-xs font-black text-[#F5EBDD] tracking-wider">
                LPU CORE
              </div>
              <div className="font-mono text-[10px] text-emerald-400 font-bold mt-0.5">
                318ms LATENCY
              </div>
            </div>

            {/* 6 Circuit Nodes in Orbit (Smoothly Rotating & Igniting on Scroll) */}
            {[
              { label: 'NODE 01 — GROQ WHISPER', angle: 0, threshold: 0.15 },
              { label: 'NODE 02 — LOCAL SQLITE WAL', angle: 60, threshold: 0.30 },
              { label: 'NODE 03 — DISFLUENCY PRISM', angle: 120, threshold: 0.45 },
              { label: 'NODE 04 — 100% FREE FOREVER', angle: 180, threshold: 0.60 },
              { label: 'NODE 05 — CURSOR INJECTION', angle: 240, threshold: 0.75 },
              { label: 'NODE 06 — EPHEMERAL BUFFER', angle: 300, threshold: 0.90 },
            ].map((node, i) => {
              const currentAngle = node.angle + (lpuProg * 60);
              const rad = (currentAngle * Math.PI) / 180;
              const radius = 135;
              const x = Math.cos(rad) * radius;
              const y = Math.sin(rad) * radius;
              const isIgnited = lpuProg >= node.threshold;
              return (
                <div
                  key={i}
                  className={`absolute px-2.5 py-1 rounded-full text-[9px] font-mono font-bold shadow-md transition-all duration-200 whitespace-nowrap hidden sm:block ${
                    isIgnited
                      ? 'bg-[#6F1025] border border-[#FF4D73] text-white shadow-[0_0_16px_rgba(200,62,91,0.8)] scale-105'
                      : 'bg-[#1C060B]/90 border border-[#3D1520] text-[#A89F91]'
                  }`}
                  style={{
                    transform: `translate(${x}px, ${y}px)`,
                  }}
                >
                  {node.label}
                </div>
              );
            })}
          </div>

          {/* Speed Comparison Cards Below */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-5 text-left mt-10">
            {/* Standard Keyboard (45 wpm) */}
            <div
              className={`md:col-span-4 p-7 rounded-2xl sm:rounded-3xl border flex flex-col justify-between min-h-[220px] transition-all ${
                isLight
                  ? 'bg-white border-[#E2D9CD]'
                  : 'bg-[#100709] border-[#3D1520]'
              }`}
            >
              <div>
                <div className="text-xs font-medium text-[#A89F91] mb-1">Standard Keyboard</div>
                <div className="font-serif-instrument text-4xl sm:text-5xl font-normal leading-none text-[#A83249]">
                  45 <span className="text-xl font-sans text-[#A89F91]">wpm</span>
                </div>
              </div>
              <div className="mt-6 font-mono text-xs sm:text-sm text-[#D6C7B2] border-r-2 border-[#A83249] pr-1 py-1 overflow-hidden whitespace-nowrap">
                {typingSimText}
              </div>
            </div>

            {/* SAYN Voice Dictation (220 wpm) */}
            <div
              className={`md:col-span-8 p-7 rounded-2xl sm:rounded-3xl border flex flex-col justify-between min-h-[220px] relative overflow-hidden transition-all ${
                isLight
                  ? 'bg-gradient-to-br from-[#FFF5F7] via-[#FFFFFF] to-[#FAF0F2] border-[#C83E5B]/40 shadow-[0_10px_30px_rgba(200,62,91,0.12)]'
                  : 'bg-gradient-to-br from-[#260910] via-[#1C060B] to-[#120307] border-[#C83E5B]/60 shadow-[0_15px_40px_rgba(200,62,91,0.22)]'
              }`}
            >
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-xs font-bold text-[#A83249] mb-1 tracking-wide">
                    SAYN Voice Dictation
                  </div>
                  <div
                    className={`font-serif-instrument text-4xl sm:text-5xl font-normal leading-none ${
                      isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                    }`}
                  >
                    220 <span className="text-xl font-sans text-[#C83E5B] font-bold">wpm</span>
                  </div>
                </div>
                <span className="inline-flex items-center space-x-1.5 px-3 py-1 rounded-full bg-[#A83249]/20 border border-[#A83249]/40 text-[#A83249] text-xs font-bold">
                  <Zap className="w-3.5 h-3.5" />
                  <span>⚡ Real-Time LPU</span>
                </span>
              </div>

              {/* Text streamer */}
              <div className="mt-4 pt-4 border-t border-[#A83249]/20">
                <div className="flex items-center space-x-2 text-xs font-medium text-[#C83E5B] mb-1.5">
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Instant Audio-to-Cursor Injection</span>
                </div>
                <p
                  className={`text-xs sm:text-sm leading-relaxed font-medium ${
                    isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                  }`}
                >
                  Speak naturally, paraphrase word-by-word, adjust tone, and auto-paste into any active chatbot or editor instantly.
                </p>
              </div>
            </div>
          </div>
        </div>
        </div>
      </section>

      {/* 2. THREE-PILLAR CAPABILITIES SECTION */}
      <section id="features" className="py-24 border-t border-[#3D1520] bg-[#14080D]/80 relative overflow-hidden">
        {/* Subtle ambient section glow */}
        <div className="absolute top-0 right-1/3 w-[500px] h-[500px] bg-[#6F1025]/10 rounded-full blur-[150px] pointer-events-none scroll-parallax-glow" />
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center max-w-3xl mx-auto mb-16 reveal-on-scroll scroll-reveal">
            <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
              Core Architecture
            </span>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
              Engineered for Effortless Communication
            </h2>
            <p className="text-sm sm:text-base text-[#D6C7B2]">
              Three major superpowers united into one seamless companion: voice-to-text, intelligent writing refinement, and cross-application assistance.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Card 1: Voice to Text */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-1 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <Mic className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Voice to Text</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Turn natural speech into crisp, punctuated text with zero cloud lock-in. Powered by high-speed Groq Whisper LPUs.
              </p>
            </div>

            {/* Card 2: AI Writing Assistant */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-2 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <PenTool className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">QuillBot & Grammarly Refinement</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Correct grammar, paraphrase word-by-word, adjust tone (Fluent, Professional, Natural), and optimize clarity in real time.
              </p>
            </div>

            {/* Card 3: Floating Assistant */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-3 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <Layers className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Desktop & Mobile Assistant</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                A sleek floating pill on Mac and Windows, plus Android overlay and keyboard. Automatically pastes into any active chatbot or document.
              </p>
            </div>

            {/* Card 4: Smart Keyboard */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-4 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <Keyboard className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Android Smart Keyboard</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Custom mobile IME with one-tap voice dictation, instant grammar linting, and integrated emoji palette elevated above the gesture bar.
              </p>
            </div>

            {/* Card 5: Cross Platform */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-5 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <Laptop className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Universal Compatibility</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Native DMG for macOS (Silicon + Intel), portable installer for Windows (64-bit + 32-bit), release APK for Android, and progressive Web Studio.
              </p>
            </div>

            {/* Card 6: Privacy by Design */}
            <div className="reveal-on-scroll scroll-reveal reveal-delay-6 p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/80 hover:shadow-[0_8px_30px_rgba(111,16,37,0.3)] transition-all duration-300 group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-110 transition-transform">
                <ShieldCheck className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">100% Free &amp; Unlimited</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Zero paywalls. Unlimited usage with zero-prompt embedded keys. Audio is processed ephemerally and discarded immediately.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 2B. ABOUT SAYN SECTION */}
      <section
        id="about"
        className={`py-24 border-t relative overflow-hidden transition-colors ${
          isLight ? 'border-[#E2D9CD] bg-[#F7F4EE]' : 'border-[#3D1520] bg-[#14080D]/90'
        }`}
      >
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center max-w-3xl mx-auto mb-16 reveal-on-scroll scroll-reveal">
            <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
              About SAYN
            </span>
            <h2
              className={`text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 ${
                isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
              }`}
            >
              Built for Humans Who Think Fast
            </h2>
            <p
              className={`text-sm sm:text-base leading-relaxed ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              Human speech flows at 150 to 200 words per minute, while typing maxes out at 40 to 60 words per minute. SAYN eliminates this bottleneck with zero subscription fees, zero word quotas, and uncompromising local-first privacy.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div
              className={`p-6 rounded-2xl border transition-all ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#1C0B12] border-[#3D1520]'
              }`}
            >
              <div className="w-10 h-10 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                <Zap className="w-5 h-5" />
              </div>
              <h3
                className={`text-base font-bold mb-2 ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                Why No Subscription?
              </h3>
              <p
                className={`text-xs leading-relaxed ${
                  isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                }`}
              >
                Unlike apps that cut you off with "0 words left" or charge monthly subscriptions, SAYN is built on ultra-fast Groq LPU Whisper and local SQLite architectures. Dictate 10 words or 100,000 words—it is completely free.
              </p>
            </div>

            <div
              className={`p-6 rounded-2xl border transition-all ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#1C0B12] border-[#3D1520]'
              }`}
            >
              <div className="w-10 h-10 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                <Sparkles className="w-5 h-5" />
              </div>
              <h3
                className={`text-base font-bold mb-2 ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                How It Helps You
              </h3>
              <p
                className={`text-xs leading-relaxed ${
                  isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                }`}
              >
                Speak unstructured thoughts, stumble, or pace around your desk. SAYN strips verbal fillers ("um", "ah"), fixes grammar, and auto-adapts your tone for executive emails, Slack replies, or GitHub PR descriptions.
              </p>
            </div>

            <div
              className={`p-6 rounded-2xl border transition-all ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#1C0B12] border-[#3D1520]'
              }`}
            >
              <div className="w-10 h-10 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <h3
                className={`text-base font-bold mb-2 ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                Local-First &amp; Private
              </h3>
              <p
                className={`text-xs leading-relaxed ${
                  isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                }`}
              >
                Audio streams are kept in ephemeral memory and discarded immediately after transcription. Your history is stored on your local machine in SQLite WAL. No surveillance, and no model training on your private voice data.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 3. INTERACTIVE 3-STEP WORKFLOW SECTION */}
      <section
        id="how-it-works"
        className={`py-24 border-t relative overflow-hidden transition-colors ${
          isLight ? 'border-[#E2D9CD] bg-[#FDFBF7]' : 'border-[#3D1520] bg-[#100709]'
        }`}
      >
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center max-w-2xl mx-auto mb-16 reveal-on-scroll scroll-reveal">
            <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
              Workflow
            </span>
            <h2
              className={`text-3xl sm:text-4xl font-extrabold tracking-tight mb-3 ${
                isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
              }`}
            >
              How It Works
            </h2>
            <p
              className={`text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              A frictionless three-step process to elevate any communication in seconds.
            </p>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-stretch">
            {/* Left: 3 Interactive Step Cards */}
            <div className="lg:col-span-5 flex flex-col justify-between space-y-4">
              {[
                {
                  step: 0,
                  num: '1',
                  title: 'Speak or Type',
                  desc: 'Record your voice with Fn or Option+Space, or paste a rough thought without worrying about phrasing or punctuation.',
                },
                {
                  step: 1,
                  num: '2',
                  title: 'Choose Refinement',
                  desc: 'Select your desired mode and style—Natural, Fluent, Professional, Prompt Mode, or Live Translation.',
                },
                {
                  step: 2,
                  num: '3',
                  title: 'Auto-Paste Anywhere',
                  desc: 'The refined text automatically injects into your active chatbot, email, or editor. Zero manual Cmd+V required.',
                },
              ].map((item) => {
                const isActive = activeWorkflowStep === item.step;
                return (
                  <div
                    key={item.num}
                    onClick={() => setActiveWorkflowStep(item.step as 0 | 1 | 2)}
                    className={`cursor-pointer p-6 rounded-2xl border transition-all duration-300 text-left ${
                      isActive
                        ? isLight
                          ? 'bg-white border-[#6F1025] shadow-lg translate-x-1.5'
                          : 'bg-[#1C060B] border-[#C83E5B] shadow-[0_12px_30px_rgba(200,62,91,0.18)] translate-x-1.5'
                        : isLight
                          ? 'bg-white/60 border-[#E2D9CD] opacity-60 hover:opacity-90'
                          : 'bg-[#14080D]/60 border-[#3D1520] opacity-50 hover:opacity-85'
                    }`}
                  >
                    <div className="flex items-center space-x-3 mb-2">
                      <div
                        className={`w-7 h-7 rounded-full font-mono text-xs font-bold flex items-center justify-center transition-colors ${
                          isActive
                            ? 'bg-[#A83249] text-white shadow-sm'
                            : isLight
                              ? 'bg-[#E2D9CD] text-[#5C4D44]'
                              : 'bg-[#3D1520] text-[#D6C7B2]'
                        }`}
                      >
                        {item.num}
                      </div>
                      <h3
                        className={`font-bold text-base ${
                          isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                        }`}
                      >
                        {item.title}
                      </h3>
                    </div>
                    <p
                      className={`text-xs sm:text-sm leading-relaxed pl-10 ${
                        isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                      }`}
                    >
                      {item.desc}
                    </p>
                  </div>
                );
              })}
            </div>

            {/* Right: The Morphing Live Stage Card */}
            <div className="lg:col-span-7">
              <div
                className={`h-full min-h-[380px] rounded-3xl p-7 sm:p-9 border flex flex-col justify-between shadow-2xl relative transition-all ${
                  isLight
                    ? 'bg-gradient-to-br from-white via-[#FAF7F2] to-[#F5EFE6] border-[#6F1025]/30 shadow-[0_20px_50px_rgba(111,16,37,0.09)]'
                    : 'bg-gradient-to-br from-[#260910] via-[#1C060B] to-[#120307] border-[#C83E5B]/50 shadow-[0_25px_70px_rgba(0,0,0,0.75)]'
                }`}
              >
                {/* Stage Header */}
                <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-[#A83249]/20">
                  <span className="text-xs font-bold uppercase tracking-wider text-[#C83E5B]">
                    {activeWorkflowStep === 0 && 'STEP 01 — CAPTURING VOICE STREAM'}
                    {activeWorkflowStep === 1 && 'STEP 02 — GRAMMAR & STYLE REFINEMENT'}
                    {activeWorkflowStep === 2 && 'STEP 03 — ZERO-CLICK AUTO-PASTE'}
                  </span>

                  {/* Mode Pills */}
                  <div className="flex items-center space-x-1.5 text-xs">
                    {(['Raw Input', 'Professional', 'Auto-Paste'] as const).map((label, idx) => (
                      <button
                        key={label}
                        onClick={() => setActiveWorkflowStep(idx as 0 | 1 | 2)}
                        className={`px-3 py-1 rounded-full font-medium transition-all ${
                          activeWorkflowStep === idx
                            ? 'bg-[#C83E5B] text-white shadow-sm'
                            : isLight
                              ? 'bg-white text-[#5C4D44] border border-[#E2D9CD]'
                              : 'bg-[#100709] text-[#B59CA2] border border-[#3D1520]'
                        }`}
                      >
                        {label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Stage Dynamic Body Content */}
                <div
                  className={`my-6 p-6 rounded-2xl border min-h-[160px] flex flex-col justify-between transition-all ${
                    isLight
                      ? 'bg-white border-[#E2D9CD] shadow-inner'
                      : 'bg-[#100709] border-[#3D1520] shadow-inner'
                  }`}
                >
                  {activeWorkflowStep === 0 && (
                    <div className="text-sm sm:text-base leading-relaxed">
                      "Um,{' '}
                      <span className="line-through text-[#C83E5B] opacity-75">
                        like
                      </span>{' '}
                      can you let the team know the launch is{' '}
                      <span className="line-through text-[#C83E5B] opacity-75">
                        uh basically
                      </span>{' '}
                      slipping to Thursday? We still need design system sign-off."
                    </div>
                  )}

                  {activeWorkflowStep === 1 && (
                    <div
                      className={`text-sm sm:text-base leading-relaxed ${
                        isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                      }`}
                    >
                      "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday."
                    </div>
                  )}

                  {activeWorkflowStep === 2 && (
                    <div>
                      <div className="text-[11px] font-mono text-[#A89F91] mb-2 flex items-center space-x-2">
                        <span className="w-2 h-2 rounded-full bg-emerald-500" />
                        <span>Slack — #product-engineering</span>
                      </div>
                      <div
                        className={`text-sm sm:text-base leading-relaxed font-medium ${
                          isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                        }`}
                      >
                        "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday."
                        <span className="inline-block w-1.5 h-4 ml-1 bg-[#C83E5B] animate-pulse align-middle" />
                      </div>
                    </div>
                  )}

                  <div className="pt-4 mt-4 border-t border-[#A83249]/20 flex items-center justify-between text-xs">
                    <span className="text-[#C83E5B] font-semibold">
                      {activeWorkflowStep === 0 && '🎙️ Fn Key Held (00:04)'}
                      {activeWorkflowStep === 1 && '✨ Mode: Professional & Fluent'}
                      {activeWorkflowStep === 2 && '✔ Injected into active cursor'}
                    </span>
                    <span className="text-emerald-500 font-bold">
                      {activeWorkflowStep === 0 && 'Groq Whisper LPU Active'}
                      {activeWorkflowStep === 1 && 'Clarity Optimized'}
                      {activeWorkflowStep === 2 && 'Zero Cmd+V Required'}
                    </span>
                  </div>
                </div>

                {/* Stage Hint */}
                <div
                  className={`text-center text-xs ${
                    isLight ? 'text-[#706E6B]' : 'text-[#B59CA2]'
                  }`}
                >
                  Click steps or pills above to preview how SAYN transforms and auto-pastes your message.
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* 3B. DIRECT DOWNLOAD SECTION */}
      <section
        id="download"
        className={`scroll-mt-24 py-24 border-t relative overflow-hidden transition-colors ${
          isLight ? 'border-[#E2D9CD] bg-[#FAF7F2]' : 'border-[#3D1520] bg-[#100709]'
        }`}
      >
        <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center">
          <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
            Install Once. Speak Anywhere.
          </span>
          <h2
            className={`text-3xl sm:text-5xl font-extrabold tracking-tight mb-4 ${
              isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
            }`}
          >
            Download SAYN Free
          </h2>
          <p
            className={`max-w-2xl mx-auto text-sm sm:text-base mb-12 ${
              isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
            }`}
          >
            Native performance on Apple Silicon, Intel Macs, Windows 10/11, and Android. No credit card, no subscription, no sign-up barrier.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 text-left">
            {/* macOS Card */}
            <div
              className={`p-6 rounded-2xl border relative flex flex-col justify-between ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#18080E] border-[#3D1520]'
              }`}
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                  <Laptop className="w-6 h-6" />
                </div>
                <div className="flex items-center justify-between mb-1">
                  <h3
                    className={`text-lg font-bold ${
                      isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                    }`}
                  >
                    macOS
                  </h3>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-500 border border-emerald-500/20">
                    Universal 2
                  </span>
                </div>
                <p
                  className={`text-xs mb-4 ${
                    isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                  }`}
                >
                  Optimized for Apple Silicon M1/M2/M3/M4 &amp; Intel. Includes floating pill window &amp; Fn push-to-talk.
                </p>
                <div
                  className={`text-[11px] font-mono space-y-1 mb-6 ${
                    isLight ? 'text-[#706E6B]' : 'text-[#D6C7B2]/70'
                  }`}
                >
                  <div>• macOS 11.0 (Big Sur) or later</div>
                  <div>• Native Global Keyboard Listener</div>
                  <div>• Direct AXUIElement Auto-Paste</div>
                </div>
              </div>
              <button
                onClick={() => setIsDownloadOpen(true)}
                className={`w-full py-3 rounded-xl text-xs font-bold flex items-center justify-center space-x-2 transition shadow-sm ${
                  isLight
                    ? 'bg-[#6F1025] hover:bg-[#85162E] text-[#F5EBDD]'
                    : 'bg-[#F5EBDD] hover:bg-[#FAF4EB] text-[#100709]'
                }`}
              >
                <Download className="w-4 h-4 stroke-[2.5]" />
                <span>Download for Mac (.dmg)</span>
              </button>
            </div>

            {/* Windows Card */}
            <div
              className={`p-6 rounded-2xl border relative flex flex-col justify-between ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#18080E] border-[#3D1520]'
              }`}
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                  <Monitor className="w-6 h-6" />
                </div>
                <div className="flex items-center justify-between mb-1">
                  <h3
                    className={`text-lg font-bold ${
                      isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                    }`}
                  >
                    Windows
                  </h3>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-500/10 text-blue-400 border border-blue-500/20">
                    x64 / ARM64
                  </span>
                </div>
                <p
                  className={`text-xs mb-4 ${
                    isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                  }`}
                >
                  High-speed desktop assistant with global hotkey support and Windows SendInput injection.
                </p>
                <div
                  className={`text-[11px] font-mono space-y-1 mb-6 ${
                    isLight ? 'text-[#706E6B]' : 'text-[#D6C7B2]/70'
                  }`}
                >
                  <div>• Windows 10 / 11 (64-bit)</div>
                  <div>• Low latency tray overlay</div>
                  <div>• Seamless Office, VS Code, Browser paste</div>
                </div>
              </div>
              <button
                onClick={() => setIsDownloadOpen(true)}
                className={`w-full py-3 rounded-xl text-xs font-bold flex items-center justify-center space-x-2 transition border ${
                  isLight
                    ? 'border-[#6F1025] text-[#6F1025] hover:bg-[#6F1025]/10'
                    : 'border-[#A83249] text-[#F5EBDD] hover:bg-[#6F1025]/30'
                }`}
              >
                <Download className="w-4 h-4" />
                <span>Download for Windows (.exe)</span>
              </button>
            </div>

            {/* Android Card */}
            <div
              className={`p-6 rounded-2xl border relative flex flex-col justify-between ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#18080E] border-[#3D1520]'
              }`}
            >
              <div>
                <div className="w-12 h-12 rounded-xl bg-[#6F1025]/20 flex items-center justify-center text-[#A83249] mb-4">
                  <Smartphone className="w-6 h-6" />
                </div>
                <div className="flex items-center justify-between mb-1">
                  <h3
                    className={`text-lg font-bold ${
                      isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                    }`}
                  >
                    Android
                  </h3>
                  <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-500 border border-amber-500/20">
                    IME Keyboard
                  </span>
                </div>
                <p
                  className={`text-xs mb-4 ${
                    isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
                  }`}
                >
                  Voice-first custom Android keyboard with floating mic bubble and real-time smart punctuation.
                </p>
                <div
                  className={`text-[11px] font-mono space-y-1 mb-6 ${
                    isLight ? 'text-[#706E6B]' : 'text-[#D6C7B2]/70'
                  }`}
                >
                  <div>• Android 9.0 (Pie) to 15+</div>
                  <div>• System-wide Input Method (IME)</div>
                  <div>• Floating dictation overlay</div>
                </div>
              </div>
              <button
                onClick={() => setIsDownloadOpen(true)}
                className={`w-full py-3 rounded-xl text-xs font-bold flex items-center justify-center space-x-2 transition border ${
                  isLight
                    ? 'border-[#6F1025] text-[#6F1025] hover:bg-[#6F1025]/10'
                    : 'border-[#A83249] text-[#F5EBDD] hover:bg-[#6F1025]/30'
                }`}
              >
                <Download className="w-4 h-4" />
                <span>Download Android APK</span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* CHAPTER 04: THE EPHEMERAL INCINERATOR VAULT (Sticky Reversible Scrollytelling Track) */}
      {/* ========================================================================= */}
      <section id="privacy" ref={privacyTrackRef} className="relative h-[170vh] border-t border-[#3D1520] bg-[#14080D]/80 z-10 my-8">
        <div className="sticky top-20 sm:top-24 h-auto">
          <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
          <div className="reveal-on-scroll scroll-reveal">
            <span className="text-xs font-bold uppercase tracking-widest text-[#C83E5B] mb-2 block font-mono">
              CH.04 — ZERO CLOUD RETENTION
            </span>
            <div className="w-14 h-14 rounded-2xl bg-[#6F1025]/30 border border-[#A83249]/40 text-[#A83249] flex items-center justify-center mx-auto mb-5 shadow-sm">
              <ShieldCheck className="w-7 h-7" />
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
              The Ephemeral{' '}
              <span className="font-serif-instrument italic text-[#C83E5B]">
                Incinerator Vault
              </span>
            </h2>
            <p className="text-sm sm:text-base text-[#D6C7B2] leading-relaxed max-w-2xl mx-auto mb-10">
              SAYN processes voice streams ephemerally. Audio recordings never touch permanent disk caches or cloud servers. The moment your transcript is rendered, the RAM buffer is completely wiped.
            </p>

            {/* Live Buffer Shredder Visualization Bar */}
            <div
              className={`p-6 rounded-2xl border mb-12 text-left transition-all ${
                isLight
                  ? 'bg-white border-[#E2D9CD] shadow-sm'
                  : 'bg-[#1C060B] border-[#4A1522] shadow-[0_10px_30px_rgba(0,0,0,0.6)]'
              }`}
            >
              <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
                <span className="text-[11px] font-mono font-bold text-[#C83E5B] flex items-center space-x-1.5">
                  <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" />
                  <span>LIVE MEMORY SHREDDER GAUGE</span>
                </span>
                <span className="text-[10px] font-mono text-emerald-400 font-bold px-2 py-0.5 rounded bg-emerald-500/10 border border-emerald-500/20">
                  RAM FLUSH: {Math.round(privacyProg * 100)}% COMPLETE (0.00 KB LEAK)
                </span>
              </div>

              {/* Progress bar stream linked to scroll */}
              <div className="relative w-full h-3 rounded-full bg-[#100205] overflow-hidden border border-[#3D1520]">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-emerald-500 via-[#C83E5B] to-emerald-400 transition-all duration-150"
                  style={{ width: `${Math.round(25 + privacyProg * 75)}%` }}
                />
              </div>

              <div className="grid grid-cols-3 gap-2 mt-4 text-center font-mono text-[10px] text-[#A89F91]">
                <div className={`p-2 rounded border transition-colors ${privacyProg < 0.33 ? 'bg-[#6F1025]/40 border-[#C83E5B] text-[#F5EBDD] font-bold' : 'bg-black/30 border-[#3D1520]'}`}>
                  1. MIC CAPTURE (PCM 48kHz)
                </div>
                <div className={`p-2 rounded border transition-colors ${privacyProg >= 0.33 && privacyProg < 0.75 ? 'bg-[#6F1025]/40 border-[#C83E5B] text-[#F5EBDD] font-bold' : 'bg-black/30 border-[#3D1520]'}`}>
                  2. GROQ LPU INFERENCE
                </div>
                <div className={`p-2 rounded border transition-colors ${privacyProg >= 0.75 ? 'bg-[#6F1025]/40 border-[#C83E5B] text-[#F5EBDD] font-bold shadow-[0_0_12px_rgba(200,62,91,0.5)]' : 'bg-[#6F1025]/20 border-[#C83E5B]/40 text-[#F5EBDD]'}`}>
                  3. MEMORY INCINERATED 🔥
                </div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-left max-w-3xl mx-auto text-xs">
            <div className="reveal-on-scroll scroll-reveal reveal-delay-1 p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>Zero Audio Retention</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Voice streams are ephemeral and destroyed immediately after transcription.</p>
            </div>

            <div className="reveal-on-scroll scroll-reveal reveal-delay-2 p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>Local SQLite WAL</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Your writing history is encrypted locally on your SSD. Zero cloud sync or tracking.</p>
            </div>

            <div className="reveal-on-scroll scroll-reveal reveal-delay-3 p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>Sensitive Field Guard</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Password and secure credentials are excluded from external AI processing.</p>
            </div>
          </div>
        </div>
        </div>
      </section>

      {/* 5. FINAL CALL TO ACTION */}
      <section className="py-24 border-t border-[#3D1520] bg-gradient-to-b from-[#100709] to-[#1C0B12] text-center relative overflow-hidden">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 reveal-on-scroll scroll-reveal">
          <h2 className="text-4xl sm:text-5xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
            Write less. Say more.
          </h2>
          <p className="text-base text-[#D6C7B2] mb-9">
            Experience the clarity and speed of SAYN on your Mac, Windows, Android, or Web today.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <button
              onClick={() => setIsDownloadOpen(true)}
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2.5 px-8 py-4 rounded-full font-bold text-sm bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_24px_rgba(245,235,221,0.25)] hover:shadow-[0_8px_32px_rgba(245,235,221,0.35)]"
            >
              <Download className="w-4 h-4 stroke-[2.5]" />
              <span>Download Free for {device?.osName || 'Your Device'}</span>
            </button>
            <a
              href="#about"
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 px-8 py-4 rounded-full font-semibold text-sm text-[#F5EBDD] bg-[#100709] border border-[#A83249] hover:bg-[#6F1025]/30 hover:border-[#F5EBDD]/40 transition-all"
            >
              <span>Learn More About SAYN</span>
              <ArrowRight className="w-4 h-4" />
            </a>
          </div>
        </div>
      </section>



      {/* Smart Device Detection Download Modal */}
      <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
    </div>
  );
};
