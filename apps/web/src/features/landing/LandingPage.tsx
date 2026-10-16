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

export const LandingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'refine' | 'voice' | 'overlay'>('refine');
  const [copiedDemo, setCopiedDemo] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const [device, setDevice] = useState<DeviceInfo | null>(null);
  const [activeWorkflowStep, setActiveWorkflowStep] = useState<0 | 1 | 2>(0);
  const [typingSimText, setTypingSimText] = useState('Hey team, I revie');
  const [isAutoScrolling, setIsAutoScrolling] = useState(false);
  const { scrollY, scrollProgress } = useScrollAnimation();
  const { actualTheme } = useTheme();
  const isLight = actualTheme === 'light';

  React.useEffect(() => {
    setDevice(detectDevice());
  }, []);

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

  // Auto-scroll simulation
  React.useEffect(() => {
    if (!isAutoScrolling) return;
    let animId: number;
    const step = () => {
      const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
      if (window.scrollY >= maxScroll - 4) {
        window.scrollTo({ top: 0, behavior: 'smooth' });
        setIsAutoScrolling(false);
        return;
      }
      window.scrollBy(0, 3.2);
      animId = requestAnimationFrame(step);
    };
    animId = requestAnimationFrame(step);
    return () => cancelAnimationFrame(animId);
  }, [isAutoScrolling]);

  const handleCopyDemo = () => {
    navigator.clipboard.writeText(
      'Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday.'
    );
    setCopiedDemo(true);
    setTimeout(() => setCopiedDemo(false), 2000);
  };

  return (
    <div
      className={`flex-1 flex flex-col overflow-hidden transition-colors duration-300 ${
        isLight ? 'bg-[#FAF7F2] text-[#2D0A12]' : 'bg-[#100709] text-[#F5EBDD]'
      }`}
    >
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
                    {/* Left Mini Sidebar */}
                    <div className="col-span-3 space-y-1.5 text-left text-[11px]">
                      <div className="flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg bg-[#6F1025] text-[#F5EBDD] font-semibold shadow-sm">
                        <PenTool className="w-3 h-3 text-[#F5EBDD]" />
                        <span>AI Writer</span>
                      </div>
                      <div className="flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg text-[#D6C7B2] hover:bg-[#240F16] transition-colors">
                        <Mic className="w-3 h-3 text-[#A83249]" />
                        <span>Voice Mode</span>
                      </div>
                      <div className="flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg text-[#D6C7B2] hover:bg-[#240F16] transition-colors">
                        <Sliders className="w-3 h-3" />
                        <span>Grammar</span>
                      </div>
                      <div className="flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg text-[#D6C7B2] hover:bg-[#240F16] transition-colors">
                        <Minimize2 className="w-3 h-3" />
                        <span>Shorten</span>
                      </div>
                      <div className="flex items-center space-x-1.5 px-2.5 py-1.5 rounded-lg text-[#D6C7B2] hover:bg-[#240F16] transition-colors">
                        <Maximize2 className="w-3 h-3" />
                        <span>Expand</span>
                      </div>
                    </div>

                    {/* Center Voice Waveform Card */}
                    <div className="col-span-4 rounded-xl bg-[#1C0B12] border border-[#3D1520] p-3.5 flex flex-col items-center justify-between text-center shadow-inner">
                      <div className="text-[11px] font-mono font-bold text-[#F5EBDD]">00:04</div>
                      
                      {/* Equalizer Soundwave Bars in Soft Rose-Maroon */}
                      <div className="flex items-center justify-center space-x-1 h-12 my-2">
                        {[20, 45, 80, 100, 65, 90, 40, 75, 30].map((h, i) => (
                          <div
                            key={i}
                            className="w-1 rounded-full bg-[#A83249] animate-pulse"
                            style={{
                              height: `${h}%`,
                              animationDelay: `${i * 90}ms`,
                              animationDuration: '900ms',
                            }}
                          />
                        ))}
                      </div>

                      <div className="text-[10px] text-[#D6C7B2] mb-2 font-medium">Listening...</div>

                      {/* Deep Maroon Stop Button */}
                      <button className="w-7 h-7 rounded-full bg-[#6F1025] hover:bg-[#8F1835] text-[#F5EBDD] flex items-center justify-center shadow-md transition-transform hover:scale-110">
                        <Square className="w-2.5 h-2.5 fill-current" />
                      </button>
                    </div>

                    {/* Right Refined Output Card */}
                    <div className="col-span-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] p-3 flex flex-col justify-between text-left">
                      {/* Segmented Original / Refined Switcher */}
                      <div className="flex items-center justify-end space-x-1 mb-2">
                        <button className="px-2 py-0.5 rounded-md text-[10px] text-[#A89F91]">
                          Original
                        </button>
                        <button className="px-2 py-0.5 rounded-md text-[10px] font-bold text-[#100709] bg-[#F5EBDD] shadow-sm">
                          Refined
                        </button>
                      </div>

                      {/* Polished Text Display */}
                      <p className="text-[11px] text-[#F5EBDD] leading-relaxed mb-3">
                        "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday."
                      </p>

                      <div className="flex items-center justify-between pt-1 border-t border-[#3D1520]/50 text-[10px] text-[#A83249]">
                        <span className="flex items-center space-x-1">
                          <CheckCircle2 className="w-3 h-3 text-[#30D158]" />
                          <span>Ready to paste</span>
                        </span>
                        <button onClick={handleCopyDemo} className="hover:text-[#F5EBDD] flex items-center space-x-1">
                          {copiedDemo ? <Check className="w-2.5 h-2.5 text-[#30D158]" /> : <Copy className="w-2.5 h-2.5" />}
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

      {/* 1C. SPEED COMPARISON: 4X FASTER THAN TYPING */}
      <section className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 my-10 sm:my-14 relative z-10">
        <div
          className={`rounded-3xl sm:rounded-[38px] p-8 sm:p-14 text-center border shadow-2xl relative overflow-hidden transition-all ${
            isLight
              ? 'bg-gradient-to-b from-[#FFFDF9] to-[#FAF4EB] border-[#E2D9CD] shadow-[0_20px_50px_rgba(111,16,37,0.08)]'
              : 'bg-gradient-to-b from-[#1C060B] to-[#120307] border-[#4A1522] shadow-[0_30px_80px_rgba(0,0,0,0.7)]'
          }`}
        >
          <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
            GROQ WHISPER LPU ENGINE
          </span>
          <h2
            className={`text-3xl sm:text-5xl font-extrabold tracking-tight mb-3 ${
              isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
            }`}
          >
            4x faster{' '}
            <span className="font-serif-instrument italic text-[#C83E5B]">
              than typing
            </span>
          </h2>
          <p
            className={`max-w-xl mx-auto text-sm sm:text-base mb-10 ${
              isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
            }`}
          >
            Turn natural speech into crisp, punctuated text with zero cloud lock-in. Speak at the speed of thought across every app.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-12 gap-5 text-left">
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
                    {activeWorkflowStep === 0 && 'STEP 01 // CAPTURING VOICE STREAM'}
                    {activeWorkflowStep === 1 && 'STEP 02 // QUILLBOT & GRAMMARLY REFINEMENT'}
                    {activeWorkflowStep === 2 && 'STEP 03 // ZERO-CLICK AUTO-PASTE'}
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
        className={`py-24 border-t relative overflow-hidden transition-colors ${
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

      {/* 4. PRIVACY SECTION */}
      <section id="privacy" className="py-24 border-t border-[#3D1520] bg-[#14080D]/80 relative overflow-hidden">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center relative z-10">
          <div className="reveal-on-scroll scroll-reveal">
            <div className="w-14 h-14 rounded-2xl bg-[#6F1025]/30 border border-[#A83249]/40 text-[#A83249] flex items-center justify-center mx-auto mb-5 shadow-sm">
              <ShieldCheck className="w-7 h-7" />
            </div>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
              Your Privacy Is Fundamental
            </h2>
            <p className="text-sm sm:text-base text-[#D6C7B2] leading-relaxed max-w-2xl mx-auto mb-10">
              SAYN processes text strictly for the requested transformation. We do not retain audio recordings after transcription, we do not log passwords or keystrokes, and you have full control over your writing history.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-left max-w-3xl mx-auto text-xs">
            <div className="reveal-on-scroll scroll-reveal reveal-delay-1 p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>No Audio Retention</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Voice streams are ephemeral and discarded immediately after transcription.</p>
            </div>

            <div className="reveal-on-scroll scroll-reveal reveal-delay-2 p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>History Controls</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Enable, disable, or purge your writing history anytime with one click.</p>
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

      {/* Floating Auto-Scroll Interactive Tour Pill */}
      <div className="fixed bottom-6 left-6 z-40 hidden sm:flex items-center space-x-3 px-3.5 py-2 rounded-full backdrop-blur-xl border shadow-xl bg-[#1C060B]/90 border-[#C83E5B]/60 text-xs transition-all">
        <button
          onClick={() => setIsAutoScrolling(!isAutoScrolling)}
          className="px-3.5 py-1 rounded-full font-bold bg-[#C83E5B] text-white hover:bg-[#E04A6A] transition-all active:scale-95 shadow-sm"
        >
          {isAutoScrolling ? '⏸ Pause Tour' : '▶ Auto-Play Tour'}
        </button>
        <span className="text-[11px] text-[#B59CA2] font-mono">
          Scroll: {Math.round(scrollProgress)}%
        </span>
      </div>

      {/* Smart Device Detection Download Modal */}
      <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
    </div>
  );
};
