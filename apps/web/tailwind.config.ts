import type { Config } from 'tailwindcss';

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        sayn: {
          // Dark palette
          dark: {
            bg: '#0B0B0D',
            surface: '#151518',
            surface2: '#1C1C20',
            elevated: '#242428',
            text: '#F5F5F7',
            secondary: '#A1A1AA',
            muted: '#71717A',
            divider: '#303036',
            accent: '#0A84FF',
            success: '#30D158',
            warning: '#FFD60A',
            error: '#FF453A',
          },
          // Light palette
          light: {
            bg: '#F5F5F7',
            surface: '#FFFFFF',
            surface2: '#F0F0F2',
            elevated: '#FFFFFF',
            text: '#1D1D1F',
            secondary: '#6E6E73',
            muted: '#8E8E93',
            divider: '#D2D2D7',
            accent: '#007AFF',
            success: '#248A3D',
            warning: '#9A6700',
            error: '#D70015',
          },
          // Restrained audio accent
          audio: '#5DE4FF',
        },
      },
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          '"SF Pro Text"',
          '"SF Pro Display"',
          'Inter',
          'ui-sans-serif',
          'system-ui',
          'sans-serif',
        ],
      },
      borderRadius: {
        ios: '14px',
        'ios-sm': '10px',
        'ios-lg': '18px',
        'ios-pill': '9999px',
      },
    },
  },
  plugins: [],
} satisfies Config;
