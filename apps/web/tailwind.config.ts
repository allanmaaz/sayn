import type { Config } from 'tailwindcss';

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        sayn: {
          // Official SAYN Palette: Deep Maroon & Warm Cream
          maroon: {
            DEFAULT: '#6F1025',
            primary: '#6F1025',
            rose: '#A83249',
            light: '#8F1835',
            dark: '#4A0817',
            deep: '#360510',
          },
          cream: {
            DEFAULT: '#F5EBDD',
            light: '#FAF4EB',
            muted: '#D6C7B2',
            dim: '#A89F91',
            dark: '#6E665A',
          },
          // Dark canvas palette (70% Near-black #100709)
          dark: {
            bg: '#100709',
            surface: '#180B0F',
            surface2: '#240F16',
            elevated: '#2E141D',
            text: '#F5EBDD',
            secondary: '#D6C7B2',
            muted: '#A89F91',
            divider: '#3D1520',
            accent: '#6F1025',
            rose: '#A83249',
            cream: '#F5EBDD',
            volt: '#A83249',
            success: '#30D158',
            warning: '#FFD60A',
            error: '#FF453A',
          },
          // Light palette for high-contrast accessibility
          light: {
            bg: '#FAF4EB',
            surface: '#FFFFFF',
            surface2: '#F5EBDD',
            elevated: '#FFFFFF',
            text: '#100709',
            secondary: '#6E665A',
            muted: '#A89F91',
            divider: '#E5D6C2',
            accent: '#6F1025',
            rose: '#A83249',
            success: '#248A3D',
            warning: '#9A6700',
            error: '#D70015',
          },
          audio: '#A83249',
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
        ios: '16px',
        'ios-sm': '10px',
        'ios-lg': '22px',
        'ios-pill': '9999px',
      },
    },
  },
  plugins: [],
} satisfies Config;
