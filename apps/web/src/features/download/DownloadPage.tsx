import React, { useState, useEffect } from 'react';
import {
  Download,
  Apple,
  Monitor,
  Smartphone,
  CheckCircle,
  ExternalLink,
  Laptop,
  ArrowRight,
  ShieldCheck,
  Zap,
} from 'lucide-react';
import { Link } from 'react-router-dom';
import { detectDevice, DeviceInfo, ALL_DOWNLOAD_OPTIONS } from '../../utils/deviceDetector.js';

export const DownloadPage: React.FC = () => {
  const [device, setDevice] = useState<DeviceInfo | null>(null);
  const [downloadStarted, setDownloadStarted] = useState(false);
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);

  useEffect(() => {
    setDevice(detectDevice());

    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  const handleDownload = (url: string) => {
    if (url === '#pwa-install') {
      if (deferredPrompt) {
        deferredPrompt.prompt();
      } else {
        alert('To install SAYN, open your browser menu (⋮ or Share) and select "Add to Home Screen" or "Install App".');
      }
      return;
    }

    setDownloadStarted(true);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', '');
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    setTimeout(() => setDownloadStarted(false), 5000);
  };

  const getOsIcon = (os: string) => {
    switch (os) {
      case 'macos':
        return <Apple className="w-10 h-10 text-white" />;
      case 'windows':
        return <Monitor className="w-10 h-10 text-[#00A4EF]" />;
      case 'android':
        return <Smartphone className="w-10 h-10 text-[#3DDC84]" />;
      default:
        return <Laptop className="w-10 h-10 text-[#CBFE00]" />;
    }
  };

  return (
    <div className="flex-1 flex flex-col py-12 md:py-20 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-12">
        <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full bg-[#CBFE00]/10 border border-[#CBFE00]/30 mb-4">
          <span className="w-2 h-2 rounded-full bg-[#CBFE00] animate-pulse" />
          <span className="text-xs font-bold text-[#CBFE00] uppercase tracking-wider">
            Smart Device Detection
          </span>
        </div>
        <h1 className="text-3xl sm:text-5xl font-extrabold text-white tracking-tight">
          Download <span className="text-[#CBFE00]">SAYN</span>
        </h1>
        <p className="mt-3 text-sm sm:text-base text-zinc-400">
          AI Voice Dictation, QuillBot Paraphrasing, and Grammarly 4-Pillar Proofreading.
        </p>
      </div>

      {/* Main Detected OS Card */}
      {device && (
        <div className="relative p-6 sm:p-8 rounded-2xl bg-[#16161D] border-2 border-[#CBFE00]/50 shadow-[0_0_50px_rgba(203,254,0,0.12)] mb-14">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
            <div className="flex items-start space-x-5">
              <div className="p-4 rounded-2xl bg-black/50 border border-white/10 flex-shrink-0">
                {getOsIcon(device.os)}
              </div>
              <div>
                <div className="flex items-center space-x-3">
                  <h2 className="text-xl sm:text-2xl font-bold text-white">
                    SAYN for {device.osName}
                  </h2>
                  <span className="px-2.5 py-0.5 text-xs font-bold rounded-full bg-[#CBFE00]/20 text-[#CBFE00] border border-[#CBFE00]/30">
                    {device.badgeLabel}
                  </span>
                </div>
                <p className="text-sm text-zinc-300 mt-1.5">
                  Detected Architecture: <strong className="text-white">{device.archName}</strong>
                </p>
                <p className="text-xs text-zinc-400 mt-1 font-mono">
                  {device.recommendedFileName} • Zero Cost (₹0.00) • Free Forever
                </p>
              </div>
            </div>

            {/* Primary Action Button */}
            <button
              onClick={() => handleDownload(device.recommendedDownloadUrl)}
              className="w-full md:w-auto px-8 py-4 rounded-xl font-extrabold text-sm bg-[#CBFE00] text-[#0D0D12] hover:bg-[#D9FF33] active:scale-95 transition-all shadow-[0_0_25px_rgba(203,254,0,0.4)] flex items-center justify-center space-x-2.5 flex-shrink-0"
            >
              <Download className="w-5 h-5 stroke-[2.5]" />
              <span>Download for {device.osName}</span>
            </button>
          </div>

          {downloadStarted && (
            <div className="mt-5 p-3.5 rounded-xl bg-[#CBFE00]/10 border border-[#CBFE00]/30 flex items-center space-x-2 text-xs font-semibold text-[#CBFE00] animate-in fade-in">
              <CheckCircle className="w-4 h-4 flex-shrink-0" />
              <span>Download initiated! Open the file once finished to install.</span>
            </div>
          )}

          <div className="mt-6 pt-5 border-t border-white/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs text-zinc-400">
            <div className="flex items-center space-x-2">
              <Zap className="w-4 h-4 text-[#CBFE00] flex-shrink-0" />
              <span>{device.instructions}</span>
            </div>
            <div className="flex items-center space-x-4">
              <span className="flex items-center space-x-1 text-zinc-400">
                <ShieldCheck className="w-4 h-4 text-[#CBFE00]" />
                <span>Code-Signed & Verified</span>
              </span>
            </div>
          </div>
        </div>
      )}

      {/* Grid: All Other Platforms & Architectures */}
      <div>
        <div className="flex items-center justify-between mb-6">
          <h3 className="text-lg font-bold text-white">All Platforms & Architectures</h3>
          <span className="text-xs text-zinc-400">Universal support for every device</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {ALL_DOWNLOAD_OPTIONS.map((opt, idx) => (
            <div
              key={idx}
              className="p-5 rounded-xl bg-[#16161D] border border-white/10 hover:border-[#CBFE00]/40 transition-all flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-mono px-2 py-0.5 rounded bg-white/5 text-[#CBFE00] border border-white/5">
                    {opt.category}
                  </span>
                  <span className="text-xs font-mono text-zinc-400">{opt.format}</span>
                </div>
                <h4 className="text-sm font-bold text-white">{opt.title}</h4>
                <p className="text-xs text-zinc-400 mt-1">{opt.arch}</p>
                <p className="text-[11px] text-zinc-500 font-mono mt-1">{opt.fileName}</p>
              </div>

              <button
                onClick={() => handleDownload(opt.url)}
                className="mt-4 w-full py-2.5 px-3 rounded-lg text-xs font-bold bg-white/5 hover:bg-[#CBFE00] hover:text-[#0D0D12] text-zinc-200 transition-all flex items-center justify-center space-x-2 border border-white/10"
              >
                <Download className="w-3.5 h-3.5" />
                <span>Download ({opt.tag})</span>
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Web PWA Card */}
      <div className="mt-12 p-6 rounded-2xl bg-gradient-to-r from-[#16161D] to-[#0D0D12] border border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h4 className="text-base font-bold text-white">Prefer to use SAYN in your browser?</h4>
          <p className="text-xs text-zinc-400 mt-1">
            Access the full 0ms QuillBot paraphraser and Grammarly proofreading workstation online.
          </p>
        </div>
        <Link
          to="/workspace"
          className="px-5 py-2.5 rounded-xl text-xs font-bold bg-[#CBFE00] text-[#0D0D12] hover:bg-[#D9FF33] transition-all flex items-center space-x-1.5 flex-shrink-0"
        >
          <span>Launch Web Studio</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>
    </div>
  );
};
