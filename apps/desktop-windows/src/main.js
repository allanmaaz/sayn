const { app, BrowserWindow, globalShortcut, Tray, Menu, ipcMain, clipboard, shell } = require('electron');
const path = require('path');
const fs = require('fs');
const { exec } = require('child_process');

let mainWindow = null;
let pillWindow = null;
let tray = null;
let currentExecutionMode = 'dictate';

const configDir = path.join(app.getPath('userData'), 'config');
const vocabFile = path.join(configDir, 'vocabulary.json');
const snippetsFile = path.join(configDir, 'snippets.json');

function ensureConfig() {
  try {
    if (!fs.existsSync(configDir)) {
      fs.mkdirSync(configDir, { recursive: true });
    }
    if (!fs.existsSync(vocabFile)) {
      fs.writeFileSync(vocabFile, JSON.stringify({ terms: ["SAYN", "San", "Groq", "Whisper", "TypeScript", "React", "Electron", "API"] }, null, 2));
    }
    if (!fs.existsSync(snippetsFile)) {
      fs.writeFileSync(snippetsFile, JSON.stringify({
        snippets: [
          { trigger: "insert standup", template: "🚀 Daily Standup:\n- Yesterday: \n- Today: \n- Blockers: None" },
          { trigger: "insert signature", template: "Best regards,\nSent with SAYN Voice" }
        ]
      }, null, 2));
    }
  } catch (e) {
    console.error('Config init error:', e);
  }
}

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1240,
    height: 840,
    minWidth: 920,
    minHeight: 620,
    backgroundColor: '#100709',
    title: 'SAYN — AI Voice & Smart Writing Studio',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false,
  });

  const indexPath = path.join(__dirname, '../dist/index.html');
  mainWindow.loadFile(indexPath).catch(() => {
    mainWindow.loadURL('http://localhost:5173');
  });

  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  mainWindow.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
    return false;
  });
}

function createPillWindow() {
  pillWindow = new BrowserWindow({
    width: 440,
    height: 64,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    show: false,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
  });

  pillWindow.loadFile(path.join(__dirname, 'pill.html'));
}

function togglePill() {
  if (!pillWindow) {
    createPillWindow();
  }
  if (pillWindow.isVisible()) {
    pillWindow.hide();
  } else {
    const { screen } = require('electron');
    const primaryDisplay = screen.getPrimaryDisplay();
    const { width, height } = primaryDisplay.workAreaSize;
    pillWindow.setPosition(Math.round((width - 440) / 2), height - 100);
    pillWindow.show();
    pillWindow.webContents.send('start-listening');
  }
}

function cyclePillMode() {
  if (pillWindow) {
    pillWindow.webContents.send('cycle-mode');
  }
}

// Windows native auto-paste via PowerShell WScript.Shell SendKeys
function simulateWindowsPaste(text) {
  clipboard.writeText(text);
  const psCommand = `powershell -NoProfile -Command "$wshell = New-Object -ComObject wscript.shell; Start-Sleep -Milliseconds 60; $wshell.SendKeys('^v')"`;
  exec(psCommand, (err) => {
    if (err) {
      console.error('Error pasting via PowerShell:', err);
    }
  });
}

function setupTray() {
  const iconPath = path.join(__dirname, '../resources/icon.png');
  tray = new Tray(iconPath);
  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Open SAYN Studio',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        } else {
          createMainWindow();
        }
      },
    },
    {
      label: 'Toggle Voice Pill (Alt+Space)',
      click: () => togglePill(),
    },
    {
      label: 'Cycle Mode (Alt+M)',
      click: () => cyclePillMode(),
    },
    { type: 'separator' },
    {
      label: 'Edit Custom Vocabulary...',
      click: () => shell.openPath(vocabFile),
    },
    {
      label: 'Edit Voice Snippets...',
      click: () => shell.openPath(snippetsFile),
    },
    { type: 'separator' },
    {
      label: 'Quit SAYN',
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);
  tray.setToolTip('SAYN — AI Voice & Smart Writing Studio (Deep Maroon & Warm Cream)');
  tray.setContextMenu(contextMenu);
  tray.on('double-click', () => {
    if (mainWindow) {
      mainWindow.show();
    } else {
      createMainWindow();
    }
  });
}

app.whenReady().then(() => {
  ensureConfig();
  createMainWindow();
  createPillWindow();
  setupTray();

  // Register Global Hotkeys
  globalShortcut.register('Alt+Space', () => {
    togglePill();
  });

  globalShortcut.register('Alt+M', () => {
    cyclePillMode();
  });

  // IPC handlers
  ipcMain.on('mode-changed', (_event, mode) => {
    currentExecutionMode = mode;
  });

  ipcMain.on('pill-commit', (_event, data) => {
    if (pillWindow) pillWindow.hide();
    const mode = (data && data.mode) || currentExecutionMode;
    const text = (data && data.text) || 'Polished output from SAYN Voice.';
    simulateWindowsPaste(text);
  });

  ipcMain.on('pill-close', () => {
    if (pillWindow) pillWindow.hide();
  });
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createMainWindow();
  }
});
