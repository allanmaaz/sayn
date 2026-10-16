import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  Mic,
  PenTool,
  History,
  Bookmark,
  Settings,
  Sun,
  Moon,
  LogOut,
  Menu,
  X,
  User as UserIcon,
  ArrowRight,
  ArrowUp,
  Download,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext.js';
import { useTheme } from '../../context/ThemeContext.js';
import { DownloadModal } from '../download/DownloadModal.js';
import { useScrollAnimation } from '../../hooks/useScrollAnimation.js';
import saynLogo from '../../assets/logo.png';

export const Navbar: React.FC = () => {
  const { user, signOut } = useAuth();
  const { actualTheme, setTheme } = useTheme();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);
  const { scrollProgress, scrollY } = useScrollAnimation();

  const toggleTheme = () => {
    setTheme(actualTheme === 'dark' ? 'light' : 'dark');
  };

  interface NavItem {
    label: string;
    path: string;
    icon?: React.ComponentType<{ className?: string }>;
  }

  const navLinks: NavItem[] = user
    ? [
        { label: 'Workspace', path: '/workspace', icon: PenTool },
        { label: 'Voice', path: '/voice', icon: Mic },
        { label: 'History', path: '/history', icon: History },
        { label: 'Prompts', path: '/prompts', icon: Bookmark },
        { label: 'Settings', path: '/settings', icon: Settings },
      ]
    : [
        { label: 'Features', path: '/#features' },
        { label: 'How It Works', path: '/#how-it-works' },
        { label: 'Privacy', path: '/#privacy' },
      ];

  return (
    <>
      {/* Top Floating Glass Capsule Bar */}
      <header className="fixed top-3 sm:top-5 left-0 right-0 z-50 flex justify-center px-3 sm:px-6 pointer-events-none transition-all duration-300">
        <div
          className={`pointer-events-auto relative max-w-5xl w-full rounded-full transition-all duration-300 ${
            scrollY > 20
              ? 'backdrop-blur-2xl bg-[#14080D]/90 border border-[#A83249]/50 shadow-[0_12px_40px_rgba(16,7,9,0.85),0_0_25px_rgba(111,16,37,0.3)] py-2 sm:py-2.5 px-4 sm:px-6'
              : 'backdrop-blur-xl bg-[#180B0F]/80 border border-[#A83249]/35 shadow-[0_8px_32px_rgba(16,7,9,0.7),0_0_16px_rgba(111,16,37,0.18)] py-2.5 sm:py-3 px-5 sm:px-7'
          }`}
        >
          {/* Top Specular Edge Highlight */}
          <div className="absolute inset-x-0 top-0 h-[1px] bg-gradient-to-r from-transparent via-[#F5EBDD]/25 to-transparent pointer-events-none rounded-t-full" />

          {/* Dynamic Hairline Scroll Progress Bar along Capsule Bottom */}
          <div className="absolute bottom-0 inset-x-0 h-[2px] overflow-hidden rounded-b-full pointer-events-none">
            <div
              className="h-full bg-gradient-to-r from-[#6F1025] via-[#A83249] to-[#F5EBDD] transition-all duration-75 ease-out shadow-[0_0_8px_rgba(168,50,73,0.9)]"
              style={{ width: `${scrollProgress}%` }}
            />
          </div>

          <div className="flex items-center justify-between">
            {/* Brand Logo & Wordmark */}
            <Link to="/" className="flex items-center space-x-2.5 group">
              <img
                src={saynLogo}
                alt="SAYN Logo"
                className="w-8 h-8 rounded-lg shadow-sm transition-transform group-hover:scale-105"
              />
              <span className="font-bold text-lg tracking-wider text-[#F5EBDD]">
                SAYN
              </span>
            </Link>

            {/* Desktop Navigation Links */}
            <nav className="hidden md:flex items-center space-x-1 sm:space-x-2">
              {user ? (
                navLinks.map((link) => {
                  const Icon = link.icon;
                  const isActive = location.pathname === link.path;
                  return (
                    <Link
                      key={link.path}
                      to={link.path}
                      className={`flex items-center space-x-1.5 px-3 py-1.5 rounded-full text-xs sm:text-sm font-medium transition-all ${
                        isActive
                          ? 'bg-[#6F1025] text-[#F5EBDD] font-semibold shadow-sm'
                          : 'text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#6F1025]/20'
                      }`}
                    >
                      {Icon && <Icon className="w-3.5 h-3.5" />}
                      <span>{link.label}</span>
                    </Link>
                  );
                })
              ) : (
                <div className="flex items-center space-x-1">
                  {navLinks.map((link) => (
                    <a
                      key={link.label}
                      href={link.path}
                      className="px-3.5 py-1.5 rounded-full text-xs sm:text-sm font-medium text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#6F1025]/20 transition-all"
                    >
                      {link.label}
                    </a>
                  ))}
                </div>
              )}
            </nav>

            {/* Right Action Buttons */}
            <div className="hidden md:flex items-center space-x-3">
              {/* Quick Download App Pill */}
              <button
                onClick={() => setIsDownloadOpen(true)}
                className="flex items-center space-x-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold text-[#F5EBDD] bg-[#6F1025]/35 border border-[#A83249]/50 hover:bg-[#6F1025] active:scale-95 transition-all"
              >
                <Download className="w-3.5 h-3.5 stroke-[2]" />
                <span>Download</span>
              </button>

              {/* Theme Toggle Button */}
              <button
                onClick={toggleTheme}
                aria-label="Toggle theme"
                className="p-1.5 rounded-full text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#240F16] transition-colors"
              >
                {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </button>

              {user ? (
                <div className="flex items-center space-x-2">
                  <Link
                    to="/settings"
                    className="flex items-center space-x-1.5 px-3 py-1.5 rounded-full text-xs sm:text-sm text-[#F5EBDD] bg-[#240F16] border border-[#3D1520] hover:border-[#A83249] transition-colors"
                  >
                    <UserIcon className="w-3.5 h-3.5 text-[#A83249]" />
                    <span className="truncate max-w-[100px]">{user.displayName || user.email}</span>
                  </Link>
                  <button
                    onClick={() => signOut()}
                    aria-label="Sign out"
                    className="p-1.5 rounded-full text-[#D6C7B2] hover:text-[#FF453A] hover:bg-[#240F16] transition-colors"
                    title="Sign out"
                  >
                    <LogOut className="w-4 h-4" />
                  </button>
                </div>
              ) : (
                <div className="flex items-center space-x-2.5">
                  <Link
                    to="/login"
                    className="text-xs sm:text-sm font-medium text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors px-2.5 py-1"
                  >
                    Sign In
                  </Link>
                  {/* Official Warm Cream Pill Button matching mockup */}
                  <Link
                    to="/signup"
                    className="inline-flex items-center space-x-1.5 px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-bold text-[#100709] bg-[#F5EBDD] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_2px_14px_rgba(245,235,221,0.25)]"
                  >
                    <span>Get Started</span>
                    <ArrowRight className="w-3 h-3 stroke-[2.5]" />
                  </Link>
                </div>
              )}
            </div>

            {/* Mobile Hamburger Button */}
            <div className="flex md:hidden items-center space-x-1">
              <button
                onClick={toggleTheme}
                aria-label="Toggle theme"
                className="p-1.5 rounded-full text-[#D6C7B2]"
              >
                {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </button>
              <button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                aria-label="Toggle menu"
                className="p-1.5 rounded-full text-[#F5EBDD]"
              >
                {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
              </button>
            </div>
          </div>

          {/* Mobile Drawer (Floating Glass Card Under Capsule) */}
          {mobileMenuOpen && (
            <div className="md:hidden absolute top-[calc(100%+8px)] left-0 right-0 rounded-2xl backdrop-blur-2xl bg-[#14080D]/95 border border-[#A83249]/40 shadow-[0_16px_50px_rgba(16,7,9,0.9)] p-4 space-y-2 pointer-events-auto animate-in fade-in zoom-in-95 duration-150">
              {user ? (
                <>
                  {navLinks.map((link) => {
                    const Icon = link.icon;
                    const isActive = location.pathname === link.path;
                    return (
                      <Link
                        key={link.path}
                        to={link.path}
                        onClick={() => setMobileMenuOpen(false)}
                        className={`flex items-center space-x-3 px-3 py-2 rounded-xl text-sm font-medium ${
                          isActive
                            ? 'bg-[#6F1025] text-[#F5EBDD]'
                            : 'text-[#D6C7B2] hover:text-[#F5EBDD]'
                        }`}
                      >
                        {Icon && <Icon className="w-4 h-4" />}
                        <span>{link.label}</span>
                      </Link>
                    );
                  })}
                  <div className="pt-2 border-t border-[#3D1520]">
                    <button
                      onClick={() => {
                        signOut();
                        setMobileMenuOpen(false);
                      }}
                      className="flex items-center space-x-3 w-full px-3 py-2 text-sm text-[#FF453A]"
                    >
                      <LogOut className="w-4 h-4" />
                      <span>Sign Out</span>
                    </button>
                  </div>
                </>
              ) : (
                <div className="space-y-2 pt-1">
                  {navLinks.map((link) => (
                    <a
                      key={link.label}
                      href={link.path}
                      onClick={() => setMobileMenuOpen(false)}
                      className="block px-3 py-2 rounded-xl text-sm text-[#D6C7B2] hover:text-[#F5EBDD] font-medium"
                    >
                      {link.label}
                    </a>
                  ))}
                  <div className="pt-2 border-t border-[#3D1520]/60 space-y-2">
                    <Link
                      to="/login"
                      onClick={() => setMobileMenuOpen(false)}
                      className="block px-3 py-2 rounded-xl text-sm text-[#F5EBDD] font-medium"
                    >
                      Sign In
                    </Link>
                    <Link
                      to="/signup"
                      onClick={() => setMobileMenuOpen(false)}
                      className="block text-center px-4 py-2.5 rounded-full text-sm font-bold text-[#100709] bg-[#F5EBDD]"
                    >
                      Get Started Free →
                    </Link>
                    <button
                      onClick={() => {
                        setIsDownloadOpen(true);
                        setMobileMenuOpen(false);
                      }}
                      className="w-full flex items-center justify-center space-x-2 px-4 py-2.5 rounded-full text-sm font-semibold text-[#F5EBDD] bg-[#6F1025]"
                    >
                      <Download className="w-4 h-4" />
                      <span>Download App</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Smart Device Detection Download Modal */}
        <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
      </header>

    {/* Floating Scroll-to-Top Button with Smooth Blur & Glow */}
    {scrollY > 400 && (
      <button
        onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
        className="fixed bottom-6 right-6 z-40 w-11 h-11 rounded-full bg-[#180B0F]/90 border border-[#A83249]/50 text-[#F5EBDD] backdrop-blur-md shadow-[0_8px_24px_rgba(111,16,37,0.4)] flex items-center justify-center hover:bg-[#6F1025] hover:scale-105 active:scale-95 transition-all animate-in fade-in zoom-in-90 duration-200"
        title="Scroll to Top"
        aria-label="Scroll to Top"
      >
        <ArrowUp className="w-5 h-5" />
      </button>
    )}
  </>
  );
};
