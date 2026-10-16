import React from 'react';
import { Link } from 'react-router-dom';
import saynLogo from '../../assets/logo.png';

export const Footer: React.FC = () => {
  return (
    <footer className="border-t border-[#3D1520] bg-[#100709] py-14 transition-colors duration-150">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
          {/* Brand Info */}
          <div className="space-y-3">
            <div className="flex items-center space-x-2.5">
              <img src={saynLogo} alt="SAYN" className="w-7 h-7 rounded-lg shadow-sm" />
              <span className="font-bold text-[#F5EBDD] text-lg tracking-wide">
                SAYN
              </span>
            </div>
            <p className="text-sm font-semibold text-[#A83249]">
              Say it. Refine it. Send it.
            </p>
            <p className="text-xs text-[#D6C7B2] leading-relaxed">
              Speak naturally, refine your writing with precision AI, and communicate better across Mac, Windows, Android, and Web.
            </p>
          </div>

          {/* Product Links */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Product
            </h4>
            <ul className="space-y-2 text-sm text-[#D6C7B2]">
              <li>
                <Link to="/workspace" className="hover:text-[#F5EBDD] transition-colors">
                  AI Writing Studio
                </Link>
              </li>
              <li>
                <Link to="/voice" className="hover:text-[#F5EBDD] transition-colors">
                  Voice Dictation
                </Link>
              </li>
              <li>
                <Link to="/download" className="hover:text-[#F5EBDD] transition-colors">
                  Desktop & Mobile Apps
                </Link>
              </li>
            </ul>
          </div>

          {/* Features */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Modes & Features
            </h4>
            <ul className="space-y-2 text-sm text-[#D6C7B2]">
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
            <ul className="space-y-2 text-sm text-[#D6C7B2]">
              <li>
                <a href="#privacy" className="hover:text-[#F5EBDD] transition-colors">
                  Privacy Policy
                </a>
              </li>
              <li>No Permanent Audio Storage</li>
              <li>Zero Tracking Guarantee</li>
              <li>100% Free & Open Ecosystem</li>
            </ul>
          </div>
        </div>

        <div className="pt-8 border-t border-[#3D1520]/60 flex flex-col sm:flex-row items-center justify-between text-xs text-[#A89F91]">
          <p>© {new Date().getFullYear()} SAYN. All rights reserved.</p>
          <p className="mt-2 sm:mt-0 font-medium text-[#D6C7B2]">Crafted with Deep Maroon & Warm Cream.</p>
        </div>
      </div>
    </footer>
  );
};
