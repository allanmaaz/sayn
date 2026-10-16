/**
 * Intelligent Client-Side Device and OS Detector for SAYN
 * Accurately detects OS (macOS, Windows, Android, iOS, Linux)
 * and hardware architecture (Apple Silicon vs Intel, 64-bit vs 32-bit Windows).
 */

export type OperatingSystem = 'macos' | 'windows' | 'android' | 'ios' | 'linux' | 'unknown';
export type Architecture = 'arm64' | 'x86_64' | 'x86_32' | 'universal' | 'unknown';

export interface DeviceInfo {
  os: OperatingSystem;
  osName: string;
  arch: Architecture;
  archName: string;
  isMobile: boolean;
  recommendedFileName: string;
  recommendedDownloadUrl: string;
  badgeLabel: string;
  instructions: string;
}

const GITHUB_RELEASE_BASE = 'https://github.com/allanmaaz/sayn/releases/latest/download';

export function detectDevice(): DeviceInfo {
  if (typeof window === 'undefined') {
    return getFallbackDeviceInfo();
  }

  const ua = navigator.userAgent || '';
  const platform = navigator.platform || '';
  const maxTouchPoints = navigator.maxTouchPoints || 0;

  // 1. Android Detection
  if (/android/i.test(ua)) {
    return {
      os: 'android',
      osName: 'Android',
      arch: 'universal',
      archName: 'Universal (ARM64 / ARMv7)',
      isMobile: true,
      recommendedFileName: 'sayn-release.apk',
      recommendedDownloadUrl: `${GITHUB_RELEASE_BASE}/sayn-release.apk`,
      badgeLabel: 'Android APK',
      instructions: 'Download the APK and tap to install. Enable "Install from unknown sources" if prompted.',
    };
  }

  // 2. iOS / iPadOS Detection
  const isIOS = /iPad|iPhone|iPod/.test(ua) || (platform === 'MacIntel' && maxTouchPoints > 1);
  if (isIOS) {
    return {
      os: 'ios',
      osName: 'iOS / iPadOS',
      arch: 'arm64',
      archName: 'Apple Mobile',
      isMobile: true,
      recommendedFileName: 'SAYN Web Studio (PWA)',
      recommendedDownloadUrl: '#pwa-install',
      badgeLabel: 'Install PWA',
      instructions: 'Tap the Share icon in Safari, then tap "Add to Home Screen" to install SAYN natively.',
    };
  }

  // 3. macOS Detection
  if (/Macintosh|Mac OS X|MacPPC|MacIntel/i.test(ua) && !isIOS) {
    let isAppleSilicon = false;

    // Detect Apple Silicon via WebGL unmasked renderer
    try {
      const canvas = document.createElement('canvas');
      const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
      if (gl) {
        const debugInfo = (gl as WebGLRenderingContext).getExtension('WEBGL_debug_renderer_info');
        if (debugInfo) {
          const renderer = (gl as WebGLRenderingContext).getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
          if (/Apple/i.test(renderer) && !/Apple Software Renderer/i.test(renderer)) {
            isAppleSilicon = true;
          }
        }
      }
    } catch (_) {}

    return {
      os: 'macos',
      osName: 'macOS',
      arch: isAppleSilicon ? 'arm64' : 'universal',
      archName: isAppleSilicon ? 'Apple Silicon (M1/M2/M3/M4)' : 'Universal (Apple Silicon & Intel)',
      isMobile: false,
      recommendedFileName: 'San-macOS-Installer.dmg',
      recommendedDownloadUrl: `${GITHUB_RELEASE_BASE}/San-macOS-Installer.dmg`,
      badgeLabel: 'macOS DMG',
      instructions: 'Open the DMG and drag San to your Applications folder. Global Hotkey: Press Fn key or ⌥ Space.',
    };
  }

  // 4. Windows Detection
  if (/Win32|Win64|Windows|WinCE/i.test(ua)) {
    // Check 64-bit indicators
    const is64Bit = /WOW64|Win64|x64|x86_64/i.test(ua);

    return {
      os: 'windows',
      osName: 'Windows',
      arch: is64Bit ? 'x86_64' : 'x86_32',
      archName: is64Bit ? '64-Bit (x64)' : '32-Bit (ia32)',
      isMobile: false,
      recommendedFileName: is64Bit ? 'SAYN-Setup-1.1.0-x64.exe' : 'SAYN-Setup-1.1.0-ia32.exe',
      recommendedDownloadUrl: is64Bit
        ? `${GITHUB_RELEASE_BASE}/SAYN-Setup-1.1.0-x64.exe`
        : `${GITHUB_RELEASE_BASE}/SAYN-Setup-1.1.0-ia32.exe`,
      badgeLabel: is64Bit ? 'Windows 64-bit' : 'Windows 32-bit',
      instructions: 'Run the setup installer. Press Alt + Space anywhere on Windows to trigger the San voice pill.',
    };
  }

  // 5. Linux / Fallback
  return {
    os: 'linux',
    osName: 'Linux / Web',
    arch: 'universal',
    archName: 'Standalone PWA',
    isMobile: false,
    recommendedFileName: 'SAYN Web Studio (PWA)',
    recommendedDownloadUrl: '#pwa-install',
    badgeLabel: 'Install PWA',
    instructions: 'Click the install icon in your browser address bar to install SAYN as a standalone desktop app.',
  };
}

