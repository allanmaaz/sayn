import React, { useState, useEffect } from 'react';
import {
  Copy,
  Check,
  Terminal,
  Apple,
  Monitor,
  Download,
  Sparkles,
  Command,
  ArrowRight,
} from 'lucide-react';
import { detectDevice } from '../../utils/deviceDetector.js';

interface TerminalInstallProps {
  className?: string;
  isLight?: boolean;
}

export const TerminalInstall: React.FC<TerminalInstallProps> = ({
  className = '',
  isLight = false,
}) => {
  const [activePlatform, setActivePlatform] = useState<'macos' | 'windows'>('macos');
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const dev = detectDevice();
    if (dev.os === 'windows') {
      setActivePlatform('windows');
    } else {
      setActivePlatform('macos');
    }
  }, []);

  const commands = {
    macos: 'curl -fsSL https://sayn.ai/install.sh | bash',
    windows: 'irm https://sayn.ai/install.ps1 | iex',
  };

  const handleCopy = async () => {
    const cmd = commands[activePlatform];
    try {
      await navigator.clipboard.writeText(cmd);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      // Fallback if clipboard API blocked
      const ta = document.createElement('textarea');
      ta.value = cmd;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    }
  };

  return (
    <div className={`w-full max-w-4xl mx-auto ${className}`}>
      {/* Platform Switcher Tabs */}
      <div className="flex items-center justify-center mb-6">
        <div
          className={`inline-flex p-1.5 rounded-2xl border ${
            isLight
              ? 'bg-[#EFEAE2] border-[#D4C8B8]'
              : 'bg-[#18080E] border-[#3D1520]'
          } shadow-inner`}
        >
          <button
            onClick={() => {
              setActivePlatform('macos');
              setCopied(false);
            }}
            className={`flex items-center space-x-2.5 px-5 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
              activePlatform === 'macos'
                ? isLight
                  ? 'bg-white text-[#2D0A12] shadow-sm'
                  : 'bg-[#6F1025] text-[#F5EBDD] shadow-[0_2px_12px_rgba(111,16,37,0.4)]'
                : isLight
                ? 'text-[#706E6B] hover:text-[#2D0A12]'
                : 'text-[#D6C7B2]/70 hover:text-[#F5EBDD]'
            }`}
          >
            <Apple className="w-4 h-4" />
            <span>macOS / Linux</span>
            {activePlatform === 'macos' && (
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse ml-1" />
            )}
          </button>

          <button
            onClick={() => {
              setActivePlatform('windows');
              setCopied(false);
            }}
            className={`flex items-center space-x-2.5 px-5 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition-all ${
              activePlatform === 'windows'
                ? isLight
                  ? 'bg-white text-[#2D0A12] shadow-sm'
                  : 'bg-[#6F1025] text-[#F5EBDD] shadow-[0_2px_12px_rgba(111,16,37,0.4)]'
                : isLight
                ? 'text-[#706E6B] hover:text-[#2D0A12]'
                : 'text-[#D6C7B2]/70 hover:text-[#F5EBDD]'
            }`}
          >
            <Monitor className="w-4 h-4" />
            <span>Windows (PowerShell)</span>
            {activePlatform === 'windows' && (
              <span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse ml-1" />
            )}
          </button>
        </div>
      </div>

      {/* Terminal Window Box */}
      <div
        className={`rounded-2xl border overflow-hidden shadow-2xl transition-all ${
          isLight
            ? 'bg-[#180A0F] border-[#E2D9CD]'
            : 'bg-[#100709] border-[#3D1520] shadow-[0_10px_40px_rgba(111,16,37,0.25)]'
        }`}
      >
        {/* Terminal Title Bar */}
        <div className="flex items-center justify-between px-4 sm:px-6 py-3 border-b border-[#3D1520]/80 bg-[#16080D]">
          <div className="flex items-center space-x-2">
            <span className="w-3 h-3 rounded-full bg-[#FF5F56] border border-[#E0443E]/50 inline-block" />
            <span className="w-3 h-3 rounded-full bg-[#FFBD2E] border border-[#DEA123]/50 inline-block" />
            <span className="w-3 h-3 rounded-full bg-[#27C93F] border border-[#1AAB29]/50 inline-block" />
          </div>

          <div className="flex items-center space-x-2 text-xs font-mono text-[#D6C7B2]/60">
            <Terminal className="w-3.5 h-3.5 text-[#A83249]" />
            <span>
              {activePlatform === 'macos'
                ? 'zsh — 80×24 (macOS Universal)'
                : 'pwsh — 80×24 (Windows x64 / ARM64)'}
            </span>
          </div>

          <div className="text-[11px] font-mono text-[#A89F91]/50 hidden sm:block">
            {activePlatform === 'macos' ? 'bash / zsh' : 'PowerShell 7+'}
          </div>
        </div>

        {/* Terminal Body */}
        <div className="p-4 sm:p-7 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="font-mono text-xs sm:text-base leading-relaxed overflow-x-auto py-1 text-left flex items-center space-x-3">
            <span className="text-[#A83249] select-none font-bold">
              {activePlatform === 'macos' ? '$' : 'PS >'}
            </span>

            {activePlatform === 'macos' ? (
              <span className="text-[#F5EBDD] tracking-wide whitespace-nowrap">
                <span className="text-[#5AC8FA] font-semibold">curl</span>{' '}
                <span className="text-[#D6C7B2]">-fsSL</span>{' '}
                <span className="text-[#FFD60A]">https://sayn.ai/install.sh</span>{' '}
                <span className="text-[#A89F91]">|</span>{' '}
                <span className="text-[#30D158] font-semibold">bash</span>
              </span>
            ) : (
              <span className="text-[#F5EBDD] tracking-wide whitespace-nowrap">
                <span className="text-[#5AC8FA] font-semibold">irm</span>{' '}
                <span className="text-[#FFD60A]">https://sayn.ai/install.ps1</span>{' '}
                <span className="text-[#A89F91]">|</span>{' '}
                <span className="text-[#30D158] font-semibold">iex</span>
              </span>
            )}
          </div>

          {/* 1-Click Copy Action Button */}
          <button
            onClick={handleCopy}
            className={`px-5 py-3 rounded-xl font-bold text-xs sm:text-sm flex items-center justify-center space-x-2 transition-all flex-shrink-0 active:scale-95 ${
              copied
                ? 'bg-emerald-500 text-white shadow-[0_0_20px_rgba(48,209,88,0.4)]'
                : 'bg-[#F5EBDD] hover:bg-white text-[#100709] shadow-[0_4px_16px_rgba(245,235,221,0.2)]'
            }`}
          >
            {copied ? (
              <>
                <Check className="w-4 h-4 stroke-[2.5]" />
                <span>Copied to Clipboard!</span>
              </>
            ) : (
              <>
                <Copy className="w-4 h-4" />
                <span>Copy Command</span>
              </>
            )}
          </button>
        </div>

        {/* Terminal Status / Hotkey Footer */}
        <div className="px-4 sm:px-6 py-3 border-t border-[#3D1520]/80 bg-[#14060B] flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs text-[#D6C7B2]">
          <div className="flex items-center space-x-2">
            <Sparkles className="w-3.5 h-3.5 text-[#A83249]" />
            <span>
              {activePlatform === 'macos'
                ? 'Downloads DMG, installs to /Applications, clears Gatekeeper & launches automatically.'
                : 'Downloads setup, performs silent installation and configures hotkey tray automatically.'}
            </span>
          </div>

          <div className="flex items-center space-x-1.5 text-[11px] font-mono text-[#A89F91]">
            <Command className="w-3 h-3 text-[#A83249]" />
            <span>
              {activePlatform === 'macos' ? 'Hotkey: Fn or Option+Space' : 'Hotkey: Alt+Space'}
            </span>
          </div>
        </div>
      </div>

      {/* Manual Fallback Links */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-4 text-xs">
        <span className={isLight ? 'text-[#706E6B]' : 'text-[#D6C7B2]/70'}>
          Prefer manual setup?
        </span>
        <a
          href="https://github.com/allanmaaz/sayn/releases/latest/download/SAYN-macOS-Installer.dmg"
          download
          className={`inline-flex items-center space-x-1.5 font-bold transition-colors underline-offset-4 hover:underline ${
            isLight ? 'text-[#6F1025]' : 'text-[#F5EBDD] hover:text-[#A83249]'
          }`}
        >
          <Download className="w-3.5 h-3.5" />
          <span>Download DMG for Mac</span>
        </a>
        <span className={isLight ? 'text-[#D4C8B8]' : 'text-[#3D1520]'}>•</span>
        <a
          href="https://github.com/allanmaaz/sayn/releases/latest/download/SAYN-Setup-1.1.0-x64.exe"
          download
          className={`inline-flex items-center space-x-1.5 font-bold transition-colors underline-offset-4 hover:underline ${
            isLight ? 'text-[#6F1025]' : 'text-[#F5EBDD] hover:text-[#A83249]'
          }`}
        >
          <Download className="w-3.5 h-3.5" />
          <span>Download EXE for Windows</span>
        </a>
      </div>
    </div>
  );
};
