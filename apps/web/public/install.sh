#!/usr/bin/env bash
set -e

# ==============================================================================
# SAYN Terminal Quick-Install Script for macOS & Linux
# One-command automated installation: curl -fsSL https://sayn.ai/install.sh | bash
# ==============================================================================

# Terminal ANSI Color Codes
BOLD="\033[1m"
RESET="\033[0m"
MAROON="\033[38;2;168;50;73m"
CREAM="\033[38;2;245;235;221m"
GREEN="\033[38;2;48;209;88m"
MUTED="\033[38;2;168;159;145m"
CYAN="\033[38;2;90;200;250m"

clear 2>/dev/null || true

echo -e "${MAROON}${BOLD}"
cat << "EOF"
   ____    _ __   ___   _ 
  / ___)  / _  \ \   \ | |
  \___ \ / /_\  \ |   \| |
  ____) )  ___   \| |\   |
 (_____/|_/   \_|_|_| \__|
EOF
echo -e "${CREAM} SAYN — The Intelligent Voice Assistant${RESET}"
echo -e "${MUTED} https://sayn.ai • Native macOS & Linux Quick-Install${RESET}"
echo ""

OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

case "$OS_TYPE" in
  Darwin*)
    echo -e "${CYAN}➜ Detected platform:${RESET} macOS ($ARCH_TYPE)"
    
    RELEASE_URL="https://github.com/allanmaaz/sayn/releases/latest/download/SAYN-macOS-Installer.dmg"
    TEMP_DIR="$(mktemp -d -t sayn_install_XXXXXX)"
    DMG_PATH="$TEMP_DIR/SAYN-macOS-Installer.dmg"
    MOUNT_POINT="$TEMP_DIR/sayn_mount"

    cleanup() {
      if [ -d "$MOUNT_POINT" ]; then
        hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null || true
      fi
      rm -rf "$TEMP_DIR" 2>/dev/null || true
    }
    trap cleanup EXIT

    echo -e "${CYAN}➜ Fetching latest SAYN release from GitHub...${RESET}"
    curl -fL --progress-bar "$RELEASE_URL" -o "$DMG_PATH"

    echo -e "${CYAN}➜ Mounting installer image...${RESET}"
    mkdir -p "$MOUNT_POINT"
    hdiutil attach "$DMG_PATH" -nobrowse -mountpoint "$MOUNT_POINT" -quiet

    echo -e "${CYAN}➜ Installing SAYN to /Applications...${RESET}"
    if [ -d "$MOUNT_POINT/SAYN.app" ]; then
      APP_SOURCE="$MOUNT_POINT/SAYN.app"
    elif [ -d "$MOUNT_POINT/Sayn.app" ]; then
      APP_SOURCE="$MOUNT_POINT/Sayn.app"
    else
      APP_SOURCE="$(find "$MOUNT_POINT" -maxdepth 2 -name "*.app" | head -n 1)"
    fi

    if [ -z "$APP_SOURCE" ] || [ ! -d "$APP_SOURCE" ]; then
      echo -e "\033[31mError: Could not find SAYN.app in the downloaded installer.\033[0m"
      exit 1
    fi

    # Remove existing version if present
    if [ -d "/Applications/SAYN.app" ]; then
      rm -rf "/Applications/SAYN.app" 2>/dev/null || sudo rm -rf "/Applications/SAYN.app"
    fi

    cp -R "$APP_SOURCE" "/Applications/SAYN.app"

    echo -e "${CYAN}➜ Configuring Gatekeeper permissions...${RESET}"
    xattr -cr "/Applications/SAYN.app" 2>/dev/null || true

    # Optional CLI symlink
    if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
      ln -sf "/Applications/SAYN.app/Contents/MacOS/SAYN" "/usr/local/bin/sayn" 2>/dev/null || true
    elif [ -d "$HOME/.local/bin" ]; then
      ln -sf "/Applications/SAYN.app/Contents/MacOS/SAYN" "$HOME/.local/bin/sayn" 2>/dev/null || true
    fi

    echo ""
    echo -e "${GREEN}${BOLD}✓ SAYN installed successfully into /Applications/SAYN.app!${RESET}"
    echo -e "${CREAM}➜ Launching SAYN...${RESET}"
    open "/Applications/SAYN.app"

    echo ""
    echo -e "${MUTED}• Trigger voice dictation anywhere by pressing ${BOLD}Fn${RESET}${MUTED} or ${BOLD}Option + Space${RESET}"
    echo -e "${MUTED}• Enjoy private, zero-latency voice typing and AI polishing!${RESET}"
    echo ""
    ;;

  Linux*)
    echo -e "${CYAN}➜ Detected platform:${RESET} Linux ($ARCH_TYPE)"
    echo -e "${MUTED}SAYN is currently launching native AppImage packages for Linux.${RESET}"
    echo -e "${CREAM}Please visit https://sayn.ai to access the SAYN Web Studio or PWA.${RESET}"
    ;;

  *)
    echo -e "\033[31mUnsupported operating system: $OS_TYPE\033[0m"
    echo -e "For Windows, use PowerShell: ${BOLD}irm https://sayn.ai/install.ps1 | iex${RESET}"
    exit 1
    ;;
esac
