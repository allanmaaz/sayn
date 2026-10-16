import React from 'react';
import { Navbar } from './Navbar.js';
import { Footer } from './Footer.js';

export const AppShell: React.FC<{ children: React.ReactNode; showFooter?: boolean }> = ({
  children,
  showFooter = true,
}) => {
  return (
    <div className="min-h-screen flex flex-col bg-sayn-dark-bg dark:bg-sayn-dark-bg light:bg-sayn-light-bg text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text transition-colors duration-150">
      <Navbar />
      <main className="flex-1 flex flex-col pt-20 sm:pt-24">{children}</main>
      {showFooter && <Footer />}
    </div>
  );
};
