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
  Download,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext.js';
import { useTheme } from '../../context/ThemeContext.js';
import { DownloadModal } from '../download/DownloadModal.js';
import saynLogo from '../../assets/logo.png';

export const Navbar: React.FC = () => {
  const { user, signOut } = useAuth();
  const { actualTheme, setTheme } = useTheme();
  const location = useLocation();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isDownloadOpen, setIsDownloadOpen] = useState(false);

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
    <header className="sticky top-0 z-40 backdrop-blur-xl bg-[#100709]/90 border-b border-[#3D1520]/60 transition-colors duration-150">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-18 flex items-center justify-between">
        {/* Brand Logo & Wordmark */}
        <Link to="/" className="flex items-center space-x-3 group">
          <img src={saynLogo} alt="SAYN Logo" className="w-9 h-9 rounded-xl shadow-md transition-transform group-hover:scale-105" />
          <div className="flex flex-col">
            <span className="font-bold text-xl tracking-wider text-[#F5EBDD]">
              SAYN
            </span>
          </div>
        </Link>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center space-x-8">
          {user ? (
            navLinks.map((link) => {
              const Icon = link.icon;
              const isActive = location.pathname === link.path;
              return (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`flex items-center space-x-2 px-3 py-1.5 rounded-full text-sm font-medium transition-all ${
                    isActive
                      ? 'bg-[#6F1025] text-[#F5EBDD] font-semibold shadow-sm'
                      : 'text-[#D6C7B2] hover:text-[#F5EBDD]'
                  }`}
                >
                  {Icon && <Icon className="w-4 h-4" />}
                  <span>{link.label}</span>
                </Link>
              );
            })
          ) : (
            <div className="flex items-center space-x-8">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.path}
                  className="text-sm font-medium text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors"
                >
                  {link.label}
                </a>
              ))}
            </div>
          )}
        </nav>

        {/* Right Action Buttons */}
        <div className="hidden md:flex items-center space-x-4">
          {/* Quick Download App Pill */}
          <button
            onClick={() => setIsDownloadOpen(true)}
            className="flex items-center space-x-1.5 px-3.5 py-1.5 rounded-full text-xs font-semibold text-[#F5EBDD] bg-[#6F1025]/40 border border-[#A83249]/50 hover:bg-[#6F1025] active:scale-95 transition-all"
          >
            <Download className="w-3.5 h-3.5 stroke-[2]" />
            <span>Download</span>
          </button>

          {/* Theme Toggle Button */}
          <button
            onClick={toggleTheme}
            aria-label="Toggle theme"
            className="p-2 rounded-full text-[#D6C7B2] hover:text-[#F5EBDD] hover:bg-[#240F16] transition-colors"
          >
            {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>

          {user ? (
            <div className="flex items-center space-x-2">
              <Link
                to="/settings"
                className="flex items-center space-x-2 px-3 py-1.5 rounded-full text-sm text-[#F5EBDD] bg-[#240F16] border border-[#3D1520] hover:border-[#A83249] transition-colors"
              >
                <UserIcon className="w-3.5 h-3.5 text-[#A83249]" />
                <span className="truncate max-w-[120px]">{user.displayName || user.email}</span>
              </Link>
              <button
                onClick={() => signOut()}
                aria-label="Sign out"
                className="p-2 rounded-full text-[#D6C7B2] hover:text-[#FF453A] hover:bg-[#240F16] transition-colors"
                title="Sign out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div className="flex items-center space-x-4">
              <Link
                to="/login"
                className="text-sm font-medium text-[#D6C7B2] hover:text-[#F5EBDD] transition-colors px-2 py-1.5"
              >
                Sign In
              </Link>
              {/* Official Warm Cream Pill Button matching mockup */}
              <Link
                to="/signup"
                className="inline-flex items-center space-x-2 px-5 py-2.5 rounded-full text-sm font-bold text-[#100709] bg-[#F5EBDD] hover:bg-[#FAF4EB] active:scale-95 transition-all shadow-[0_4px_16px_rgba(245,235,221,0.2)]"
              >
                <span>Get Started Free</span>
                <ArrowRight className="w-3.5 h-3.5 stroke-[2.5]" />
              </Link>
            </div>
          )}
        </div>

        {/* Mobile Hamburger Button */}
        <div className="flex md:hidden items-center space-x-2">
          <button
            onClick={toggleTheme}
            aria-label="Toggle theme"
            className="p-2 rounded-full text-[#D6C7B2]"
          >
            {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
            className="p-2 rounded-full text-[#F5EBDD]"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-[#3D1520] bg-[#180B0F] px-4 pt-3 pb-5 space-y-2">
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
                    className={`flex items-center space-x-3 px-3 py-2.5 rounded-xl text-sm font-medium ${
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
            <div className="space-y-3 pt-2">
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
                className="block text-center px-4 py-3 rounded-full text-sm font-bold text-[#100709] bg-[#F5EBDD]"
              >
                Get Started Free →
              </Link>
              <button
                onClick={() => {
                  setIsDownloadOpen(true);
                  setMobileMenuOpen(false);
                }}
                className="w-full flex items-center justify-center space-x-2 px-4 py-3 rounded-full text-sm font-semibold text-[#F5EBDD] bg-[#6F1025]"
              >
                <Download className="w-4 h-4" />
                <span>Download App</span>
              </button>
            </div>
          )}
        </div>
      )}

      {/* Smart Device Detection Download Modal */}
      <DownloadModal isOpen={isDownloadOpen} onClose={() => setIsDownloadOpen(false)} />
    </header>
  );
};
