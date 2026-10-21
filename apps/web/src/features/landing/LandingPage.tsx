import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import {
  Mic,
  Copy,
  Check,
  ArrowRight,
  ArrowDown,
  ChevronRight,
  Send,
  Smartphone,
  Laptop,
  Infinity as InfinityIcon,
  Sparkles,
  FileText,
  Lock,
  Square,
  Play,
  Apple,
  Download,
  Terminal,
} from 'lucide-react';
import { DownloadModal } from '../../components/download/DownloadModal.js';
import saynLogo from '../../assets/logo.png';

const WindowsIcon: React.FC<{ className?: string }> = ({ className = 'w-4 h-4' }) => (
  <svg className={className} viewBox="0 0 24 24" fill="currentColor">
    <path d="M3 3h8.2v8.2H3V3zm9.6 0H21v8.2h-8.4V3zM3 12.8h8.2V21H3v-8.2zm9.6 0H21V21h-8.4v-8.2z" />
  </svg>
);

export const LandingPage: React.FC = () => {
  // Navigation & Modal state
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const [activeNav, setActiveNav] = useState<string>('how-it-works');

  // Hero Studio Mockup State
  const [activeStudioTab, setActiveStudioTab] = useState<'write' | 'improve' | 'shorten' | 'detail'>('write');
  const [isListening, setIsListening] = useState(true);
  const [audioSeconds, setAudioSeconds] = useState(8);
  const [copiedMessage, setCopiedMessage] = useState(false);

  // Screen 2 Slider State
  const [sliderValue, setSliderValue] = useState(50); // 0 (original) to 100 (clearer)

  // Screen 3 Typing Simulation State
  const [typedChars, setTypedChars] = useState(0);
  const fullTypingText = "Hey team, I reviewed the sprint deliverables and the design migration is on track for Thursday";

  // Installation Section State (Screenshot 1)
  const [installPlatform, setInstallPlatform] = useState<'mac' | 'windows'>('mac');
  const [copiedInstallCmd, setCopiedInstallCmd] = useState(false);

  // Audio timer ticker
  useEffect(() => {
    if (!isListening) return;
    const interval = setInterval(() => {
      setAudioSeconds((prev) => (prev >= 59 ? 0 : prev + 1));
    }, 1000);
    return () => clearInterval(interval);
  }, [isListening]);

  // Typing simulation ticker for normal typing card
  useEffect(() => {
    const interval = setInterval(() => {
      setTypedChars((prev) => (prev < fullTypingText.length ? prev + 1 : 0));
    }, 90);
    return () => clearInterval(interval);
  }, []);

  const handleCopyMessage = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedMessage(true);
    setTimeout(() => setCopiedMessage(false), 2000);
  };

  const handleCopyInstallCommand = (cmd: string) => {
    navigator.clipboard.writeText(cmd);
    setCopiedInstallCmd(true);
    setTimeout(() => setCopiedInstallCmd(false), 2000);
  };

  const openDownload = () => {
    const downloadSec = document.getElementById('download');
    if (downloadSec) {
      downloadSec.scrollIntoView({ behavior: 'smooth' });
    } else {
      setIsDownloadOpen(true);
    }
  };

  const studioTabMessages: Record<'write' | 'improve' | 'shorten' | 'detail', string> = {
    write: 'Hey team, I reviewed the latest updates. Everything is on track for Thursday.',
    improve: 'Good morning team. I have thoroughly reviewed the latest deliverables; our timeline remains intact for Thursday.',
    shorten: 'Reviewed updates. On track for Thursday.',
    detail: 'Hey team, I conducted a full audit of the current sprint deliverables. The core blockers have been mitigated and the release remains on track for Thursday deployment.',
  };

  const macCommand = 'curl -fsSL https://sayn.ai/install.sh | bash';
  const windowsCommand = 'irm https://sayn.ai/install.ps1 | iex';

  return (
    <div className="min-h-screen bg-[#FAF4EB] text-[#581121] selection:bg-[#581121] selection:text-[#FAF4EB] font-sans antialiased">
      {/* ─────────────────────────────────────────────────────────────
          TOP FLOATING CAPSULE NAVBAR
      ─────────────────────────────────────────────────────────────── */}
      <header className="sticky top-4 z-50 flex justify-center px-4 sm:px-6">
        <div className="w-full max-w-5xl bg-[#FAF5EB]/95 backdrop-blur-md border-[1.5px] border-[#581121] rounded-full py-2.5 px-5 sm:px-7 flex items-center justify-between shadow-[0_4px_20px_rgba(88,17,33,0.06)] transition-all">
          {/* Logo */}
          <a href="#" className="flex items-center space-x-2.5 group">
            <img src={saynLogo} alt="SAYN Logo" className="w-8 h-8 rounded-lg shadow-sm object-contain" />
            <span className="font-extrabold text-lg tracking-wider text-[#581121]">SAYN</span>
          </a>

          {/* Desktop Nav Links */}
          <nav className="hidden md:flex items-center space-x-6 text-[14px] font-semibold text-[#581121]">
            <a
              href="#download"
              onClick={() => setActiveNav('download')}
              className={`hover:opacity-70 transition-opacity ${activeNav === 'download' ? 'border-b-2 border-[#581121] pb-0.5' : ''}`}
            >
              Download
            </a>
            <a
              href="#about"
              onClick={() => setActiveNav('about')}
              className={`hover:opacity-70 transition-opacity ${activeNav === 'about' ? 'border-b-2 border-[#581121] pb-0.5' : ''}`}
            >
              About
            </a>
            <a
              href="#how-it-works"
              onClick={() => setActiveNav('how-it-works')}
              className={`hover:opacity-70 transition-opacity ${activeNav === 'how-it-works' ? 'border-b-2 border-[#581121] pb-0.5' : ''}`}
            >
              How It Works
            </a>
            <a
              href="#features"
              onClick={() => setActiveNav('features')}
              className={`hover:opacity-70 transition-opacity ${activeNav === 'features' ? 'border-b-2 border-[#581121] pb-0.5' : ''}`}
            >
              What SAYN Does
            </a>
            <a
              href="#privacy"
              onClick={() => setActiveNav('privacy')}
              className={`hover:opacity-70 transition-opacity ${activeNav === 'privacy' ? 'border-b-2 border-[#581121] pb-0.5' : ''}`}
            >
              Privacy
            </a>
          </nav>

          {/* CTA Button */}
          <div className="flex items-center space-x-3">
            <button
              onClick={openDownload}
              className="bg-[#581121] hover:bg-[#450B18] text-[#FAF4EB] font-medium text-xs sm:text-sm px-4 sm:px-5 py-2 sm:py-2.5 rounded-full flex items-center space-x-1.5 transition-all shadow-sm active:scale-95"
            >
              <span>Get Started</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </header>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 1: HERO SECTION
      ─────────────────────────────────────────────────────────────── */}
      <section id="hero" className="relative pt-12 pb-20 sm:pt-16 sm:pb-28 overflow-hidden">
        {/* Organic Wine Maroon Curved Ribbon on the right */}
        <div className="absolute top-0 right-0 w-[55vw] max-w-[850px] h-[95%] pointer-events-none z-0 hidden lg:block overflow-hidden">
          <svg
            className="w-full h-full"
            viewBox="0 0 700 700"
            fill="none"
            preserveAspectRatio="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              d="M 280 0 C 120 180 80 420 340 560 C 470 630 620 680 700 700 L 700 0 Z"
              fill="#581121"
            />
          </svg>
        </div>

        <div className="max-w-6xl mx-auto px-5 sm:px-8 relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
            {/* Left Headline & Action */}
            <div className="lg:col-span-6 flex flex-col items-start pr-0 lg:pr-4">
              <h1 className="font-serif-editorial text-[48px] sm:text-[62px] md:text-[74px] leading-[1.05] tracking-tight font-extrabold text-[#581121] mb-6">
                Say what you <br />
                mean. <br />
                <span className="italic font-normal">Write it better.</span>
              </h1>

              <p className="text-[17px] sm:text-[19px] text-[#581121]/90 leading-relaxed max-w-md mb-8 font-normal">
                Talk naturally. SAYN turns your words into clear, polished messages.
              </p>

              <div className="flex flex-wrap items-center gap-3.5 sm:gap-4">
                <button
                  onClick={openDownload}
                  className="bg-[#3D0A16] hover:bg-[#2B060F] text-[#FAF4EB] font-medium text-[15px] px-6 py-3.5 rounded-full flex items-center space-x-2.5 transition-all shadow-md active:scale-95"
                >
                  <Apple className="w-4 h-4 fill-current" />
                  <span>Download for Mac</span>
                </button>

                <a
                  href="#how-it-works"
                  className="border-[1.5px] border-[#581121] hover:bg-[#581121]/5 text-[#581121] font-semibold text-[15px] px-6 py-3.5 rounded-full flex items-center space-x-2 transition-all active:scale-95"
                >
                  <span>See how it works</span>
                  <ArrowRight className="w-4 h-4" />
                </a>
              </div>
            </div>

            {/* Right Desktop Studio App Mockup */}
            <div className="lg:col-span-6 flex justify-center">
              <div className="w-full max-w-[540px] bg-[#3A0A16] border border-[#521323] rounded-2xl p-4 sm:p-5 shadow-[0_25px_60px_rgba(40,6,15,0.45)] text-[#FAF4EB]">
                {/* macOS Window Title Bar */}
                <div className="flex items-center justify-between pb-3.5 mb-3.5 border-b border-[#521323]/60">
                  <div className="flex items-center space-x-2">
                    <div className="w-2.5 h-2.5 rounded-full bg-[#FF5F56]" />
                    <div className="w-2.5 h-2.5 rounded-full bg-[#FFBD2E]" />
                    <div className="w-2.5 h-2.5 rounded-full bg-[#27C93F]" />
                  </div>
                  <div className="flex items-center space-x-1.5 opacity-90">
                    <img src={saynLogo} alt="SAYN" className="w-5 h-5 rounded object-contain" />
                    <span className="text-xs font-bold tracking-widest text-[#FAF4EB]">SAYN</span>
                  </div>
                  <div className="w-12" />
                </div>

                {/* 3-Pane Horizontal Studio Layout */}
                <div className="grid grid-cols-12 gap-3 items-stretch">
                  {/* Pane 1: Sidebar Modes */}
                  <div className="col-span-12 sm:col-span-3 flex sm:flex-col gap-1.5 justify-between sm:justify-start">
                    <button
                      onClick={() => setActiveStudioTab('write')}
                      className={`flex items-center space-x-2 px-3 py-2 rounded-xl text-xs font-bold transition-all text-left ${
                        activeStudioTab === 'write'
                          ? 'bg-[#FAF4EB] text-[#581121] shadow-sm'
                          : 'text-[#FAF4EB]/70 hover:bg-[#521323]/40'
                      }`}
                    >
                      <Mic className="w-3.5 h-3.5 flex-shrink-0" />
                      <span>Write</span>
                    </button>
                    <button
                      onClick={() => setActiveStudioTab('improve')}
                      className={`flex items-center space-x-2 px-3 py-2 rounded-xl text-xs font-bold transition-all text-left ${
                        activeStudioTab === 'improve'
                          ? 'bg-[#FAF4EB] text-[#581121] shadow-sm'
                          : 'text-[#FAF4EB]/70 hover:bg-[#521323]/40'
                      }`}
                    >
                      <Sparkles className="w-3.5 h-3.5 flex-shrink-0" />
                      <span>Improve</span>
                    </button>
                    <button
                      onClick={() => setActiveStudioTab('shorten')}
                      className={`flex items-center space-x-2 px-3 py-2 rounded-xl text-xs font-bold transition-all text-left ${
                        activeStudioTab === 'shorten'
                          ? 'bg-[#FAF4EB] text-[#581121] shadow-sm'
                          : 'text-[#FAF4EB]/70 hover:bg-[#521323]/40'
                      }`}
                    >
                      <span className="text-xs">☰</span>
                      <span>Shorten</span>
                    </button>
                    <button
                      onClick={() => setActiveStudioTab('detail')}
                      className={`flex items-center space-x-2 px-3 py-2 rounded-xl text-xs font-bold transition-all text-left ${
                        activeStudioTab === 'detail'
                          ? 'bg-[#FAF4EB] text-[#581121] shadow-sm'
                          : 'text-[#FAF4EB]/70 hover:bg-[#521323]/40'
                      }`}
                    >
                      <span className="text-xs">⊕</span>
                      <span>Add detail</span>
                    </button>
                  </div>

                  {/* Pane 2: Middle Voice Recorder Card */}
                  <div className="col-span-12 sm:col-span-4 bg-[#28060F] border border-[#521323] rounded-xl p-3.5 flex flex-col items-center justify-between min-h-[170px]">
                    <span className="text-[11px] font-mono opacity-60">
                      00:{audioSeconds < 10 ? `0${audioSeconds}` : audioSeconds}
                    </span>

                    {/* Animated Waveform Bars */}
                    <div className="flex items-center justify-center space-x-1 my-3 h-12 w-full">
                      {[18, 36, 22, 44, 28, 48, 32, 40, 20, 34, 16].map((h, i) => (
                        <div
                          key={i}
                          className="w-1 bg-[#FAF4EB] rounded-full transition-all duration-200"
                          style={{
                            height: isListening ? `${Math.max(10, (h * (0.6 + 0.4 * Math.sin(audioSeconds * 2 + i))))}px` : '6px',
                            opacity: isListening ? 0.95 : 0.35,
                          }}
                        />
                      ))}
                    </div>

                    <span className="text-xs font-medium opacity-80 mb-2">
                      {isListening ? 'Listening...' : 'Paused'}
                    </span>

                    {/* Stop/Play button */}
                    <button
                      onClick={() => setIsListening(!isListening)}
                      className="w-8 h-8 rounded-full bg-[#FAF4EB]/10 hover:bg-[#FAF4EB]/20 border border-[#FAF4EB]/30 flex items-center justify-center transition-all active:scale-90"
                    >
                      {isListening ? (
                        <Square className="w-3.5 h-3.5 fill-[#FAF4EB] text-[#FAF4EB]" />
                      ) : (
                        <Play className="w-3.5 h-3.5 fill-[#FAF4EB] text-[#FAF4EB] ml-0.5" />
                      )}
                    </button>
                  </div>

                  {/* Pane 3: Right Message Card */}
                  <div className="col-span-12 sm:col-span-5 bg-[#28060F] border border-[#521323] rounded-xl p-3 flex flex-col justify-between min-h-[170px]">
                    <div>
                      <span className="text-[11px] font-semibold text-[#FAF4EB]/70 block mb-2">Your message</span>
                      <p className="text-[12.5px] leading-relaxed text-[#FAF4EB] font-normal">
                        {studioTabMessages[activeStudioTab]}
                      </p>
                    </div>

                    <button
                      onClick={() => handleCopyMessage(studioTabMessages[activeStudioTab])}
                      className="mt-3 w-full bg-[#FAF4EB] hover:bg-white text-[#581121] text-xs font-bold py-2 px-3 rounded-lg flex items-center justify-center space-x-1.5 transition-all active:scale-95 shadow-sm"
                    >
                      {copiedMessage ? (
                        <>
                          <Check className="w-3.5 h-3.5 text-emerald-700" />
                          <span>Copied!</span>
                        </>
                      ) : (
                        <>
                          <Copy className="w-3.5 h-3.5" />
                          <span>Copy message</span>
                        </>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 2: INTERACTIVE BEFORE / AFTER SLIDER
      ─────────────────────────────────────────────────────────────── */}
      <section id="how-it-works" className="py-20 sm:py-28 px-5 sm:px-8 border-t border-[#581121]/15">
        <div className="max-w-5xl mx-auto">
          {/* Section Heading */}
          <div className="text-center mb-12 sm:mb-16">
            <h2 className="font-serif-editorial text-[38px] sm:text-[54px] md:text-[62px] font-bold text-[#581121] leading-tight mb-4">
              Turn rough speech into <br className="hidden sm:inline" />
              <span className="italic font-normal">clear messages.</span>
            </h2>
            <p className="text-[16px] sm:text-[18px] text-[#581121]/80 max-w-xl mx-auto">
              Move the slider to see your words get clearer.
            </p>
          </div>

          {/* Large Outlined Interactive Comparison Card */}
          <div className="border-[1.5px] border-[#581121] rounded-3xl p-6 sm:p-10 bg-[#FAF4EB] mb-8 shadow-sm">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 sm:gap-8 items-stretch relative">
              {/* Left Column: Original */}
              <div className="flex flex-col">
                <span className="text-xs font-bold uppercase tracking-wider text-[#581121] mb-2.5">Original</span>
                <div className="flex-1 border border-[#581121] rounded-2xl p-5 bg-white/40 min-h-[120px] flex items-center">
                  <p
                    className="text-[15px] sm:text-[16px] text-[#581121] leading-relaxed transition-opacity duration-200"
                    style={{ opacity: 1 - (sliderValue / 100) * 0.4 }}
                  >
                    Hey team, um, I reviewed the latest updates. You know, the design is basically ready for Thursday, uh, actually.
                  </p>
                </div>
              </div>

              {/* Vertical Divider for desktop */}
              <div className="hidden md:block absolute left-1/2 top-4 bottom-4 w-[1px] bg-[#581121]/30 -translate-x-1/2" />

              {/* Right Column: Clearer */}
              <div className="flex flex-col">
                <span className="text-xs font-bold uppercase tracking-wider text-[#581121] mb-2.5">Clearer</span>
                <div className="flex-1 border border-[#581121] rounded-2xl p-5 bg-white/40 min-h-[120px] flex items-center">
                  <p
                    className="text-[15px] sm:text-[16px] text-[#581121] leading-relaxed transition-opacity duration-200"
                    style={{ opacity: 0.5 + (sliderValue / 100) * 0.5 }}
                  >
                    Hey team, I reviewed the latest updates. The design is on track for Thursday.
                  </p>
                </div>
              </div>
            </div>

            {/* Slider Control Row */}
            <div className="mt-8 pt-6 border-t border-[#581121]/20 flex flex-col sm:flex-row items-center justify-between gap-6">
              <div className="w-full sm:flex-1 flex items-center space-x-4 max-w-xl">
                <span className="text-xs font-bold text-[#581121] whitespace-nowrap">Original</span>
                <div className="relative flex-1 flex items-center">
                  <input
                    type="range"
                    min="0"
                    max="100"
                    value={sliderValue}
                    onChange={(e) => setSliderValue(Number(e.target.value))}
                    className="w-full h-2 bg-[#581121]/20 rounded-lg appearance-none cursor-pointer accent-[#581121]"
                  />
                </div>
                <span className="text-xs font-bold text-[#581121] whitespace-nowrap">Clearer</span>
              </div>

              <button
                onClick={() => setSliderValue(100)}
                className="bg-[#581121] hover:bg-[#450B18] text-[#FAF4EB] text-xs sm:text-sm font-semibold px-5 py-2.5 rounded-full flex items-center space-x-1.5 transition-all active:scale-95 shadow-sm whitespace-nowrap"
              >
                <span>Show improved version</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          {/* 3 Outlined Feature Cards Below */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            {/* Card 1 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-5 sm:p-6 bg-[#FAF4EB] flex items-start space-x-4">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center flex-shrink-0 text-[#581121]">
                <span className="text-lg font-bold">〰</span>
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#581121] mb-1">Remove filler words</h4>
                <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                  Take out 'um', 'like', and repeated words.
                </p>
              </div>
            </div>

            {/* Card 2 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-5 sm:p-6 bg-[#FAF4EB] flex items-start space-x-4">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center flex-shrink-0 text-[#581121]">
                <span className="text-lg font-bold">☰</span>
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#581121] mb-1">Make it shorter</h4>
                <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                  Keep the message clear and to the point.
                </p>
              </div>
            </div>

            {/* Card 3 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-5 sm:p-6 bg-[#FAF4EB] flex items-start space-x-4">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center flex-shrink-0 text-[#581121]">
                <FileText className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#581121] mb-1">Paste anywhere</h4>
                <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                  Put the finished text straight into your app.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 3: DEEP WINE MAROON SECTION (Speed & Typing Comparison)
      ─────────────────────────────────────────────────────────────── */}
      <section className="bg-[#581121] text-[#FAF4EB] py-20 sm:py-28 px-5 sm:px-8 selection:bg-[#FAF4EB] selection:text-[#581121]">
        <div className="max-w-5xl mx-auto">
          {/* Section Heading */}
          <div className="text-center mb-12 sm:mb-16">
            <h2 className="font-serif-editorial text-[38px] sm:text-[54px] md:text-[62px] font-bold text-[#FAF4EB] leading-tight mb-4">
              Speak naturally. <span className="italic font-normal">Type faster.</span>
            </h2>
            <p className="text-[16px] sm:text-[18px] text-[#FAF4EB]/80 max-w-xl mx-auto font-normal">
              Turn your speech into clear text in the app you're using.
            </p>
          </div>

          {/* Interactive Speed Comparison Block */}
          <div className="grid grid-cols-1 lg:grid-cols-11 gap-6 items-center mb-16">
            {/* Left Card: Normal Typing */}
            <div className="lg:col-span-5 bg-[#420C18] border border-[#6B172A] rounded-2xl p-6 sm:p-7 flex flex-col justify-between min-h-[260px]">
              <div>
                <span className="text-xs font-bold text-[#FAF4EB]/70 block mb-1">Normal typing</span>
                <div className="flex items-baseline space-x-2 mb-4">
                  <span className="font-serif-editorial text-4xl sm:text-5xl font-bold text-[#FAF4EB]">45</span>
                  <span className="text-xs text-[#FAF4EB]/70">words/min</span>
                </div>
                <div className="border border-[#6B172A] rounded-xl p-4 bg-[#320812]/50 min-h-[110px]">
                  <p className="text-sm text-[#FAF4EB]/90 leading-relaxed font-mono">
                    {fullTypingText.slice(0, typedChars)}
                    <span className="animate-pulse inline-block w-1.5 h-4 bg-[#FAF4EB] ml-0.5 align-middle" />
                  </p>
                </div>
              </div>
            </div>

            {/* Center: Connector with Sound Waveform & Mic */}
            <div className="lg:col-span-1 flex flex-col items-center justify-center py-2">
              <div className="flex items-center space-x-0.5 mb-2">
                {[14, 26, 18, 32, 20, 28].map((h, idx) => (
                  <div
                    key={idx}
                    className="w-0.5 bg-[#FAF4EB]/80 rounded-full animate-pulse"
                    style={{ height: `${h}px`, animationDelay: `${idx * 150}ms` }}
                  />
                ))}
              </div>
              <div className="w-12 h-12 rounded-full bg-[#FAF4EB] text-[#581121] flex items-center justify-center shadow-lg my-1">
                <Mic className="w-6 h-6" />
              </div>
              <span className="text-[11px] font-medium text-[#FAF4EB]/80 mt-1 whitespace-nowrap">Speak naturally</span>
              <ArrowRight className="w-3.5 h-3.5 text-[#FAF4EB]/60 mt-0.5" />
            </div>

            {/* Right Card: With SAYN (High-Contrast Warm Cream Card) */}
            <div className="lg:col-span-5 bg-[#FAF4EB] text-[#581121] rounded-2xl p-6 sm:p-7 flex flex-col justify-between min-h-[260px] shadow-xl">
              <div>
                <span className="text-xs font-bold text-[#581121]/70 block mb-1">With SAYN</span>
                <div className="flex items-baseline space-x-2 mb-4">
                  <span className="font-serif-editorial text-4xl sm:text-5xl font-bold text-[#581121]">220</span>
                  <span className="text-xs text-[#581121]/70">words/min</span>
                </div>
                <div className="border border-[#581121] rounded-xl p-4 bg-white/50 min-h-[110px]">
                  <p className="text-sm text-[#581121] leading-relaxed">
                    Hey team, I reviewed the latest updates. The design migration is on track for Thursday.
                    <span className="inline-block w-1.5 h-4 bg-[#581121] ml-1 align-middle" />
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* 3 Bottom Feature Circles in Wine Section */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-8 border-t border-[#FAF4EB]/15">
            {/* Circle 1 */}
            <div className="flex items-start space-x-4">
              <div className="w-11 h-11 rounded-full border border-[#FAF4EB]/50 flex items-center justify-center flex-shrink-0 text-[#FAF4EB]">
                <Mic className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#FAF4EB] mb-1">Speak instead of typing</h4>
                <p className="text-xs sm:text-[13px] text-[#FAF4EB]/75 leading-relaxed">
                  Just talk naturally and let SAYN turn your speech into text.
                </p>
              </div>
            </div>

            {/* Circle 2 */}
            <div className="flex items-start space-x-4">
              <div className="w-11 h-11 rounded-full border border-[#FAF4EB]/50 flex items-center justify-center flex-shrink-0 text-[#FAF4EB]">
                <Sparkles className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#FAF4EB] mb-1">Clearer messages</h4>
                <p className="text-xs sm:text-[13px] text-[#FAF4EB]/75 leading-relaxed">
                  Automatically removes filler words and keeps your message clear.
                </p>
              </div>
            </div>

            {/* Circle 3 */}
            <div className="flex items-start space-x-4">
              <div className="w-11 h-11 rounded-full border border-[#FAF4EB]/50 flex items-center justify-center flex-shrink-0 text-[#FAF4EB]">
                <FileText className="w-5 h-5" />
              </div>
              <div>
                <h4 className="font-bold text-[15px] text-[#FAF4EB] mb-1">Works in your apps</h4>
                <p className="text-xs sm:text-[13px] text-[#FAF4EB]/75 leading-relaxed">
                  Type with your voice in any app on Mac, Windows, Android, and Web.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 4: 6-CARD FEATURES GRID
      ─────────────────────────────────────────────────────────────── */}
      <section id="features" className="py-20 sm:py-28 px-5 sm:px-8 border-t border-[#581121]/15">
        <div className="max-w-5xl mx-auto">
          {/* Section Heading */}
          <div className="text-center mb-12 sm:mb-16">
            <h2 className="font-serif-editorial text-[38px] sm:text-[54px] md:text-[62px] font-bold text-[#581121] leading-tight mb-4">
              Everything you need to <br className="hidden sm:inline" />
              write with <span className="italic font-normal">your voice.</span>
            </h2>
            <p className="text-[16px] sm:text-[18px] text-[#581121]/80 max-w-xl mx-auto font-normal">
              Speak naturally. SAYN turns your words into clear messages, wherever you're working.
            </p>
          </div>

          {/* 6 Clean Outlined Squircle Cards in a 2x3 Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Card 1 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <Mic className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Speak instead of typing</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                Turn your voice into text in seconds.
              </p>
            </div>

            {/* Card 2 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <FileText className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Fix your message</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                Clean up grammar and make your words clearer.
              </p>
            </div>

            {/* Card 3 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <Send className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Use it in your apps</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                Put your words into the app you're already using.
              </p>
            </div>

            {/* Card 4 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <Smartphone className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Works on your phone</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                Use voice typing on Android.
              </p>
            </div>

            {/* Card 5 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <Laptop className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Works on your computer</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                Use SAYN on Mac and Windows.
              </p>
            </div>

            {/* Card 6 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-6 sm:p-7 bg-[#FAF4EB] hover:bg-[#FAF4EB]/70 transition-all">
              <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-5 text-[#581121]">
                <InfinityIcon className="w-5 h-5" />
              </div>
              <h3 className="font-bold text-[17px] text-[#581121] mb-2">Free to use</h3>
              <p className="text-sm text-[#581121]/80 leading-relaxed">
                No subscription or word limits.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 5: ABOUT SAYN (Pillars & Values)
      ─────────────────────────────────────────────────────────────── */}
      <section id="about" className="py-20 sm:py-28 px-5 sm:px-8 border-t border-[#581121]/15">
        <div className="max-w-5xl mx-auto">
          {/* Section Heading */}
          <div className="text-center mb-12 sm:mb-16">
            <span className="text-xs font-extrabold tracking-widest uppercase text-[#581121] block mb-3">
              ABOUT SAYN
            </span>
            <h2 className="font-serif-editorial text-[38px] sm:text-[54px] md:text-[62px] font-bold text-[#581121] leading-tight mb-4">
              Made for the way <span className="italic font-normal">you think.</span>
            </h2>
            <p className="text-[16px] sm:text-[18px] text-[#581121]/80 max-w-xl mx-auto font-normal">
              Speaking is faster than typing. SAYN turns your natural speech into clear messages, so you can get your thoughts out without slowing down.
            </p>
          </div>

          {/* 3 Large Pillar Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* Pillar 1 */}
            <div className="border-[1.5px] border-[#581121] rounded-2xl p-7 sm:p-8 bg-[#FAF4EB] flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-6 text-[#581121]">
                  <InfinityIcon className="w-5 h-5" />
                </div>
                <h3 className="font-serif-editorial text-2xl font-bold text-[#581121] mb-3">
                  No subscription.
                </h3>
                <p className="text-sm text-[#581121]/80 leading-relaxed">
                  Speak as much as you need. No word limits or monthly fees.
                </p>
              </div>
            </div>

            {/* Pillar 2 */}
            <div id="features-detail" className="border-[1.5px] border-[#581121] rounded-2xl p-7 sm:p-8 bg-[#FAF4EB] flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-6 text-[#581121]">
                  <Sparkles className="w-5 h-5" />
                </div>
                <h3 className="font-serif-editorial text-2xl font-bold text-[#581121] mb-3">
                  Your words, made clearer.
                </h3>
                <p className="text-sm text-[#581121]/80 leading-relaxed">
                  SAYN removes filler words, fixes grammar, and helps your message sound natural.
                </p>
              </div>
            </div>

            {/* Pillar 3 */}
            <div id="privacy" className="border-[1.5px] border-[#581121] rounded-2xl p-7 sm:p-8 bg-[#FAF4EB] flex flex-col justify-between">
              <div>
                <div className="w-12 h-12 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center mb-6 text-[#581121]">
                  <Lock className="w-5 h-5" />
                </div>
                <h3 className="font-serif-editorial text-2xl font-bold text-[#581121] mb-3">
                  Your privacy matters.
                </h3>
                <p className="text-sm text-[#581121]/80 leading-relaxed">
                  Your voice is used to create your text. It's processed on your device and stored locally. We don't use your voice data to train models.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 6: INSTALLATION & QUICK SETUP (Screenshot 1)
      ─────────────────────────────────────────────────────────────── */}
      <section id="how-it-works" className="py-20 sm:py-28 px-5 sm:px-8 border-t border-[#581121]/15 bg-[#FAF4EB]">
        <div id="download" className="max-w-4xl mx-auto">
          {/* Section Heading */}
          <div className="text-center mb-10">
            <h2 className="font-serif-editorial text-[42px] sm:text-[56px] font-bold text-[#581121] leading-tight mb-3">
              Get SAYN set up in minutes.
            </h2>
            <p className="text-[16px] sm:text-[18px] text-[#581121]/80 max-w-xl mx-auto font-normal">
              Choose your computer, follow one simple step, and start speaking instead of typing.
            </p>
          </div>

          {/* Segmented Platform Pill Switcher */}
          <div className="flex justify-center mb-10">
            <div className="inline-flex items-center p-1 border-[1.5px] border-[#581121] rounded-full bg-transparent">
              <button
                onClick={() => setInstallPlatform('mac')}
                className={`flex items-center space-x-2 px-6 py-2.5 rounded-full text-sm font-semibold transition-all ${
                  installPlatform === 'mac'
                    ? 'bg-[#581121] text-[#FAF4EB] shadow-sm'
                    : 'text-[#581121] hover:bg-[#581121]/5'
                }`}
              >
                <Apple className="w-4 h-4 fill-current" />
                <span>Mac</span>
              </button>
              <button
                onClick={() => setInstallPlatform('windows')}
                className={`flex items-center space-x-2 px-6 py-2.5 rounded-full text-sm font-semibold transition-all ${
                  installPlatform === 'windows'
                    ? 'bg-[#581121] text-[#FAF4EB] shadow-sm'
                    : 'text-[#581121] hover:bg-[#581121]/5'
                }`}
              >
                <WindowsIcon className="w-4 h-4" />
                <span>Windows</span>
              </button>
            </div>
          </div>

          {/* Step-by-Step Card */}
          <div className="border-[1.5px] border-[#581121] rounded-3xl p-6 sm:p-10 bg-[#FAF4EB] shadow-sm mb-10">
            <div className="grid grid-cols-1 md:grid-cols-11 gap-4 items-center mb-8">
              {/* Step 1 */}
              <div className="md:col-span-3 flex items-start space-x-3.5">
                <div className="w-11 h-11 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center font-bold text-base text-[#581121] flex-shrink-0 mt-0.5">
                  1
                </div>
                <div>
                  <h4 className="font-serif-editorial text-[18px] font-bold text-[#581121] mb-1">
                    {installPlatform === 'mac' ? 'Open Terminal' : 'Open PowerShell'}
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                    {installPlatform === 'mac'
                      ? 'Press ⌘ + Space, search for Terminal, and open it.'
                      : 'Press ⊞ + X, select PowerShell or Terminal.'}
                  </p>
                </div>
              </div>

              {/* Arrow 1 */}
              <div className="hidden md:flex md:col-span-1 justify-center text-[#581121]/60">
                <ChevronRight className="w-5 h-5 stroke-[1.5]" />
              </div>

              {/* Step 2 */}
              <div className="md:col-span-3 flex items-start space-x-3.5">
                <div className="w-11 h-11 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center font-bold text-base text-[#581121] flex-shrink-0 mt-0.5">
                  2
                </div>
                <div>
                  <h4 className="font-serif-editorial text-[18px] font-bold text-[#581121] mb-1">
                    Paste the command
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                    Copy the command below and paste it into {installPlatform === 'mac' ? 'Terminal' : 'PowerShell'}.
                  </p>
                </div>
              </div>

              {/* Arrow 2 */}
              <div className="hidden md:flex md:col-span-1 justify-center text-[#581121]/60">
                <ChevronRight className="w-5 h-5 stroke-[1.5]" />
              </div>

              {/* Step 3 */}
              <div className="md:col-span-3 flex items-start space-x-3.5">
                <div className="w-11 h-11 rounded-full border-[1.5px] border-[#581121] flex items-center justify-center font-bold text-base text-[#581121] flex-shrink-0 mt-0.5">
                  3
                </div>
                <div>
                  <h4 className="font-serif-editorial text-[18px] font-bold text-[#581121] mb-1">
                    Press Enter
                  </h4>
                  <p className="text-xs sm:text-[13px] text-[#581121]/80 leading-relaxed">
                    SAYN will download and install automatically.
                  </p>
                </div>
              </div>
            </div>

            {/* Terminal Command Box */}
            <div className="border border-[#581121] rounded-2xl p-4 sm:p-5 bg-white/40 flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="flex items-center space-x-3 w-full overflow-x-auto font-mono text-xs sm:text-sm text-[#581121] py-1">
                <span className="text-[#581121]/60 font-bold">$</span>
                <span className="select-all font-semibold">
                  {installPlatform === 'mac' ? macCommand : windowsCommand}
                </span>
              </div>

              <button
                onClick={() =>
                  handleCopyInstallCommand(
                    installPlatform === 'mac' ? macCommand : windowsCommand
                  )
                }
                className="w-full sm:w-auto bg-[#581121] hover:bg-[#450B18] text-[#FAF4EB] text-xs sm:text-sm font-semibold px-6 py-3 rounded-xl flex items-center justify-center space-x-2 transition-all active:scale-95 shadow-sm whitespace-nowrap"
              >
                {copiedInstallCmd ? (
                  <>
                    <Check className="w-4 h-4 text-emerald-400" />
                    <span>Copied</span>
                  </>
                ) : (
                  <>
                    <Copy className="w-4 h-4" />
                    <span>Copy command</span>
                  </>
                )}
              </button>
            </div>
          </div>

          {/* OR Divider */}
          <div className="relative flex items-center justify-center my-8 max-w-xl mx-auto">
            <div className="w-full border-t border-[#581121]/30" />
            <span className="absolute bg-[#FAF4EB] px-4 text-xs font-bold text-[#581121]/70 tracking-widest">
              OR
            </span>
          </div>

          {/* Direct Download Buttons */}
          <div className="flex flex-wrap items-center justify-center gap-5">
            <a
              href="https://github.com/allanmaaz/sayn/releases/download/v1.1.5/sayn-macos.dmg"
              className="border-[1.5px] border-[#581121] hover:bg-[#581121]/5 text-[#581121] text-sm font-bold px-7 py-3.5 rounded-full flex items-center space-x-2.5 transition-all active:scale-95 shadow-sm"
            >
              <Apple className="w-4 h-4 fill-current" />
              <span>Download for Mac</span>
              <ArrowDown className="w-4 h-4 ml-1 stroke-[2]" />
            </a>

            <a
              href="https://github.com/allanmaaz/sayn/releases/download/v1.1.5/sayn-windows-setup.exe"
              className="border-[1.5px] border-[#581121] hover:bg-[#581121]/5 text-[#581121] text-sm font-bold px-7 py-3.5 rounded-full flex items-center space-x-2.5 transition-all active:scale-95 shadow-sm"
            >
              <WindowsIcon className="w-4 h-4" />
              <span>Download for Windows</span>
              <ArrowDown className="w-4 h-4 ml-1 stroke-[2]" />
            </a>
          </div>
        </div>
      </section>

      {/* ─────────────────────────────────────────────────────────────
          SCREEN 7: GRAND WINE MAROON FOOTER (Screenshot 2)
      ─────────────────────────────────────────────────────────────── */}
      <footer className="bg-[#480A17] text-[#FAF4EB] pt-16 pb-12 px-5 sm:px-8 selection:bg-[#FAF4EB] selection:text-[#480A17] overflow-hidden relative">
        <div className="max-w-6xl mx-auto">
          {/* Brand & Links Grid with Vertical Separators */}
          <div className="grid grid-cols-1 md:grid-cols-12 gap-8 lg:gap-12 pb-10 relative z-10 items-start">
            {/* Column 1: Brand & Tagline */}
            <div className="md:col-span-5 flex flex-col pr-0 sm:pr-6">
              <div className="flex items-center space-x-3 mb-5">
                <img src={saynLogo} alt="SAYN" className="w-8 h-8 rounded-lg shadow-sm object-contain" />
                <span className="font-extrabold text-xl text-[#FAF4EB] tracking-wider">SAYN</span>
              </div>
              <h3 className="font-serif-editorial text-[28px] sm:text-[32px] font-bold text-[#FAF4EB] mb-3 leading-snug">
                Say it. Refine it. Send it.
              </h3>
              <p className="text-sm text-[#FAF4EB]/75 leading-relaxed font-normal max-w-sm">
                Speak naturally. Write clearly. <br />
                Send with confidence.
              </p>
            </div>

            {/* Right 3 Columns with Vertical Hairline Dividers */}
            <div className="md:col-span-7 flex flex-col sm:flex-row items-start justify-between gap-6 sm:gap-0">
              {/* EXPLORE */}
              <div className="flex-1 sm:pr-6">
                <span className="text-xs font-bold uppercase tracking-widest text-[#FAF4EB]/60 mb-4 block">
                  EXPLORE
                </span>
                <ul className="space-y-3 text-sm font-medium text-[#FAF4EB]/85">
                  <li>
                    <a href="#how-it-works" className="hover:text-white transition-colors">How it works</a>
                  </li>
                  <li>
                    <a href="#download" className="hover:text-white transition-colors">Download</a>
                  </li>
                </ul>
              </div>

              {/* Vertical Divider 1 */}
              <div className="hidden sm:block w-[1px] bg-[#FAF4EB]/20 self-stretch my-1 mr-6" />

              {/* FEATURES */}
              <div className="flex-1 sm:px-6">
                <span className="text-xs font-bold uppercase tracking-widest text-[#FAF4EB]/60 mb-4 block">
                  FEATURES
                </span>
                <ul className="space-y-3 text-sm font-medium text-[#FAF4EB]/85">
                  <li>
                    <a href="#features" className="hover:text-white transition-colors">Voice typing</a>
                  </li>
                  <li>
                    <a href="#features" className="hover:text-white transition-colors">Writing improvement</a>
                  </li>
                  <li>
                    <a href="#features" className="hover:text-white transition-colors">Grammar correction</a>
                  </li>
                </ul>
              </div>

              {/* Vertical Divider 2 */}
              <div className="hidden sm:block w-[1px] bg-[#FAF4EB]/20 self-stretch my-1 mr-6" />

              {/* PRIVACY */}
              <div className="flex-1 sm:pl-6">
                <span className="text-xs font-bold uppercase tracking-widest text-[#FAF4EB]/60 mb-4 block">
                  PRIVACY
                </span>
                <ul className="space-y-3 text-sm font-medium text-[#FAF4EB]/85">
                  <li>
                    <a href="#privacy" className="hover:text-white transition-colors">Privacy policy</a>
                  </li>
                  <li>
                    <a href="#privacy" className="hover:text-white transition-colors">Data handling</a>
                  </li>
                  <li>
                    <a href="mailto:contact@sayn.ai" className="hover:text-white transition-colors">Contact</a>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* GIGANTIC HOLLOW OUTLINE WIREFRAME "SAYN" WORDMARK */}
          <div className="pt-6 pb-6 select-none pointer-events-none text-center overflow-hidden">
            <svg
              className="w-full h-auto max-h-[180px] sm:max-h-[240px] md:max-h-[300px]"
              viewBox="0 0 1100 240"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <text
                x="50%"
                y="65%"
                textAnchor="middle"
                dominantBaseline="middle"
                fontSize="240"
                fontFamily="'Plus Jakarta Sans', system-ui, -apple-system, sans-serif"
                fontWeight="800"
                letterSpacing="45"
                stroke="#FAF4EB"
                strokeWidth="1.8"
                strokeOpacity="0.45"
                fill="none"
              >
                SAYN
              </text>
            </svg>
          </div>

          {/* Bottom Hairline Bar */}
          <div className="pt-6 border-t border-[#FAF4EB]/20 flex flex-col sm:flex-row items-center justify-between text-xs text-[#FAF4EB]/60 gap-4">
            <span>© 2026 SAYN. All rights reserved.</span>
            <span className="font-serif-editorial text-sm italic text-[#FAF4EB]/80">
              Say it. Refine it. Send it.
            </span>
          </div>
        </div>
      </footer>

      {/* Download Modal */}
      <DownloadModal
        isOpen={isDownloadOpen}
        onClose={() => setIsDownloadOpen(false)}
      />
    </div>
  );
};
