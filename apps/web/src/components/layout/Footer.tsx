import React from 'react';
import { Link } from 'react-router-dom';
import saynLogo from '../../assets/logo.png';
import { useTheme } from '../../context/ThemeContext.js';

export const Footer: React.FC = () => {
  const { actualTheme } = useTheme();
  const isLight = actualTheme === 'light';

  return (
    <footer
      className={`border-t transition-colors duration-150 pt-16 pb-8 overflow-hidden ${
        isLight
          ? 'border-[#E2D9CD] bg-[#FAF7F2]'
          : 'border-[#3D1520] bg-[#100709]'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
          {/* Brand Info */}
          <div className="space-y-3">
            <div className="flex items-center space-x-2.5">
              <img src={saynLogo} alt="SAYN" className="w-7 h-7 rounded-lg shadow-sm" />
              <span
                className={`font-bold text-lg tracking-wide ${
                  isLight ? 'text-[#2D0A12]' : 'text-[#F5EBDD]'
                }`}
              >
                SAYN
              </span>
            </div>
            <p className="text-sm font-semibold text-[#A83249]">
              Say it. Refine it. Send it.
            </p>
            <p
              className={`text-xs leading-relaxed ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              Speak naturally, refine your writing with precision AI, and communicate better across Mac, Windows, Android, and Web.
            </p>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Product
            </h4>
            <ul
              className={`space-y-2 text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li>
                <a
                  href="#features"
                  className={`transition-colors ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  AI Writing Capabilities
                </a>
              </li>
              <li>
                <a
                  href="#how-it-works"
                  className={`transition-colors ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Voice Dictation & Workflow
                </a>
              </li>
              <li>
                <a
                  href="#download"
                  className={`transition-colors ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Desktop & Mobile Apps
                </a>
              </li>
            </ul>
          </div>

          {/* Features */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Modes & Features
            </h4>
            <ul
              className={`space-y-2 text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li>Prompt Mode & AI Commands</li>
              <li>Live Translation Mode</li>
              <li>Per-App Smart Adaptation</li>
              <li>Grammar & Flow Polishing</li>
              <li>Custom Vocabulary Biasing</li>
            </ul>
          </div>

          {/* Privacy & Legal */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Security & Privacy
            </h4>
            <ul
              className={`space-y-2 text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li>
                <a
                  href="#privacy"
                  className={`transition-colors ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Privacy Policy
                </a>
              </li>
              <li>No Permanent Audio Storage</li>
              <li>Zero Tracking Guarantee</li>
              <li>100% Free & Open Ecosystem</li>
            </ul>
          </div>
        </div>

        {/* The Sonic Monolith Brand Watermark in Syne */}
        <div
          className={`font-syne text-[17vw] font-extrabold leading-[0.85] text-center tracking-tighter select-none my-4 pointer-events-none transition-all ${
            isLight
              ? 'text-transparent bg-gradient-to-b from-[#6F1025]/25 via-[#A83249]/10 to-transparent bg-clip-text'
              : 'text-transparent bg-gradient-to-b from-[#D9385A]/35 to-[#100205]/5 bg-clip-text'
          }`}
          style={{
            WebkitTextStroke: isLight ? '1px rgba(111,16,37,0.35)' : '1.5px rgba(217, 56, 90, 0.45)',
          }}
        >
          SAYN
        </div>

        <div
          className={`pt-6 border-t flex flex-col sm:flex-row items-center justify-between text-xs transition-colors ${
            isLight
              ? 'border-[#E2D9CD] text-[#706E6B]'
              : 'border-[#3D1520]/60 text-[#A89F91]'
          }`}
        >
          <p>© {new Date().getFullYear()} SAYN. All rights reserved.</p>
          <p
            className={`mt-2 sm:mt-0 font-medium ${
              isLight ? 'text-[#2D0A12]' : 'text-[#D6C7B2]'
            }`}
          >
            Crafted with Deep Maroon & Warm Cream
          </p>
        </div>
      </div>
    </footer>
  );
};
