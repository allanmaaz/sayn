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
          {/* Main Detected Device Card */}
          <div className="relative p-6 rounded-2xl bg-[#1C0B12] border-2 border-[#A83249]/50 shadow-[0_0_35px_rgba(111,16,37,0.3)]">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-start space-x-4">
                <div className="p-3.5 rounded-xl bg-[#100709] border border-[#3D1520]">
                  {getOsIcon(device.os)}
                </div>
                <div>
                  <div className="flex items-center space-x-2">
                    <h3 className="text-lg font-bold text-[#F5EBDD]">
                      SAYN for {device.osName}
                    </h3>
                    <span className="px-2.5 py-0.5 text-[10px] font-bold rounded-full bg-[#6F1025] text-[#F5EBDD] border border-[#A83249]">
                      {device.badgeLabel}
                    </span>
                  </div>
                  <p className="text-xs text-[#D6C7B2] mt-1">
                    Detected Architecture: <span className="text-[#F5EBDD] font-bold">{device.archName}</span>
                  </p>
                  <p className="text-xs text-[#A89F91] mt-0.5">
                    File: <span className="font-mono text-[#D6C7B2]">{device.recommendedFileName}</span> • Free & Unlimited
                  </p>
                </div>
              </div>

              {/* Primary Download Button in Warm Cream */}
              <button
                onClick={() => handleDownload(device.recommendedDownloadUrl)}
                className="w-full sm:w-auto px-7 py-3.5 rounded-full font-bold text-sm bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_20px_rgba(245,235,221,0.2)] flex items-center justify-center space-x-2 flex-shrink-0"
              >
                <Download className="w-4 h-4 stroke-[2.5]" />
                <span>Download Now</span>
              </button>
            </div>

            {/* Download Status Alert */}
            {downloadStarted && (
              <div className="mt-4 p-3 rounded-xl bg-[#6F1025]/30 border border-[#A83249] flex items-center space-x-2 text-xs text-[#F5EBDD] animate-in fade-in">
                <CheckCircle className="w-4 h-4 text-[#30D158] flex-shrink-0" />
                <span>Download started! Check your browser's download tray.</span>
              </div>
            )}

            {/* Installation Instructions */}
            <div className="mt-4 pt-4 border-t border-[#3D1520] text-xs text-[#D6C7B2] flex items-start space-x-2">
              <Sparkles className="w-4 h-4 text-[#A83249] flex-shrink-0 mt-0.5" />
              <span>{device.instructions}</span>
            </div>
          </div>

          {/* Collapsible: All Platforms & Architectures */}
          <div>
            <button
              onClick={() => setShowAllOptions(!showAllOptions)}
              className="w-full flex items-center justify-between py-2 text-xs font-semibold text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors"
            >
              <span>Looking for other platforms or architectures? (Mac Intel/Silicon, Windows 32/64-bit, Android)</span>
              {showAllOptions ? <ChevronUp className="w-4 h-4" /> : <ChevronDown className="w-4 h-4" />}
            </button>

            {showAllOptions && (
              <div className="mt-3 grid grid-cols-1 sm:grid-cols-2 gap-3 pt-2">
                {ALL_DOWNLOAD_OPTIONS.map((opt, idx) => (
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
