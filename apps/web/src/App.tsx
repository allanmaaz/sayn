import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { AppShell } from './components/layout/AppShell.js';
import { LandingPage } from './features/landing/LandingPage.js';
import { WorkspacePage } from './features/workspace/WorkspacePage.js';
import { VoicePage } from './features/voice/VoicePage.js';
import { HistoryPage } from './features/history/HistoryPage.js';
import { SavedPromptsPage } from './features/prompts/SavedPromptsPage.js';
import { SettingsPage } from './features/settings/SettingsPage.js';
import { LoginPage } from './features/auth/LoginPage.js';
import { SignupPage } from './features/auth/SignupPage.js';

export const App: React.FC = () => {
  return (
    <AppShell>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/workspace" element={<WorkspacePage />} />
        <Route path="/voice" element={<VoicePage />} />
        <Route path="/history" element={<HistoryPage />} />
        <Route path="/prompts" element={<SavedPromptsPage />} />
        <Route path="/settings" element={<SettingsPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/signup" element={<SignupPage />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </AppShell>
  );
};
