import React, { useRef, useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import saynLogo from '../../assets/logo.png';
import { useTheme } from '../../context/ThemeContext.js';

export const Footer: React.FC = () => {
  const { actualTheme } = useTheme();
  const isLight = actualTheme === 'light';

  // Scroll-in reveal animation tracking ("only scroll in")
  const monolithRef = useRef<HTMLDivElement | null>(null);
  const [enterProgress, setEnterProgress] = useState(0);

  useEffect(() => {
    const handleScroll = () => {
      if (!monolithRef.current) return;
      const rect = monolithRef.current.getBoundingClientRect();
      const windowHeight = window.innerHeight;

      // Starts revealing as the monolith approaches bottom of viewport (98% of windowHeight)
      // Reaches full 100% convergence when it is well centered in view (55% of windowHeight)
      const start = windowHeight * 0.98;
      const end = windowHeight * 0.55;
      const p = Math.min(1, Math.max(0, (start - rect.top) / (start - end)));
      setEnterProgress(p);
    };

    window.addEventListener('scroll', handleScroll, { passive: true });
    window.addEventListener('resize', handleScroll, { passive: true });
    handleScroll();
    return () => {
      window.removeEventListener('scroll', handleScroll);
      window.removeEventListener('resize', handleScroll);
    };
  }, []);

  return (
    <footer
      className={`border-t transition-colors duration-150 pt-16 pb-8 overflow-hidden relative ${
        isLight
          ? 'border-[#E2D9CD] bg-[#FAF7F2]'
          : 'border-[#3D1520] bg-[#100709]'
      }`}
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Responsive Footer Links Grid (2 columns on mobile, 4 columns on desktop) */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 sm:gap-8 mb-10 text-left">
          {/* Brand Info */}
          <div className="col-span-2 md:col-span-1 space-y-3">
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
          <div className="col-span-1">
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Product
            </h4>
            <ul
              className={`space-y-2 text-xs sm:text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li>
                <a
                  href="#features"
                  className={`transition-colors block py-1 ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  AI Writing Capabilities
                </a>
              </li>
              <li>
                <a
                  href="#how-it-works"
                  className={`transition-colors block py-1 ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Voice Dictation & Workflow
                </a>
              </li>
              <li>
                <a
                  href="#download"
                  className={`transition-colors block py-1 ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Desktop & Mobile Apps
                </a>
              </li>
            </ul>
          </div>

          {/* Modes & Features */}
          <div className="col-span-1">
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Modes & Features
            </h4>
            <ul
              className={`space-y-2 text-xs sm:text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li className="py-1">Prompt Mode & AI Commands</li>
              <li className="py-1">Live Translation Mode</li>
              <li className="py-1">Per-App Smart Adaptation</li>
              <li className="py-1">Grammar & Flow Polishing</li>
              <li className="py-1">Custom Vocabulary Biasing</li>
            </ul>
          </div>

          {/* Privacy & Legal */}
          <div className="col-span-2 md:col-span-1">
            <h4 className="text-xs font-bold uppercase tracking-wider text-[#A83249] mb-3">
              Security & Privacy
            </h4>
            <ul
              className={`space-y-2 text-xs sm:text-sm ${
                isLight ? 'text-[#5C4D44]' : 'text-[#D6C7B2]'
              }`}
            >
              <li>
                <a
                  href="#privacy"
                  className={`transition-colors block py-1 ${
                    isLight ? 'hover:text-[#2D0A12]' : 'hover:text-[#F5EBDD]'
                  }`}
                >
                  Privacy Policy
                </a>
              </li>
              <li className="py-1">No Permanent Audio Storage</li>
              <li className="py-1">Zero Tracking Guarantee</li>
              <li className="py-1">100% Free & Open Ecosystem</li>
            </ul>
          </div>
        </div>

        {/* The Sonic Monolith Brand Watermark with Geometric Wireframe & Scroll-In Entrance */}
        <div
          ref={monolithRef}
          className="w-full overflow-hidden flex flex-col items-center justify-center py-4 my-2 sm:my-4 select-none relative"
        >
          {/* Container with dynamic scroll-in translation, scale and letter-spacing */}
          <div
            className="relative w-full flex items-center justify-center transition-all duration-150 ease-out"
            style={{
              opacity: Math.min(1, Math.max(0.12, enterProgress)),
              transform: `translate3d(0, ${(1 - enterProgress) * 36}px, 0) scale(${0.92 + enterProgress * 0.08})`,
              letterSpacing: `${(1 - enterProgress) * 0.035}em`,
            }}
          >
            {/* SAYN Giant Typography */}
            <div
              className={`font-syne text-[18.5vw] sm:text-[17vw] md:text-[16vw] lg:text-[190px] xl:text-[220px] font-extrabold leading-none tracking-tighter whitespace-nowrap text-center select-none pointer-events-none transition-all ${
                isLight
                  ? 'text-transparent bg-gradient-to-b from-[#6F1025]/30 via-[#A83249]/15 to-transparent bg-clip-text'
                  : 'text-transparent bg-gradient-to-b from-[#D9385A]/40 to-[#100205]/10 bg-clip-text'
              }`}
              style={{
                WebkitTextStroke: isLight ? '1px rgba(111,16,37,0.35)' : '1.3px rgba(217, 56, 90, 0.45)',
              }}
            >
              SAYN
            </div>

            {/* Architectural Geometric Laser Wireframe Overlay matching reference image */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none transition-opacity duration-300"
              viewBox="0 0 1000 280"
              fill="none"
              preserveAspectRatio="none"
              style={{ opacity: Math.min(1, enterProgress * 0.95) }}
            >
              {/* Harmonic curve wave passing across S and A */}
              <path
                d="M 30 140 Q 160 80 230 140 T 420 140"
                stroke="#FF4D73"
                strokeWidth="1.2"
                strokeOpacity="0.4"
                strokeDasharray="4 4"
              />

              {/* Geometric Polygon Wireframe over Letter A */}
              <polygon
                points="300,205 385,55 470,205"
                stroke="#D9385A"
                strokeWidth="1.5"
                strokeOpacity={0.65 * enterProgress}
                fill="none"
              />
              <line
                x1="318"
                y1="165"
                x2="452"
                y2="165"
                stroke="#FF4D73"
                strokeWidth="1.5"
                strokeOpacity={0.75 * enterProgress}
              />

              {/* Geometric Polygon Wireframe over Letter Y */}
              <polygon
                points="490,60 560,175 630,60"
                stroke="#D9385A"
                strokeWidth="1.5"
                strokeOpacity={0.65 * enterProgress}
                fill="none"
              />
              <line
                x1="560"
                y1="175"
                x2="560"
                y2="245"
                stroke="#FF4D73"
                strokeWidth="1.5"
                strokeOpacity={0.75 * enterProgress}
              />

              {/* Geometric Diagonal Crossbeam over Letter N */}
              <polyline
                points="690,225 690,55 830,225 830,55"
                stroke="#D9385A"
                strokeWidth="1.5"
                strokeOpacity={0.65 * enterProgress}
                fill="none"
              />
              <line
                x1="690"
                y1="55"
                x2="830"
                y2="225"
                stroke="#FF4D73"
                strokeWidth="1.8"
                strokeOpacity={0.8 * enterProgress}
              />
            </svg>

            {/* Glowing Horizontal Laser Line passing through center */}
            <div
              className="absolute top-1/2 left-0 right-0 h-[1.5px] pointer-events-none transition-all duration-150"
              style={{
                background:
                  'linear-gradient(90deg, transparent 0%, rgba(200,62,91,0.25) 15%, #FF4D73 50%, rgba(200,62,91,0.25) 85%, transparent 100%)',
                opacity: enterProgress,
                transform: `scaleX(${enterProgress})`,
                boxShadow: '0 0 20px 2px rgba(255, 77, 115, 0.65)',
              }}
            />
          </div>
        </div>

        {/* Bottom Copyright & Tagline Bar */}
        <div
          className={`pt-6 border-t flex flex-col sm:flex-row items-center justify-between text-xs transition-colors gap-2 sm:gap-0 ${
            isLight
              ? 'border-[#E2D9CD] text-[#706E6B]'
              : 'border-[#3D1520]/60 text-[#A89F91]'
          }`}
        >
          <p>© {new Date().getFullYear()} SAYN. All rights reserved.</p>
          <p
            className={`font-medium ${
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
