import React from 'react';
import { Link } from 'react-router-dom';

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider bg-sayn-dark-bg dark:bg-sayn-dark-bg light:bg-sayn-light-bg py-12 transition-colors duration-150">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
          {/* Brand Info */}
          <div className="space-y-3">
            <div className="flex items-center space-x-2.5">
              <img src="/logo.svg" alt="SAYN" className="w-6 h-6 rounded-md" />
              <span className="font-semibold text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text text-base">
                SAYN
              </span>
            </div>
            <p className="text-sm font-medium text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              Say it. Refine it. Send it.
            </p>
            <p className="text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted leading-relaxed">
              Speak naturally, refine your writing with precision AI, and communicate better across the apps you use every day.
            </p>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-3">
              Product
            </h4>
            <ul className="space-y-2 text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              <li>
                <Link to="/workspace" className="hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors">
                  AI Writing Workspace
                </Link>
              </li>
              <li>
                <Link to="/voice" className="hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors">
                  Voice Dictation
                </Link>
              </li>
              <li>
                <span className="text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted cursor-default">
                  Floating Overlay (Android)
                </span>
              </li>
              <li>
                <span className="text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted cursor-default">
                  Smart Keyboard (Android)
                </span>
              </li>
            </ul>
          </div>

          {/* Features */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-3">
              Capabilities
            </h4>
            <ul className="space-y-2 text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              <li>Grammar & Correction</li>
              <li>Tone Adjustment</li>
              <li>Paraphrasing & Brevity</li>
              <li>Idiomatic Translation</li>
              <li>Custom Prompts</li>
            </ul>
          </div>

          {/* Privacy & Legal */}
          <div>
            <h4 className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-3">
              Security & Privacy
            </h4>
            <ul className="space-y-2 text-sm text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
              <li>
                <a href="#privacy" className="hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors">
                  Privacy Policy
                </a>
              </li>
              <li>
                <a href="#terms" className="hover:text-sayn-dark-text dark:hover:text-sayn-dark-text light:hover:text-sayn-light-text transition-colors">
                  Terms of Service
                </a>
              </li>
              <li>No Permanent Audio Storage</li>
              <li>Local Preference Controls</li>
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider flex flex-col sm:flex-row items-center justify-between text-xs text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted">
          <p>© {new Date().getFullYear()} SAYN. All rights reserved.</p>
          <p className="mt-2 sm:mt-0">Designed with precision & simplicity.</p>
        </div>
      </div>
    </footer>
  );
};
