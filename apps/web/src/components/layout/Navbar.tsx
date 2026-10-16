import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import {
  Menu,
  X,
  ArrowUp,
  ArrowRight,
  Download,
  Sparkles,
  Info,
  HelpCircle,
  ShieldCheck,
  Zap
} from 'lucide-react';
import { useTheme } from '../../context/ThemeContext.js';
import { DownloadModal } from '../download/DownloadModal.js';
import { useScrollAnimation } from '../../hooks/useScrollAnimation.js';
import saynLogo from '../../assets/logo.png';

export const Navbar: React.FC = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const { scrollProgress, scrollY } = useScrollAnimation();
  const { actualTheme } = useTheme();

  const isLight = actualTheme === 'light';

  const navLinks = [
    { label: 'Download', href: '#download', icon: Download },
    { label: 'About', href: '#about', icon: Info },
    { label: 'How It Works', href: '#how-it-works', icon: HelpCircle },
    { label: 'What SAYN Does', href: '#features', icon: Sparkles },
    { label: 'Privacy', href: '#privacy', icon: ShieldCheck },
  ];


  const handleGetStarted = (e?: React.MouseEvent) => {
    e?.preventDefault();
    setMobileMenuOpen(false);
    const downloadSection = document.getElementById('download');
    if (downloadSection) {
      downloadSection.scrollIntoView({ behavior: 'smooth' });
    } else {
      setIsDownloadOpen(true);
    }
  };

  return (
    <>
      {/* Top Floating Glass Capsule Bar */}
      <header className="fixed top-0 sm:top-5 left-0 right-0 z-50 flex justify-center px-0 sm:px-6 pointer-events-none transition-all duration-300">
        <div
          className={`pointer-events-auto relative w-full sm:max-w-5xl rounded-none sm:rounded-full transition-all duration-300 ${
            scrollY > 20
              ? isLight
                ? 'backdrop-blur-2xl bg-[#FAF7F2]/95 border-b sm:border border-[#E2D9CD] shadow-[0_12px_40px_rgba(45,10,18,0.08)] py-3 sm:py-2.5 px-5 sm:px-6'
                : 'backdrop-blur-2xl bg-[#100709]/95 sm:bg-[#14080D]/90 border-b sm:border border-[#A83249]/40 sm:shadow-[0_12px_40px_rgba(16,7,9,0.85),0_0_25px_rgba(111,16,37,0.3)] py-3 sm:py-2.5 px-5 sm:px-6'
              : isLight
                ? 'bg-transparent sm:backdrop-blur-xl sm:bg-[#FAF7F2]/85 border-b border-transparent sm:border-[#E2D9CD]/80 sm:shadow-[0_8px_32px_rgba(45,10,18,0.05)] py-3.5 sm:py-3 px-5 sm:px-7'
                : 'bg-transparent sm:backdrop-blur-xl sm:bg-[#180B0F]/80 border-b border-transparent sm:border-[#A83249]/35 sm:shadow-[0_8px_32px_rgba(16,7,9,0.7),0_0_16px_rgba(111,16,37,0.18)] py-3.5 sm:py-3 px-5 sm:px-7'
          }`}
        >
          {/* Top Specular Edge Highlight (Desktop Capsule) */}
          <div
            className={`hidden sm:block absolute inset-x-0 top-0 h-[1px] pointer-events-none rounded-t-full ${
              isLight
                ? 'bg-gradient-to-r from-transparent via-[#6F1025]/20 to-transparent'
                : 'bg-gradient-to-r from-transparent via-[#F5EBDD]/25 to-transparent'
            }`}
          />

          {/* Dynamic Hairline Scroll Progress Bar along Capsule Bottom */}
          <div className="absolute bottom-0 inset-x-0 h-[2px] overflow-hidden rounded-b-none sm:rounded-b-full pointer-events-none">
            <div
              className="h-full bg-gradient-to-r from-[#6F1025] via-[#A83249] to-[#F5EBDD] transition-all duration-75 ease-out shadow-[0_0_8px_rgba(168,50,73,0.9)]"
              style={{ width: `${scrollProgress}%` }}
            />
          </div>

          <div className="flex items-center justify-between">
            {/* Brand Logo & Wordmark */}
            <a href="#" className="flex items-center space-x-2.5 group">
              <img
                src={saynLogo}
                alt="SAYN Logo"
                className="w-8 h-8 rounded-lg shadow-sm transition-transform group-hover:scale-105"
              />
              <span
                className={`font-extrabold text-lg tracking-wider ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                SAYN
              </span>
            </a>

            {/* Desktop Navigation Links */}
            <nav className="hidden md:flex items-center space-x-1 sm:space-x-1.5">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  className={`px-3.5 py-1.5 rounded-full text-xs sm:text-sm font-semibold transition-all ${
                    isLight
                      ? 'text-[#5C4D44] hover:text-[#2D0A12] hover:bg-[#6F1025]/10'
                      : 'text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#6F1025]/20'
                  }`}
                >
                  {link.label}
                </a>
              ))}
            </nav>

            {/* Right Action Buttons */}
            <div className="hidden md:flex items-center space-x-3">

              {/* Direct 'Get Started' Action Pill */}
              <button
                onClick={handleGetStarted}
                className={`inline-flex items-center space-x-2 px-5 py-2 rounded-full text-xs sm:text-sm font-bold active:scale-95 transition-all shadow-md group ${
                  isLight
                    ? 'bg-[#6F1025] hover:bg-[#85162E] text-[#F5EBDD] shadow-[0_4px_16px_rgba(111,16,37,0.25)]'
                    : 'bg-[#F5EBDD] hover:bg-[#FAF4EB] text-[#100709] shadow-[0_4px_18px_rgba(245,235,221,0.2)]'
                }`}
              >
                <span>Get Started</span>
                <ArrowRight className="w-3.5 h-3.5 stroke-[2.5] transition-transform group-hover:translate-x-0.5" />
              </button>
            </div>

            {/* Mobile Menu Toggle Button */}
            <div className="flex md:hidden items-center">
              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                aria-label="Toggle menu"
                className={`p-1.5 rounded-lg active:scale-95 transition-all ${
                  isLight ? 'text-[#2D0A12] hover:bg-[#6F1025]/10' : 'text-[#F5EBDD] hover:bg-[#6F1025]/30'
                }`}
              >
                {mobileMenuOpen ? <X className="w-6 h-6 stroke-[2]" /> : <Menu className="w-6 h-6 stroke-[2]" />}
              </button>
            </div>
          </div>

          {/* Mobile Drawer */}
          {mobileMenuOpen && (
            <div
              className={`md:hidden absolute top-full left-0 right-0 sm:left-4 sm:right-4 sm:top-[calc(100%+8px)] sm:rounded-2xl backdrop-blur-2xl p-5 space-y-3 pointer-events-auto animate-in fade-in zoom-in-95 duration-150 border-b sm:border ${
                isLight
                  ? 'bg-[#FAF7F2]/98 border-[#E2D9CD] shadow-[0_16px_50px_rgba(45,10,18,0.12)]'
                  : 'bg-[#14080D]/98 border-[#A83249]/40 shadow-[0_16px_50px_rgba(16,7,9,0.95)]'
              }`}
            >
              <div className="space-y-2 pt-1">
                {navLinks.map((link) => {
                  const Icon = link.icon;
                  return (
                    <a
                      key={link.label}
                      href={link.href}
                      onClick={() => setMobileMenuOpen(false)}
                      className={`flex items-center space-x-3 px-3 py-2.5 rounded-xl text-sm font-semibold transition ${
                        isLight
                          ? 'text-[#5C4D44] hover:text-[#2D0A12] hover:bg-[#6F1025]/10'
                          : 'text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#6F1025]/20'
                      }`}
                    >
                      <Icon className="w-4 h-4 text-[#A83249]" />
                      <span>{link.label}</span>
                    </a>
                  );
                })}

                <div
                  className={`pt-3 border-t ${
                    isLight ? 'border-[#E2D9CD]' : 'border-[#3D1520]/60'
                  }`}
                >
                  <button
                    onClick={handleGetStarted}
                    className={`w-full flex items-center justify-center space-x-2 px-4 py-3 rounded-full text-sm font-bold shadow-md ${
                      isLight
                        ? 'bg-[#6F1025] text-[#F5EBDD]'
                        : 'bg-[#F5EBDD] text-[#100709]'
                    }`}
                  >
                    <span>Get Started</span>
                    <ArrowRight className="w-4 h-4 stroke-[2.5]" />
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Smart Device Detection Download Modal */}
        <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
      </header>

      {/* Floating Scroll-to-Top Button */}
      {scrollY > 400 && (
        <button
          onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
          className={`fixed bottom-6 right-6 z-40 w-11 h-11 rounded-full backdrop-blur-md shadow-lg flex items-center justify-center hover:scale-105 active:scale-95 transition-all animate-in fade-in zoom-in-90 duration-200 ${
            isLight
              ? 'bg-[#FAF7F2]/95 border border-[#E2D9CD] text-[#2D0A12] hover:bg-[#6F1025] hover:text-[#F5EBDD]'
              : 'bg-[#180B0F]/90 border border-[#A83249]/50 text-[#F5EBDD] hover:bg-[#6F1025]'
          }`}
          title="Scroll to Top"
          aria-label="Scroll to Top"
        >
          <ArrowUp className="w-5 h-5" />
        </button>
      )}
    </>
  );
};