function getFallbackDeviceInfo(): DeviceInfo {
  return {
    os: 'unknown',
    osName: 'Universal Desktop & Mobile',
    arch: 'universal',
    archName: 'Universal',
    isMobile: false,
    recommendedFileName: 'San-macOS-Installer.dmg',
    recommendedDownloadUrl: `${GITHUB_RELEASE_BASE}/San-macOS-Installer.dmg`,
    badgeLabel: 'Free Download',
    instructions: 'Choose the appropriate installer for your operating system below.',
  };
}

export const ALL_DOWNLOAD_OPTIONS = [
  {
    category: 'macOS',
    title: 'San for macOS Universal 2 Installer',
    arch: 'Apple Silicon (M1/M2/M3/M4) + Intel',
    fileName: 'San-macOS-Installer.dmg',
    url: `${GITHUB_RELEASE_BASE}/San-macOS-Installer.dmg`,
    tag: 'Recommended for Mac',
    format: '.dmg',
    size: '898 KB',
  },
  {
    category: 'Windows',
    title: 'Windows 64-bit Setup Installer',
    arch: 'Windows 11 / 10 (x64)',
    fileName: 'SAYN-Setup-1.1.0-x64.exe',
    url: `${GITHUB_RELEASE_BASE}/SAYN-Setup-1.1.0-x64.exe`,
    tag: 'Recommended for Windows 64-bit',
    format: '.exe (NSIS)',
    size: 'Standalone',
  },
  {
    category: 'Windows',
    title: 'Windows 32-bit Setup Installer',
    arch: 'Windows 10 / 8 / 7 (32-bit ia32)',
    fileName: 'SAYN-Setup-1.1.0-ia32.exe',
    url: `${GITHUB_RELEASE_BASE}/SAYN-Setup-1.1.0-ia32.exe`,
    tag: 'Legacy 32-bit',
    format: '.exe (NSIS)',
    size: 'Standalone',
  },
  {
    category: 'Windows',
    title: 'Windows 64-bit Portable',
    arch: 'Windows 11 / 10 (No installation needed)',
    fileName: 'SAYN-Portable-1.1.0-x64.exe',
    url: `${GITHUB_RELEASE_BASE}/SAYN-Portable-1.1.0-x64.exe`,
    tag: 'Portable',
    format: '.exe',
    size: 'Zero Install',
  },
  {
    category: 'Windows',
    title: 'Windows 32-bit Portable',
    arch: 'Windows 32-bit (No installation needed)',
    fileName: 'SAYN-Portable-1.1.0-ia32.exe',
    url: `${GITHUB_RELEASE_BASE}/SAYN-Portable-1.1.0-ia32.exe`,
    tag: 'Portable',
    format: '.exe',
    size: 'Zero Install',
  },
  {
    category: 'Android',
    title: 'Android Universal Release APK',
    arch: 'All Android devices (ARM64, ARMv7, x86)',
    fileName: 'sayn-release.apk',
    url: `${GITHUB_RELEASE_BASE}/sayn-release.apk`,
    tag: 'Android 8.0+',
    format: '.apk',
    size: 'Release Signed',
  },
];
