import React, { useState } from 'react';
import { Link } from 'react-router-dom';
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
} from 'lucide-react';
import { detectDevice, DeviceInfo } from '../../utils/deviceDetector.js';
import { DownloadModal } from '../../components/download/DownloadModal.js';

export const LandingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'refine' | 'voice' | 'overlay'>('refine');
  const [copiedDemo, setCopiedDemo] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const [device, setDevice] = useState<DeviceInfo | null>(null);

  React.useEffect(() => {
    setDevice(detectDevice());
  }, []);

  const handleCopyDemo = () => {
    navigator.clipboard.writeText(
      'Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday.'
    );
    setCopiedDemo(true);
    setTimeout(() => setCopiedDemo(false), 2000);
  };

  return (
    <div className="flex-1 flex flex-col bg-[#100709] text-[#F5EBDD] overflow-hidden">
      {/* 1. HERO SECTION (Matching SAYN Landing Page Mockup) */}
      <section className="relative pt-12 pb-20 md:pt-20 md:pb-28 overflow-hidden">
        {/* Ambient Maroon Specular Lighting Glows */}
        <div className="absolute top-1/4 left-1/4 -translate-x-1/2 -translate-y-1/2 w-[550px] h-[550px] bg-[#6F1025]/25 rounded-full blur-[140px] pointer-events-none" />
        <div className="absolute bottom-10 right-10 w-[600px] h-[600px] bg-[#A83249]/20 rounded-full blur-[160px] pointer-events-none" />
        <div className="absolute top-1/2 right-1/4 w-[400px] h-[400px] bg-[#6F1025]/15 rounded-full blur-[120px] pointer-events-none" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
            
            {/* Left Hero Column: Typography & CTAs */}
            <div className="lg:col-span-6 text-left">
              {/* Tagline Pill */}
              <div className="inline-flex items-center space-x-2.5 px-4 py-1.5 rounded-full bg-[#180B0F] border border-[#A83249]/50 shadow-[0_0_20px_rgba(111,16,37,0.3)] mb-8 animate-in fade-in slide-in-from-bottom-2 duration-300">
                <span className="flex items-center space-x-0.5 text-[#A83249]">
                  <span className="w-1 h-3 bg-[#A83249] rounded-full animate-pulse" />
                  <span className="w-1 h-4 bg-[#F5EBDD] rounded-full animate-pulse delay-75" />
                  <span className="w-1 h-2 bg-[#A83249] rounded-full animate-pulse delay-150" />
                </span>
                <span className="text-xs font-semibold tracking-wide text-[#F5EBDD]">
                  Say it. Refine it. Send it.
                </span>
              </div>

              {/* Primary Headline */}
              <h1 className="text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight text-[#F5EBDD] leading-[1.06] mb-6">
                Your voice.<br />
                Your words.<br />
                <span className="text-[#A83249]">Better.</span>
              </h1>

              {/* Supporting Copy */}
              <p className="max-w-xl text-base sm:text-lg text-[#D6C7B2] leading-relaxed mb-9">
                Speak naturally, refine your writing with AI, and communicate better across Mac, Windows, Android, and Web.
              </p>

              {/* Dynamic Auto-Detected Action CTAs */}
              <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-4 mb-8">
                {/* Primary Warm Cream Button */}
                <button
                  onClick={() => setIsDownloadOpen(true)}
                  className="inline-flex items-center justify-center space-x-2.5 px-7 py-3.5 rounded-full font-bold text-sm bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_24px_rgba(245,235,221,0.25)]"
                >
                  <Download className="w-4 h-4 stroke-[2.5]" />
                  <span>
                    Download for {device?.osName || 'macOS'}
                  </span>
                </button>

                {/* Secondary Maroon Bordered Button */}
                <Link
                  to="/workspace"
                  className="inline-flex items-center justify-center space-x-2 px-7 py-3.5 rounded-full font-semibold text-sm text-[#F5EBDD] bg-[#100709] border border-[#A83249] hover:bg-[#6F1025]/30 hover:border-[#F5EBDD]/40 transition-all shadow-sm"
                >
                  <span>Try Web Studio</span>
                  <ArrowRight className="w-4 h-4" />
                </Link>
              </div>

              {/* Platform Badges Row */}
              <div className="flex items-center space-x-6 text-xs text-[#D6C7B2] font-medium pt-2">
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <span></span>
                  <span>macOS</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <span>⊞</span>
                  <span>Windows</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <span>🤖</span>
                  <span>Android</span>
                </span>
                <span className="inline-flex items-center space-x-1.5 hover:text-[#F5EBDD] transition-colors">
                  <Globe className="w-3.5 h-3.5 text-[#A83249]" />
                  <span>Web</span>
                </span>
              </div>
            </div>

            {/* Right Hero Column: 3D Laptop Studio Showcase */}
            <div className="lg:col-span-6 relative">
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
                      <img src="/logo.svg" alt="SAYN Logo" className="w-6 h-6 rounded-md" />
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
                        <span>✓ Ready to paste</span>
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
      </section>

      {/* 2. THREE-PILLAR CAPABILITIES SECTION */}
      <section id="features" className="py-24 border-t border-[#3D1520] bg-[#14080D]/80 relative">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
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
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <Mic className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Voice to Text</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Turn natural speech into crisp, punctuated text with zero cloud lock-in. Powered by high-speed Groq Whisper LPUs.
              </p>
            </div>

            {/* Card 2: AI Writing Assistant */}
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <PenTool className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">QuillBot & Grammarly Refinement</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Correct grammar, paraphrase word-by-word, adjust tone (Fluent, Professional, Natural), and optimize clarity in real time.
              </p>
            </div>

            {/* Card 3: Floating Assistant */}
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <Layers className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Desktop & Mobile Assistant</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                A sleek floating pill on Mac and Windows, plus Android overlay and keyboard. Automatically pastes into any active chatbot or document.
              </p>
            </div>

            {/* Card 4: Smart Keyboard */}
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <Keyboard className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Android Smart Keyboard</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Custom mobile IME with one-tap voice dictation, instant grammar linting, and integrated emoji palette elevated above the gesture bar.
              </p>
            </div>

            {/* Card 5: Cross Platform */}
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <Laptop className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">Universal Compatibility</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Native DMG for macOS (Silicon + Intel), portable installer for Windows (64-bit + 32-bit), release APK for Android, and progressive Web Studio.
              </p>
            </div>

            {/* Card 6: Privacy by Design */}
            <div className="p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249]/60 transition-all shadow-sm group">
              <div className="w-12 h-12 rounded-xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#F5EBDD] mb-5 group-hover:scale-105 transition-transform">
                <ShieldCheck className="w-6 h-6 text-[#A83249]" />
              </div>
              <h3 className="text-lg font-bold text-[#F5EBDD] mb-2">100% Free & Unlimited</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Zero rupees held. Unlimited usage with zero-prompt embedded keys. Audio is processed ephemerally and discarded immediately.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 3. HOW IT WORKS SECTION */}
      <section id="how-it-works" className="py-24 border-t border-[#3D1520] bg-[#100709]">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <span className="text-xs font-bold uppercase tracking-widest text-[#A83249] mb-2 block">
              Workflow
            </span>
            <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD] mb-3">
              How It Works
            </h2>
            <p className="text-sm text-[#D6C7B2]">
              A frictionless three-step process to elevate any communication in seconds.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="flex flex-col items-center text-center p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520]">
              <div className="w-11 h-11 rounded-full bg-[#6F1025] text-[#F5EBDD] font-mono text-sm font-bold flex items-center justify-center mb-5 shadow-md">
                1
              </div>
              <h3 className="font-bold text-base text-[#F5EBDD] mb-2">Speak or Type</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Record your voice with Fn or Alt+Space, or paste a rough thought without worrying about phrasing or punctuation.
              </p>
            </div>

            <div className="flex flex-col items-center text-center p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520]">
              <div className="w-11 h-11 rounded-full bg-[#6F1025] text-[#F5EBDD] font-mono text-sm font-bold flex items-center justify-center mb-5 shadow-md">
                2
              </div>
              <h3 className="font-bold text-base text-[#F5EBDD] mb-2">Choose Refinement</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                Select your desired mode and style—Natural, Fluent, Professional, Prompt Mode, or Live Translation.
              </p>
            </div>

            <div className="flex flex-col items-center text-center p-7 rounded-2xl bg-[#1C0B12] border border-[#3D1520]">
              <div className="w-11 h-11 rounded-full bg-[#6F1025] text-[#F5EBDD] font-mono text-sm font-bold flex items-center justify-center mb-5 shadow-md">
                3
              </div>
              <h3 className="font-bold text-base text-[#F5EBDD] mb-2">Auto-Paste Anywhere</h3>
              <p className="text-xs sm:text-sm text-[#D6C7B2] leading-relaxed">
                The refined text automatically injects into your active chatbot, email, or editor. Zero manual Cmd+V required.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 4. PRIVACY SECTION */}
      <section id="privacy" className="py-24 border-t border-[#3D1520] bg-[#14080D]/80">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="w-14 h-14 rounded-2xl bg-[#6F1025]/30 border border-[#A83249]/40 text-[#A83249] flex items-center justify-center mx-auto mb-5 shadow-sm">
            <ShieldCheck className="w-7 h-7" />
          </div>
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
            Your Privacy Is Fundamental
          </h2>
          <p className="text-sm sm:text-base text-[#D6C7B2] leading-relaxed max-w-2xl mx-auto mb-10">
            SAYN processes text strictly for the requested transformation. We do not retain audio recordings after transcription, we do not log passwords or keystrokes, and you have full control over your writing history.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 text-left max-w-3xl mx-auto text-xs">
            <div className="p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520]">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>No Audio Retention</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Voice streams are ephemeral and discarded immediately after transcription.</p>
            </div>

            <div className="p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520]">
              <div className="flex items-center space-x-2 font-bold text-[#F5EBDD] mb-1.5">
                <CheckCircle2 className="w-4 h-4 text-[#30D158]" />
                <span>History Controls</span>
              </div>
              <p className="text-[#D6C7B2] leading-relaxed">Enable, disable, or purge your writing history anytime with one click.</p>
            </div>

            <div className="p-5 rounded-xl bg-[#1C0B12] border border-[#3D1520]">
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
      <section className="py-24 border-t border-[#3D1520] bg-gradient-to-b from-[#100709] to-[#1C0B12] text-center">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-4xl sm:text-5xl font-extrabold tracking-tight text-[#F5EBDD] mb-4">
            Write less. Say more.
          </h2>
          <p className="text-base text-[#D6C7B2] mb-9">
            Experience the clarity and speed of SAYN on your Mac, Windows, Android, or Web today.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <button
              onClick={() => setIsDownloadOpen(true)}
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2.5 px-8 py-4 rounded-full font-bold text-sm bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_24px_rgba(245,235,221,0.25)]"
            >
              <Download className="w-4 h-4 stroke-[2.5]" />
              <span>Download for {device?.osName || 'Your Device'}</span>
            </button>
            <Link
              to="/workspace"
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 px-8 py-4 rounded-full font-semibold text-sm text-[#F5EBDD] bg-[#100709] border border-[#A83249] hover:bg-[#6F1025]/30 transition-all"
            >
              <span>Start Using Web Studio</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* Smart Device Detection Download Modal */}
      <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
    </div>
  );
};
