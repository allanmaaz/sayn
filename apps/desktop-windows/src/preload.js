const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('saynDesktop', {
  pasteToActiveApp: (text) => ipcRenderer.send('pill-paste', text),
  closePill: () => ipcRenderer.send('pill-close'),
  isDesktop: true,
  platform: 'windows',
});
