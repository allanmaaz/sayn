import React, { useState } from 'react';
import {
  Smartphone,
  Download,
  CheckCircle,
  Sparkles,
  ShieldCheck,
  Zap,
  ArrowDown,
  Layers,
} from 'lucide-react';

interface AndroidDownloadCardProps {
  className?: string;
  isLight?: boolean;
}

export const AndroidDownloadCard: React.FC<AndroidDownloadCardProps> = ({
  className = '',
  isLight = false,
}) => {
  const [downloadTriggered, setDownloadTriggered] = useState(false);
  const apkDownloadUrl =
    'https://github.com/allanmaaz/sayn/releases/latest/download/sayn-release.apk';

  const handleDownload = () => {
    setDownloadTriggered(true);
    const link = document.createElement('a');
    link.href = apkDownloadUrl;
    link.setAttribute('download', 'sayn-release.apk');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setTimeout(() => setDownloadTriggered(false), 7000);
  };

  return (
    <div className={`w-full max-w-2xl mx-auto ${className}`}>
      {/* Main Card */}
      <div
        className={`p-6 sm:p-8 rounded-3xl border text-left relative overflow-hidden transition-all ${
          isLight
            ? 'bg-white border-[#E2D9CD] shadow-lg'
            : 'bg-[#18080E] border-[#3D1520] shadow-[0_12px_50px_rgba(111,16,37,0.3)]'
        }`}
      >
        {/* Subtle Ambient Glow */}
        <div className="absolute top-0 right-0 w-72 h-72 bg-[#6F1025]/20 rounded-full blur-3xl pointer-events-none -mr-20 -mt-20" />

        {/* Header with App Icon */}
        <div className="flex items-start space-x-4 mb-6 relative z-10">
          <div className="w-14 h-14 rounded-2xl bg-[#6F1025]/30 border border-[#A83249]/40 flex items-center justify-center text-[#A83249] flex-shrink-0 shadow-md">
            <Smartphone className="w-7 h-7" />
          </div>

          <div>
            <div className="flex items-center space-x-2.5">
              <h3
                className={`text-xl sm:text-2xl font-extrabold ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                SAYN for Android
              </h3>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                v1.1.2 Signed APK
              </span>
            </div>
            <p
              className={`text-xs sm:text-sm mt-1 ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              Voice-First Custom Keyboard &amp; Floating Microphone Overlay for WhatsApp, Slack, and every app.
            </p>
          </div>
        </div>

        {/* Feature Badges */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 mb-6 relative z-10">
          <div
            className={`p-3 rounded-xl border text-xs flex items-center space-x-2.5 ${
              isLight
                ? 'bg-[#FAF6F0] border-[#E8DFC9] text-[#2D0A12]'
                : 'bg-[#100709] border-[#3D1520] text-[#F5EBDD]'
            }`}
          >
            <Sparkles className="w-4 h-4 text-[#A83249] flex-shrink-0" />
            <span>Mammals Casual Texting (Zero Trailing Periods)</span>
          </div>

          <div
            className={`p-3 rounded-xl border text-xs flex items-center space-x-2.5 ${
              isLight
                ? 'bg-[#FAF6F0] border-[#E8DFC9] text-[#2D0A12]'
                : 'bg-[#100709] border-[#3D1520] text-[#F5EBDD]'
            }`}
          >
            <Layers className="w-4 h-4 text-[#A83249] flex-shrink-0" />
            <span>System-wide Floating Dictation Bubble</span>
          </div>

          <div
            className={`p-3 rounded-xl border text-xs flex items-center space-x-2.5 ${
              isLight
                ? 'bg-[#FAF6F0] border-[#E8DFC9] text-[#2D0A12]'
                : 'bg-[#100709] border-[#3D1520] text-[#F5EBDD]'
            }`}
          >
            <Zap className="w-4 h-4 text-[#A83249] flex-shrink-0" />
            <span>Spacebar Swipe Cursor &amp; Long-press Numbers</span>
          </div>

          <div
            className={`p-3 rounded-xl border text-xs flex items-center space-x-2.5 ${
              isLight
                ? 'bg-[#FAF6F0] border-[#E8DFC9] text-[#2D0A12]'
                : 'bg-[#100709] border-[#3D1520] text-[#F5EBDD]'
            }`}
          >
            <ShieldCheck className="w-4 h-4 text-[#30D158] flex-shrink-0" />
            <span>Zero Cloud Retention • Free &amp; Unlimited</span>
          </div>
        </div>

        {/* Prominent Direct APK Download Button */}
        <button
          onClick={handleDownload}
          className="w-full py-4 px-6 rounded-2xl font-extrabold text-sm sm:text-base bg-[#F5EBDD] hover:bg-white text-[#100709] active:scale-95 transition-all shadow-[0_6px_25px_rgba(245,235,221,0.25)] flex items-center justify-center space-x-3 relative z-10"
        >
          <Download className="w-5 h-5 stroke-[2.5]" />
          <span>Download Android APK (sayn-release.apk)</span>
        </button>

        {/* Download Alert Toast */}
        {downloadTriggered && (
          <div className="mt-4 p-3.5 rounded-xl bg-emerald-500/15 border border-emerald-500/30 flex items-center space-x-2.5 text-xs text-emerald-400 animate-in fade-in relative z-10">
            <CheckCircle className="w-4 h-4 flex-shrink-0" />
            <span>Download started! Pull down your notification shade and tap the APK to install.</span>
          </div>
        )}

        {/* 3-Step Sideloading Instructions */}
        <div
          className={`mt-6 pt-5 border-t text-xs relative z-10 ${
            isLight
              ? 'border-[#E2D9CD] text-[#706E6B]'
              : 'border-[#3D1520] text-[#D6C7B2]/70'
          }`}
        >
          <div className="font-bold text-[#A83249] uppercase tracking-wider mb-2 text-[10px]">
            Quick 3-Step Installation:
          </div>
          <ol className="space-y-1.5 list-decimal list-inside font-mono text-[11px]">
            <li>Tap <strong>Download Android APK</strong> above.</li>
            <li>Open the downloaded APK and tap <strong>Install</strong> (Allow from this source if prompted).</li>
            <li>Enable <strong>SAYN Keyboard</strong> in Settings ➔ System ➔ Languages &amp; Input.</li>
          </ol>
        </div>
      </div>
    </div>
  );
};
