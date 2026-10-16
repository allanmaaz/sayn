const { app, BrowserWindow, globalShortcut, Tray, Menu, ipcMain, clipboard } = require('electron');
const path = require('path');
const { exec } = require('child_process');

let mainWindow = null;
let pillWindow = null;
let tray = null;

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 820,
    minWidth: 900,
    minHeight: 600,
    backgroundColor: '#0D0D12',
    title: 'SAYN — AI Voice & Smart Writing Studio',
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
    show: false,
  });

  // Try loading local production dist or fallback to production URL
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
    width: 320,
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
    // Position floating pill horizontally centered at bottom of primary display
    const { screen } = require('electron');
    const primaryDisplay = screen.getPrimaryDisplay();
    const { width, height } = primaryDisplay.workAreaSize;
    pillWindow.setPosition(Math.round((width - 320) / 2), height - 100);
    pillWindow.show();
    pillWindow.webContents.send('start-listening');
  }
}

// Windows native auto-paste via PowerShell WScript.Shell SendKeys
function simulateWindowsPaste(text) {
  clipboard.writeText(text);
  // Send Ctrl+V using native Windows command
  const psCommand = `powershell -NoProfile -Command "$wshell = New-Object -ComObject wscript.shell; Start-Sleep -Milliseconds 50; $wshell.SendKeys('^v')"`;
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
    { type: 'separator' },
    {
      label: 'Quit SAYN',
      click: () => {
        app.isQuitting = true;
        app.quit();
      },
    },
  ]);
  tray.setToolTip('SAYN — AI Voice & Smart Writing Studio');
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
  createMainWindow();
  createPillWindow();
  setupTray();

  // Register Global Hotkey Alt+Space for instant Wispr Flow voice pill
  const ret = globalShortcut.register('Alt+Space', () => {
    togglePill();
  });

  if (!ret) {
    console.warn('Registration failed for Alt+Space hotkey');
  }

  // IPC handlers for Pill actions
  ipcMain.on('pill-paste', (_event, text) => {
    if (pillWindow) pillWindow.hide();
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
