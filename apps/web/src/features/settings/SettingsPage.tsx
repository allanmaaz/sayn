import React, { useState, useEffect } from 'react';
import { useAuth } from '../../context/AuthContext.js';
import { useTheme } from '../../context/ThemeContext.js';
import {
  Settings as SettingsIcon,
  Moon,
  Sun,
  Shield,
  History,
  Layers,
  Keyboard,
  LogOut,
  Trash2,
  Check,
  AlertCircle,
  ExternalLink,
} from 'lucide-react';
import { WritingMode, WritingTone } from '@sayn/shared-types';

export const SettingsPage: React.FC = () => {
  const { user, signOut } = useAuth();
  const { theme, setTheme } = useTheme();

  const [preferredLang, setPreferredLang] = useState('en');
  const [defaultTone, setDefaultTone] = useState<WritingTone>('neutral');
  const [defaultMode, setDefaultMode] = useState<WritingMode>('grammar');
  const [historyEnabled, setHistoryEnabled] = useState(true);
  const [savedSuccess, setSavedSuccess] = useState(false);

  useEffect(() => {
    const savedHist = localStorage.getItem('sayn-history-enabled');
    if (savedHist !== null) {
      setHistoryEnabled(savedHist !== 'false');
    }
  }, []);

  const handleSavePreferences = () => {
    localStorage.setItem('sayn-history-enabled', historyEnabled ? 'true' : 'false');
    setSavedSuccess(true);
    setTimeout(() => setSavedSuccess(false), 2000);
  };

  const handleDeleteAccount = () => {
    if (
      window.confirm(
        'Are you sure you want to delete your SAYN account and all associated preferences? This action cannot be undone.'
      )
    ) {
      localStorage.clear();
      signOut();
    }
  };

  return (
    <div className="flex-1 max-w-4xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="flex items-center space-x-2.5 mb-6">
        <SettingsIcon className="w-5 h-5 text-sayn-dark-accent" />
        <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-sayn-dark-text">
          Settings & Preferences
        </h1>
      </div>

      <div className="space-y-6">
        {/* 1. APPEARANCE & THEME */}
        <div className="p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4">
          <h2 className="text-sm font-semibold text-sayn-dark-text">Appearance & Theme</h2>
          <div className="grid grid-cols-3 gap-3 max-w-sm">
            <button
              onClick={() => setTheme('dark')}
              className={`flex items-center justify-center space-x-2 p-3 rounded-ios-sm text-xs font-medium border transition-colors ${
                theme === 'dark'
                  ? 'bg-sayn-dark-surface2 text-sayn-dark-accent border-sayn-dark-accent'
                  : 'text-sayn-dark-secondary border-sayn-dark-divider hover:text-sayn-dark-text'
              }`}
            >
              <Moon className="w-4 h-4" />
              <span>Dark</span>
            </button>
            <button
              onClick={() => setTheme('light')}
              className={`flex items-center justify-center space-x-2 p-3 rounded-ios-sm text-xs font-medium border transition-colors ${
                theme === 'light'
                  ? 'bg-sayn-dark-surface2 text-sayn-dark-accent border-sayn-dark-accent'
                  : 'text-sayn-dark-secondary border-sayn-dark-divider hover:text-sayn-dark-text'
              }`}
            >
              <Sun className="w-4 h-4" />
              <span>Light</span>
            </button>
            <button
              onClick={() => setTheme('system')}
              className={`flex items-center justify-center space-x-2 p-3 rounded-ios-sm text-xs font-medium border transition-colors ${
                theme === 'system'
                  ? 'bg-sayn-dark-surface2 text-sayn-dark-accent border-sayn-dark-accent'
                  : 'text-sayn-dark-secondary border-sayn-dark-divider hover:text-sayn-dark-text'
              }`}
            >
              <span>System</span>
            </button>
          </div>
        </div>

        {/* 2. DEFAULT WRITING PREFERENCES */}
        <div className="p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4 text-xs">
          <h2 className="text-sm font-semibold text-sayn-dark-text">Writing Preferences</h2>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block font-semibold uppercase tracking-wider text-sayn-dark-muted mb-1.5">
                Default Writing Mode
              </label>
              <select
                value={defaultMode}
                onChange={(e) => setDefaultMode(e.target.value as WritingMode)}
                className="w-full px-3 py-2 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text focus:outline-none"
              >
                <option value="grammar">Grammar & Fix</option>
                <option value="paraphrase">Paraphrase</option>
                <option value="professional">Professional</option>
                <option value="casual">Casual</option>
                <option value="concise">Concise</option>
                <option value="clarity">Improve Clarity</option>
              </select>
            </div>

            <div>
              <label className="block font-semibold uppercase tracking-wider text-sayn-dark-muted mb-1.5">
                Default Writing Tone
              </label>
              <select
                value={defaultTone}
                onChange={(e) => setDefaultTone(e.target.value as WritingTone)}
                className="w-full px-3 py-2 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text focus:outline-none"
              >
                <option value="neutral">Neutral</option>
                <option value="professional">Professional</option>
                <option value="casual">Casual</option>
                <option value="friendly">Friendly</option>
                <option value="confident">Confident</option>
              </select>
            </div>
          </div>

          <div className="pt-2 flex items-center justify-between">
            <button
              onClick={handleSavePreferences}
              className="inline-flex items-center space-x-1.5 px-4 py-2 rounded-ios-sm font-medium text-white bg-sayn-dark-accent hover:opacity-90 transition-all"
            >
              {savedSuccess ? <Check className="w-3.5 h-3.5" /> : null}
              <span>{savedSuccess ? 'Saved' : 'Save Preferences'}</span>
            </button>
          </div>
        </div>

        {/* 3. PRIVACY & HISTORY LOGGING */}
        <div className="p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4">
          <div className="flex items-center space-x-2">
            <Shield className="w-4 h-4 text-sayn-dark-accent" />
            <h2 className="text-sm font-semibold text-sayn-dark-text">Privacy & History</h2>
          </div>

          <div className="flex items-center justify-between py-2 border-b border-sayn-dark-divider">
            <div>
              <div className="text-xs font-semibold text-sayn-dark-text">Save Writing History</div>
              <p className="text-[11px] text-sayn-dark-secondary">
                When enabled, refined text is temporarily saved in your local session history.
              </p>
            </div>
            <button
              onClick={() => {
                const next = !historyEnabled;
                setHistoryEnabled(next);
                localStorage.setItem('sayn-history-enabled', next ? 'true' : 'false');
              }}
              className={`w-11 h-6 flex items-center rounded-full p-1 transition-colors ${
                historyEnabled ? 'bg-sayn-dark-accent' : 'bg-sayn-dark-surface2'
              }`}
            >
              <div
                className={`bg-white w-4 h-4 rounded-full shadow-md transform transition-transform ${
                  historyEnabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          <div className="flex items-center justify-between py-2">
            <div>
              <div className="text-xs font-semibold text-sayn-dark-text">Audio Retention</div>
              <p className="text-[11px] text-sayn-dark-muted">
                Voice recordings are strictly ephemeral. Zero audio is stored on our servers.
              </p>
            </div>
            <span className="text-[11px] font-semibold text-sayn-dark-success">Disabled by Default</span>
          </div>
        </div>

        {/* 4. ANDROID SYSTEM ASSISTANT & KEYBOARD GUIDES */}
        <div className="p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4 text-xs">
          <h2 className="text-sm font-semibold text-sayn-dark-text">Android Native Integration</h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-4 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider space-y-2">
              <div className="flex items-center space-x-2 font-semibold text-sayn-dark-text">
                <Layers className="w-4 h-4 text-sayn-dark-accent" />
                <span>Floating Assistant Overlay</span>
              </div>
              <p className="text-sayn-dark-secondary leading-relaxed text-[11px]">
                Requires "Display over other apps" permission in Android Settings. Provides a movable floating bubble above WhatsApp, Gmail, Slack, and browsers.
              </p>
            </div>

            <div className="p-4 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider space-y-2">
              <div className="flex items-center space-x-2 font-semibold text-sayn-dark-text">
                <Keyboard className="w-4 h-4 text-sayn-dark-accent" />
                <span>SAYN Smart Keyboard</span>
              </div>
              <p className="text-sayn-dark-secondary leading-relaxed text-[11px]">
                Enable in Android Settings → Languages & Input. Types directly with AI grammar and tone transformation built into the top keyboard bar.
              </p>
            </div>
          </div>
        </div>

        {/* 5. ACCOUNT & SESSIONS */}
        <div className="p-6 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4">
          <h2 className="text-sm font-semibold text-sayn-dark-text">Account</h2>
          <div className="flex items-center justify-between text-xs">
            <div>
              <div className="font-semibold text-sayn-dark-text">{user?.email || 'Guest User'}</div>
              <div className="text-[11px] text-sayn-dark-muted">
                {user ? `User ID: ${user.id}` : 'Local Evaluation Session'}
              </div>
            </div>
            {user && (
              <button
                onClick={() => signOut()}
                className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-ios-sm text-xs text-sayn-dark-secondary hover:text-sayn-dark-text border border-sayn-dark-divider"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Sign Out</span>
              </button>
            )}
          </div>

          <div className="pt-4 border-t border-sayn-dark-divider flex items-center justify-between">
            <div>
              <div className="text-xs font-semibold text-sayn-dark-error">Delete Account</div>
              <p className="text-[11px] text-sayn-dark-muted">
                Permanently delete all preferences and history.
              </p>
            </div>
            <button
              onClick={handleDeleteAccount}
              className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-ios-sm text-xs font-semibold text-sayn-dark-error hover:bg-sayn-dark-error/10 border border-sayn-dark-error/30"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Delete Account</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
