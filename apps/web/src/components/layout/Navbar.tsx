import React, { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
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
  ChevronRight,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext.js';
import { useTheme } from '../../context/ThemeContext.js';

export const Navbar: React.FC = () => {
  const { user, signOut } = useAuth();
  const { actualTheme, setTheme } = useTheme();
  const location = useLocation();
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

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
    <header className="sticky top-0 z-40 backdrop-blur-md bg-sayn-dark-bg/85 dark:bg-sayn-dark-bg/85 light:bg-sayn-light-bg/85 border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider transition-colors duration-150">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand Logo & Wordmark */}
        <Link to="/" className="flex items-center space-x-3 group">
          <img src="/logo.svg" alt="SAYN Logo" className="w-8 h-8 rounded-lg shadow-sm" />
          <div className="flex flex-col">
            <span className="font-semibold text-lg tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text">
              SAYN
            </span>
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center space-x-1">
          {user ? (
            navLinks.map((link) => {
              const Icon = link.icon;
              const isActive = location.pathname === link.path;
              return (
                <Link
                  key={link.path}
                  to={link.path}
                  className={`flex items-center space-x-2 px-3 py-1.5 rounded-ios-sm text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent font-semibold'
                      : 'text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text'
                  }`}
                >
                  {Icon && <Icon className="w-4 h-4" />}
                  <span>{link.label}</span>
                </Link>
              );
            })
          ) : (
            <div className="flex items-center space-x-6">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.path}
                  className="text-sm font-medium text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors"
                >
                  {link.label}
                </a>
              ))}
            </div>
          )}
        </nav>

        {/* Right Action Icons */}
        <div className="hidden md:flex items-center space-x-3">
          {/* Theme Toggle Button */}
          <button
            onClick={toggleTheme}
            aria-label="Toggle theme"
            className="p-2 rounded-ios-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text hover:bg-sayn-dark-surface2 dark:hover:bg-sayn-dark-surface2 light:hover:bg-sayn-light-surface2 transition-colors"
          >
            {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>

          {user ? (
            <div className="flex items-center space-x-2">
              <Link
                to="/settings"
                className="flex items-center space-x-2 px-3 py-1.5 rounded-ios-sm text-sm text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider hover:border-sayn-dark-muted transition-colors"
              >
                <UserIcon className="w-3.5 h-3.5 text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent" />
                <span className="truncate max-w-[120px]">{user.displayName || user.email}</span>
              </Link>
              <button
                onClick={() => signOut()}
                aria-label="Sign out"
                className="p-2 rounded-ios-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-error dark:hover:text-sayn-dark-error light:hover:text-sayn-light-error transition-colors"
                title="Sign out"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          ) : (
            <div className="flex items-center space-x-3">
              <Link
                to="/login"
                className="text-sm font-medium text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors px-3 py-1.5"
              >
                Sign In
              </Link>
              <Link
                to="/signup"
                className="inline-flex items-center space-x-1 px-4 py-2 rounded-ios-sm text-sm font-medium text-white bg-sayn-dark-accent dark:bg-sayn-dark-accent light:bg-sayn-light-accent hover:opacity-90 active:scale-95 transition-all shadow-sm"
              >
                <span>Get Started Free</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </Link>
            </div>
          )}
        </div>

        {/* Mobile Hamburger Button */}
        <div className="flex md:hidden items-center space-x-2">
          <button
            onClick={toggleTheme}
            aria-label="Toggle theme"
            className="p-2 rounded-ios-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary"
          >
            {actualTheme === 'dark' ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
          </button>
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            aria-label="Toggle menu"
            className="p-2 rounded-ios-sm text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="md:hidden border-b border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface px-4 pt-2 pb-4 space-y-1">
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
                    className={`flex items-center space-x-3 px-3 py-2.5 rounded-ios-sm text-sm font-medium ${
                      isActive
                        ? 'bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 text-sayn-dark-accent'
                        : 'text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary'
                    }`}
                  >
                    {Icon && <Icon className="w-4 h-4" />}
                    <span>{link.label}</span>
                  </Link>
                );
              })}
              <div className="pt-2 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
                <button
                  onClick={() => {
                    signOut();
                    setMobileMenuOpen(false);
                  }}
                  className="flex items-center space-x-3 w-full px-3 py-2 text-sm text-sayn-dark-error dark:text-sayn-dark-error light:text-sayn-light-error"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Sign Out</span>
                </button>
              </div>
            </>
          ) : (
            <div className="space-y-2 pt-2">
              <Link
                to="/login"
                onClick={() => setMobileMenuOpen(false)}
                className="block px-3 py-2 rounded-ios-sm text-sm text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text font-medium"
              >
                Sign In
              </Link>
              <Link
                to="/signup"
                onClick={() => setMobileMenuOpen(false)}
                className="block text-center px-4 py-2.5 rounded-ios-sm text-sm font-medium text-white bg-sayn-dark-accent"
              >
                Get Started Free
              </Link>
            </div>
          )}
        </div>
      )}
    </header>
  );
};
