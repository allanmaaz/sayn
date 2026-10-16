import React, { useState, useEffect } from 'react';
import {
  X,
  Download,
  Apple,
  Monitor,
  Smartphone,
  CheckCircle,
  ChevronDown,
  ChevronUp,
  Sparkles,
  ExternalLink,
  Laptop,
} from 'lucide-react';
import { detectDevice, DeviceInfo, ALL_DOWNLOAD_OPTIONS } from '../../utils/deviceDetector.js';

interface DownloadModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const DownloadModal: React.FC<DownloadModalProps> = ({ isOpen, onClose }) => {
  const [device, setDevice] = useState<DeviceInfo | null>(null);
  const [showAllOptions, setShowAllOptions] = useState(false);
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

  if (!isOpen || !device) return null;

  const handleDownload = (url: string) => {
    if (url === '#pwa-install') {
      if (deferredPrompt) {
        deferredPrompt.prompt();
      } else {
        alert('To install SAYN on your device, open your browser menu (⋮ or Share) and select "Add to Home Screen" or "Install App".');
      }
      return;
    }

    setDownloadStarted(true);
    // Trigger download
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
        return <Apple className="w-8 h-8 text-white" />;
      case 'windows':
        return <Monitor className="w-8 h-8 text-[#00A4EF]" />;
      case 'android':
        return <Smartphone className="w-8 h-8 text-[#3DDC84]" />;
      default:
        return <Laptop className="w-8 h-8 text-[#CBFE00]" />;
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/80 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-2xl bg-[#0D0D12] border border-[#282832] rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#282832] bg-[#16161D]/50">
          <div className="flex items-center space-x-2">
            <span className="w-2 h-2 rounded-full bg-[#CBFE00] animate-pulse" />
            <span className="text-xs font-semibold text-[#CBFE00] uppercase tracking-wider">
              Smart System Detection
            </span>
          </div>
          <button
            onClick={onClose}
            className="p-1 rounded-lg text-zinc-400 hover:text-white hover:bg-white/10 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto space-y-6">
          {/* Main Detected Device Card */}
          <div className="relative p-6 rounded-xl bg-[#16161D] border-2 border-[#CBFE00]/40 shadow-[0_0_30px_rgba(203,254,0,0.08)]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-start space-x-4">
                <div className="p-3 rounded-xl bg-black/40 border border-white/10">
                  {getOsIcon(device.os)}
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <h3 className="text-lg font-bold text-white">
                      SAYN for {device.osName}
                    </h3>
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded-full bg-[#CBFE00]/20 text-[#CBFE00] border border-[#CBFE00]/30">
                      {device.badgeLabel}
                    </span>
                  </div>
                  <p className="text-xs text-zinc-400 mt-1">
                    Detected Architecture: <span className="text-zinc-200 font-semibold">{device.archName}</span>
                  </p>
                  <p className="text-xs text-zinc-500 mt-0.5">
                    File: <span className="font-mono text-zinc-400">{device.recommendedFileName}</span> • Free & Unlimited
                  </p>
                </div>
              </div>

              {/* Primary Download Button */}
              <button
                onClick={() => handleDownload(device.recommendedDownloadUrl)}
                className="w-full sm:w-auto px-6 py-3.5 rounded-xl font-bold text-sm bg-[#CBFE00] text-[#0D0D12] hover:bg-[#D9FF33] active:scale-95 transition-all shadow-[0_0_20px_rgba(203,254,0,0.3)] flex items-center justify-center space-x-2 flex-shrink-0"
              >
                <Download className="w-4 h-4 stroke-[2.5]" />
                <span>Download Now</span>
              </button>
            </div>

            {/* Download Status Alert */}
            {downloadStarted && (
              <div className="mt-4 p-3 rounded-lg bg-[#CBFE00]/10 border border-[#CBFE00]/30 flex items-center space-x-2 text-xs text-[#CBFE00] animate-in fade-in">
                <CheckCircle className="w-4 h-4 flex-shrink-0" />
                <span>Download started! Check your browser's download tray.</span>
              </div>
            )}

            {/* Installation Instructions */}
            <div className="mt-4 pt-4 border-t border-white/5 text-xs text-zinc-400 flex items-start space-x-2">
              <Sparkles className="w-4 h-4 text-[#CBFE00] flex-shrink-0 mt-0.5" />
              <span>{device.instructions}</span>
            </div>
          </div>

          {/* Collapsible: All Platforms & Architectures */}
          <div>
            <button
              onClick={() => setShowAllOptions(!showAllOptions)}
              className="w-full flex items-center justify-between py-2 text-xs font-semibold text-zinc-400 hover:text-white transition-colors"
            >
              <span>Looking for other platforms or architectures? (Mac Intel/Silicon, Windows 32/64-bit, Android)</span>
              {showAllOptions ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </button>

            {showAllOptions && (
              <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                {ALL_DOWNLOAD_OPTIONS.map((opt, idx) => (
                  <div
                    key={idx}
                    className="p-3.5 rounded-xl bg-[#16161D] border border-white/10 hover:border-[#CBFE00]/40 transition-colors flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-center justify-between">
                        <span className="text-xs font-bold text-white">{opt.title}</span>
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-white/5 text-zinc-400">
                          {opt.format}
                        </span>
                      </div>
                      <p className="text-[11px] text-zinc-400 mt-1">{opt.arch}</p>
                      <p className="text-[10px] text-zinc-500 font-mono mt-0.5">{opt.fileName}</p>
                    </div>

                    <button
                      onClick={() => handleDownload(opt.url)}
                      className="mt-3 w-full py-1.5 px-3 rounded-lg text-xs font-semibold bg-white/5 hover:bg-[#CBFE00] hover:text-[#0D0D12] text-zinc-200 transition-all flex items-center justify-center space-x-1.5 border border-white/10"
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>Download {opt.tag}</span>
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-[#282832] bg-[#16161D]/50 flex items-center justify-between text-xs text-zinc-500">
          <span>Zero Cost • Free Forever (₹0.00) • Version 1.1.0</span>
          <a
            href="https://github.com/allanmaaz/sayn/releases"
            target="_blank"
            rel="noreferrer"
            className="flex items-center space-x-1 text-[#CBFE00] hover:underline"
          >
            <span>GitHub Releases</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      </div>
    </div>
  );
};
