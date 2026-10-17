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
import { TerminalInstall } from './TerminalInstall.js';
import { AndroidDownloadCard } from './AndroidDownloadCard.js';

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
        return <Apple className="w-8 h-8 text-[#F5EBDD]" />;
      case 'windows':
        return <Monitor className="w-8 h-8 text-[#A83249]" />;
      case 'android':
        return <Smartphone className="w-8 h-8 text-[#30D158]" />;
      default:
        return <Laptop className="w-8 h-8 text-[#F5EBDD]" />;
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/85 backdrop-blur-md animate-in fade-in duration-200">
      <div className="relative w-full max-w-2xl bg-[#100709] border border-[#3D1520] rounded-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#3D1520] bg-[#180B0F]/90">
          <div className="flex items-center space-x-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#A83249] animate-pulse" />
            <span className="text-xs font-bold text-[#A83249] uppercase tracking-wider">
              Smart System Detection
            </span>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-full text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#240F16] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto space-y-6">
          {device.os === 'android' ? (
            /* Android-Exclusive View */
            <AndroidDownloadCard />
          ) : (
            /* Laptop / Desktop View */
            <div className="space-y-6">
              <TerminalInstall />

              {/* Collapsible: Desktop Manual Installers */}
              <div>
                <button
                  onClick={() => setShowAllOptions(!showAllOptions)}
                  className="w-full flex items-center justify-between py-2 text-xs font-semibold text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors"
                >
                  <span>Looking for direct installer files? (macOS Universal DMG, Windows 64-bit / 32-bit / Portable)</span>
                  {showAllOptions ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
                </button>

                {showAllOptions && (
                  <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                    {ALL_DOWNLOAD_OPTIONS.filter((opt) => opt.category !== 'Android').map((opt, idx) => (
                      <div
                        key={idx}
                        className="p-4 rounded-xl bg-[#180B0F] border border-[#3D1520] hover:border-[#A83249] transition-colors flex flex-col justify-between"
                      >
                        <div>
                          <div className="flex items-center justify-between">
                            <span className="text-xs font-bold text-[#F5EBDD]">{opt.title}</span>
                            <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-[#240F16] text-[#D6C7B2] border border-[#3D1520]">
                              {opt.format}
                            </span>
                          </div>
                          <p className="text-[11px] text-[#D6C7B2] mt-1">{opt.arch}</p>
                          <p className="text-[10px] text-[#A89F91] font-mono mt-0.5">{opt.fileName}</p>
                        </div>

                        <button
                          onClick={() => handleDownload(opt.url)}
                          className="mt-3 w-full py-2 px-3 rounded-full text-xs font-semibold bg-[#240F16] hover:bg-[#6F1025] hover:text-[#F5EBDD] text-[#D6C7B2] transition-all flex items-center justify-center space-x-1.5 border border-[#3D1520]"
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
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3.5 border-t border-[#3D1520] bg-[#180B0F] flex items-center justify-between text-xs text-[#A89F91]">
          <span>Zero Cost • Free Forever (₹0.00) • Version 1.1.0</span>
          <a
            href="https://github.com/allanmaaz/sayn/releases"
            target="_blank"
            rel="noreferrer"
            className="flex items-center space-x-1 text-[#F5EBDD] hover:text-[#A83249]"
          >
            <span>GitHub Releases</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      </div>
    </div>
  );
};
