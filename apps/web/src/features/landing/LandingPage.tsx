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
} from 'lucide-react';

export const LandingPage: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'refine' | 'voice' | 'overlay'>('refine');
  const [copiedDemo, setCopiedDemo] = useState(false);

  const handleCopyDemo = () => {
    navigator.clipboard.writeText(
      'Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for Thursday.'
    );
    setCopiedDemo(true);
    setTimeout(() => setCopiedDemo(false), 2000);
  };

  return (
    <div className="flex-1 flex flex-col">
      {/* 1. HERO SECTION */}
      <section className="relative pt-16 pb-20 md:pt-24 md:pb-28 overflow-hidden">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          {/* Subtle Tagline Pill */}
          <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-ios-pill bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider mb-6 animate-in fade-in slide-in-from-bottom-2 duration-300">
            <span className="w-2 h-2 rounded-full bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent" />
            <span className="text-xs font-medium text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              Say it. Refine it. Send it.
            </span>
          </div>

          {/* Primary Headline */}
          <h1 className="text-4xl sm:text-6xl font-bold tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text mb-6">
            Your voice. Your words. <span className="text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent">Better.</span>
          </h1>

          {/* Supporting Copy */}
          <p className="max-w-2xl mx-auto text-base sm:text-lg text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary leading-relaxed mb-10">
            Speak naturally, refine your writing with AI, and communicate better across the apps you use every day.
          </p>

          {/* Action CTAs */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16">
            <Link
              to="/workspace"
              className="w-full sm:w-auto inline-flex items-center justify-center space-x-2 px-6 py-3 rounded-ios-sm font-semibold text-sm text-white bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent hover:opacity-90 active:scale-95 transition-all shadow-sm"
            >
              <span>Get Started Free</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
            <a
              href="#how-it-works"
              className="w-full sm:w-auto inline-flex items-center justify-center px-6 py-3 rounded-ios-sm font-semibold text-sm text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider hover:bg-sayn-dark-surface2 transition-all"
            >
              See How It Works
            </a>
          </div>

          {/* 2. INTERACTIVE PRODUCT PREVIEW CARD */}
          <div className="relative mx-auto max-w-4xl rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider shadow-2xl overflow-hidden text-left">
            {/* Mock Window Header */}
            <div className="flex items-center justify-between px-4 py-3 border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider bg-sayn-dark-bg/50 dark:bg-sayn-dark-bg/50 light:bg-sayn-light-bg/50">
              <div className="flex items-center space-x-2">
                <div className="w-2.5 h-2.5 rounded-full bg-sayn-dark-divider" />
                <div className="w-2.5 h-2.5 rounded-full bg-sayn-dark-divider" />
                <div className="w-2.5 h-2.5 rounded-full bg-sayn-dark-divider" />
                <span className="text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted ml-2 font-mono">
                  sayn.app / preview
                </span>
              </div>

              {/* Mode Switcher Tabs */}
              <div className="flex items-center space-x-1 p-0.5 rounded-ios-sm bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider">
                <button
                  onClick={() => setActiveTab('refine')}
                  className={`px-2.5 py-1 rounded-ios-sm text-xs font-medium transition-colors ${
                    activeTab === 'refine'
                      ? 'bg-sayn-dark-accent text-white'
                      : 'text-sayn-dark-secondary hover:text-sayn-dark-text'
                  }`}
                >
                  AI Writer
                </button>
                <button
                  onClick={() => setActiveTab('voice')}
                  className={`px-2.5 py-1 rounded-ios-sm text-xs font-medium transition-colors ${
                    activeTab === 'voice'
                      ? 'bg-sayn-dark-accent text-white'
                      : 'text-sayn-dark-secondary hover:text-sayn-dark-text'
                  }`}
                >
                  Voice Mode
                </button>
                <button
                  onClick={() => setActiveTab('overlay')}
                  className={`px-2.5 py-1 rounded-ios-sm text-xs font-medium transition-colors ${
                    activeTab === 'overlay'
                      ? 'bg-sayn-dark-accent text-white'
                      : 'text-sayn-dark-secondary hover:text-sayn-dark-text'
                  }`}
                >
                  Floating Assistant
                </button>
              </div>
            </div>

            {/* Tab 1: AI Writer Interactive Preview */}
            {activeTab === 'refine' && (
              <div className="p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <div className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted mb-2">
                    Source Dictation / Rough Draft
                  </div>
                  <div className="p-4 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-xs text-sayn-dark-secondary leading-relaxed min-h-[140px]">
                    "hey so basically i checked the sprint tasks and design system stuff is pretty much done by thursday probably"
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-accent">
                      Refined Output (Professional)
                    </span>
                    <button
                      onClick={handleCopyDemo}
                      className="inline-flex items-center space-x-1 text-xs text-sayn-dark-secondary hover:text-sayn-dark-text"
                    >
                      {copiedDemo ? <Check className="w-3 h-3 text-sayn-dark-success" /> : <Copy className="w-3 h-3" />}
                      <span>{copiedDemo ? 'Copied' : 'Copy'}</span>
                    </button>
                  </div>
                  <div className="p-4 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-accent/40 text-xs text-sayn-dark-text leading-relaxed min-h-[140px]">
                    "Hey team, I reviewed the latest sprint deliverables. The design system migration is on track for completion this Thursday."
                  </div>
                </div>
              </div>
            )}

            {/* Tab 2: Voice Mode Waveform Preview */}
            {activeTab === 'voice' && (
              <div className="p-8 flex flex-col items-center justify-center text-center">
                <div className="w-16 h-16 rounded-full bg-sayn-dark-accent/15 border border-sayn-dark-accent/30 flex items-center justify-center text-sayn-dark-accent mb-4">
                  <Mic className="w-7 h-7" />
                </div>
                <div className="flex items-center space-x-1 h-8 mb-4">
                  {[30, 60, 90, 50, 80, 40, 100, 70, 40].map((h, i) => (
                    <div
                      key={i}
                      className="w-1 bg-sayn-audio rounded-full animate-pulse"
                      style={{ height: `${h}%` }}
                    />
                  ))}
                </div>
                <div className="text-xs font-mono text-sayn-dark-muted mb-2">00:14 • Recording Active</div>
                <p className="text-xs text-sayn-dark-secondary max-w-md">
                  "SAYN converts your natural voice directly into crisp, punctuated sentences with zero cloud lock-in."
                </p>
              </div>
            )}

            {/* Tab 3: Floating Assistant Concept Preview */}
            {activeTab === 'overlay' && (
              <div className="p-6 flex flex-col md:flex-row items-center justify-between gap-6">
                <div className="space-y-2">
                  <span className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-accent">
                    Android System Overlay
                  </span>
                  <h3 className="text-base font-semibold text-sayn-dark-text">
                    Dictate and Refine in Any App
                  </h3>
                  <p className="text-xs text-sayn-dark-secondary leading-relaxed max-w-sm">
                    A floating bubble that stays at your fingertips over WhatsApp, Gmail, Slack, and Instagram. Speak naturally, select a tone, and paste directly.
                  </p>
                </div>
                <div className="p-4 rounded-ios bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center space-x-3">
                  <div className="w-10 h-10 rounded-full bg-sayn-dark-surface border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent shadow-sm">
                    <Mic className="w-5 h-5 text-sayn-audio" />
                  </div>
                  <div className="text-xs">
                    <div className="font-semibold text-sayn-dark-text">SAYN Floating Bubble</div>
                    <div className="text-sayn-dark-muted">Tap to dictate anywhere</div>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* 3. FEATURE SHOWCASE SECTION */}
      <section id="features" className="py-20 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider bg-sayn-dark-bg/60">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text mb-3">
              Engineered for Effortless Communication
            </h2>
            <p className="text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              Three major capabilities united into one seamless companion: voice-to-text, intelligent writing refinement, and cross-application assistance.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {/* Card 1 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <Mic className="w-5 h-5 text-sayn-audio" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">Voice to Text</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Turn natural speech into readable, punctuated text without robotic pauses or errors.
              </p>
            </div>

            {/* Card 2 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <PenTool className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">AI Writing Assistant</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Correct grammar, paraphrase, adjust tone, improve clarity, or summarize across 12 specialized modes.
              </p>
            </div>

            {/* Card 3 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <Layers className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">Floating Assistant</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                On Android, access voice dictation and refinement directly above any application via a native system overlay.
              </p>
            </div>

            {/* Card 4 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <Keyboard className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">Smart Keyboard</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                A custom Android IME with built-in dictation and one-tap grammar correction directly inside text inputs.
              </p>
            </div>

            {/* Card 5 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <Laptop className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">Works Across Devices</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Access your workspace from modern desktop and mobile browsers, or download the native Android APK.
              </p>
            </div>

            {/* Card 6 */}
            <div className="p-6 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors">
              <div className="w-10 h-10 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider flex items-center justify-center text-sayn-dark-accent mb-4">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <h3 className="text-base font-semibold text-sayn-dark-text mb-2">Privacy by Design</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Zero audio retention by default. Strict Row-Level Security ensures only you have access to your saved data.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 4. HOW IT WORKS SECTION */}
      <section id="how-it-works" className="py-20 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text mb-3">
              How It Works
            </h2>
            <p className="text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              A frictionless three-step process to elevate any communication in seconds.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="flex flex-col items-center text-center p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="w-10 h-10 rounded-full bg-sayn-dark-accent/15 border border-sayn-dark-accent/30 text-sayn-dark-accent font-mono text-sm font-bold flex items-center justify-center mb-4">
                1
              </div>
              <h3 className="font-semibold text-sm text-sayn-dark-text mb-2">Speak or Type</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Record your voice or draft a quick thought without worrying about phrasing or punctuation.
              </p>
            </div>

            <div className="flex flex-col items-center text-center p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="w-10 h-10 rounded-full bg-sayn-dark-accent/15 border border-sayn-dark-accent/30 text-sayn-dark-accent font-mono text-sm font-bold flex items-center justify-center mb-4">
                2
              </div>
              <h3 className="font-semibold text-sm text-sayn-dark-text mb-2">Choose Refinement</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Select your desired mode and tone—professional, casual, concise, clear, or translated.
              </p>
            </div>

            <div className="flex flex-col items-center text-center p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="w-10 h-10 rounded-full bg-sayn-dark-accent/15 border border-sayn-dark-accent/30 text-sayn-dark-accent font-mono text-sm font-bold flex items-center justify-center mb-4">
                3
              </div>
              <h3 className="font-semibold text-sm text-sayn-dark-text mb-2">Copy or Send</h3>
              <p className="text-xs text-sayn-dark-secondary leading-relaxed">
                Inspect the output, compare changes, and copy or share directly into your favorite apps.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* 5. PRIVACY SECTION */}
      <section id="privacy" className="py-20 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider bg-sayn-dark-bg/60">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <div className="w-12 h-12 rounded-ios-sm bg-sayn-dark-surface border border-sayn-dark-divider text-sayn-dark-accent flex items-center justify-center mx-auto mb-4">
            <ShieldCheck className="w-6 h-6" />
          </div>
          <h2 className="text-2xl sm:text-3xl font-bold tracking-tight text-sayn-dark-text mb-4">
            Your Privacy Is Fundamental
          </h2>
          <p className="text-sm text-sayn-dark-secondary leading-relaxed max-w-2xl mx-auto mb-8">
            SAYN processes text strictly for the requested transformation. We do not retain audio recordings after transcription, we do not log passwords or keystrokes, and you have full control over your writing history.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-left max-w-3xl mx-auto text-xs">
            <div className="p-4 rounded-ios-sm bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="flex items-center space-x-2 font-semibold text-sayn-dark-text mb-1">
                <CheckCircle2 className="w-4 h-4 text-sayn-dark-success" />
                <span>No Audio Retention</span>
              </div>
              <p className="text-sayn-dark-secondary">Voice streams are ephemeral and discarded after processing.</p>
            </div>

            <div className="p-4 rounded-ios-sm bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="flex items-center space-x-2 font-semibold text-sayn-dark-text mb-1">
                <CheckCircle2 className="w-4 h-4 text-sayn-dark-success" />
                <span>History Controls</span>
              </div>
              <p className="text-sayn-dark-secondary">Enable, disable, or purge your writing history anytime with one click.</p>
            </div>

            <div className="p-4 rounded-ios-sm bg-sayn-dark-surface border border-sayn-dark-divider">
              <div className="flex items-center space-x-2 font-semibold text-sayn-dark-text mb-1">
                <CheckCircle2 className="w-4 h-4 text-sayn-dark-success" />
                <span>Sensitive Field Guard</span>
              </div>
              <p className="text-sayn-dark-secondary">Password and secure fields are excluded from external AI processing.</p>
            </div>
          </div>
        </div>
      </section>

      {/* 6. FINAL CALL TO ACTION */}
      <section className="py-20 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-center">
        <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-sayn-dark-text mb-4">
            Write less. Say more.
          </h2>
          <p className="text-sm text-sayn-dark-secondary mb-8">
            Experience the clarity and speed of SAYN on the web today.
          </p>
          <Link
            to="/workspace"
            className="inline-flex items-center space-x-2 px-6 py-3 rounded-ios-sm font-semibold text-sm text-white bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent hover:opacity-90 active:scale-95 transition-all shadow-sm"
          >
            <span>Start Using SAYN</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>
    </div>
  );
};
