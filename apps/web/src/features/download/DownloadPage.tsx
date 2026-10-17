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
import { TerminalInstall } from '../../components/download/TerminalInstall.js';
import { AndroidDownloadCard } from '../../components/download/AndroidDownloadCard.js';

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
        return <Apple className="w-10 h-10 text-[#F5EBDD]" />;
      case 'windows':
        return <Monitor className="w-10 h-10 text-[#A83249]" />;
      case 'android':
        return <Smartphone className="w-10 h-10 text-[#30D158]" />;
      default:
        return <Laptop className="w-10 h-10 text-[#F5EBDD]" />;
    }
  };

  return (
    <div className="flex-1 flex flex-col py-12 md:py-20 px-4 sm:px-6 lg:px-8 max-w-5xl mx-auto w-full bg-[#100709] text-[#F5EBDD]">
      {/* Header */}
      <div className="text-center max-w-2xl mx-auto mb-14">
        <div className="inline-flex items-center space-x-2 px-4 py-1.5 rounded-full bg-[#180B0F] border border-[#A83249]/50 mb-5 shadow-[0_0_20px_rgba(111,16,37,0.3)]">
          <span className="w-2.5 h-2.5 rounded-full bg-[#A83249] animate-pulse" />
          <span className="text-xs font-bold text-[#F5EBDD] uppercase tracking-wider">
            Smart Device Detection
          </span>
        </div>
        <h1 className="text-4xl sm:text-6xl font-extrabold text-[#F5EBDD] tracking-tight">
          Download <span className="text-[#A83249]">SAYN</span>
        </h1>
        <p className="mt-3 text-sm sm:text-base text-[#D6C7B2]">
          AI Voice Dictation, QuillBot Paraphrasing, and Grammarly 4-Pillar Proofreading.
        </p>
      </div>

      {/* Device Bifurcated Content */}
      {device?.os === 'android' ? (
        /* Android-Exclusive View */
        <div className="space-y-10">
          <AndroidDownloadCard />
        </div>
      ) : (
        /* Laptop & Desktop View */
        <div className="space-y-14">
          {/* Terminal Quick-Install */}
          <TerminalInstall />

          {/* Grid: Desktop Manual Installer Assets (macOS & Windows ONLY - Android Excluded) */}
          <div>
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-[#F5EBDD]">Desktop Manual Installers</h3>
              <span className="text-xs text-[#D6C7B2]">Direct DMG and EXE packages</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {ALL_DOWNLOAD_OPTIONS.filter((opt) => opt.category !== 'Android').map((opt, idx) => (
                <div
                  key={idx}
                  className="p-5 rounded-2xl bg-[#1C0B12] border border-[#3D1520] hover:border-[#A83249] transition-all flex flex-col justify-between"
                >
                  <div>
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-xs font-mono px-2 py-0.5 rounded bg-[#240F16] text-[#A83249] border border-[#3D1520]">
                        {opt.category}
                      </span>
                      <span className="text-xs font-mono text-[#D6C7B2]">{opt.format}</span>
                    </div>
                    <h4 className="text-sm font-bold text-[#F5EBDD]">{opt.title}</h4>
                    <p className="text-xs text-[#D6C7B2] mt-1">{opt.arch}</p>
                    <p className="text-[11px] text-[#A89F91] font-mono mt-1">{opt.fileName}</p>
                  </div>

                  <button
                    onClick={() => handleDownload(opt.url)}
                    className="mt-4 w-full py-2.5 px-3 rounded-full text-xs font-bold bg-[#240F16] hover:bg-[#6F1025] hover:text-[#F5EBDD] text-[#D6C7B2] transition-all flex items-center justify-center space-x-2 border border-[#3D1520]"
                  >
                    <Download className="w-3.5 h-3.5" />
                    <span>Download ({opt.tag})</span>
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* Web PWA Card */}
      <div className="mt-14 p-7 rounded-2xl bg-gradient-to-r from-[#1C0B12] to-[#14080D] border border-[#3D1520] flex flex-col sm:flex-row items-center justify-between gap-4">
        <div>
          <h4 className="text-base font-bold text-[#F5EBDD]">Prefer to use SAYN in your browser?</h4>
          <p className="text-xs text-[#D6C7B2] mt-1">
            Access the full 0ms QuillBot paraphraser and Grammarly proofreading workstation online.
          </p>
        </div>
        <Link
          to="/workspace"
          className="px-6 py-3 rounded-full text-xs font-bold bg-[#F5EBDD] text-[#100709] hover:bg-[#FAF4EB] transition-all flex items-center space-x-1.5 flex-shrink-0 shadow-sm"
        >
          <span>Launch Web Studio</span>
          <ArrowRight className="w-3.5 h-3.5" />
        </Link>
      </div>
    </div>
  );
};
