import React from 'react';
import { useLocation } from 'react-router-dom';
import { Navbar } from './Navbar.js';
import { Footer } from './Footer.js';

export const AppShell: React.FC<{ children: React.ReactNode; showFooter?: boolean }> = ({
  children,
  showFooter = true,
}) => {
  const location = useLocation();
  const isLanding = location.pathname === '/';

  return (
    <div
      className={
        isLanding
          ? 'min-h-screen flex flex-col bg-[#FAF4EB] text-[#581121]'
          : 'min-h-screen flex flex-col bg-sayn-dark-bg dark:bg-sayn-dark-bg light:bg-sayn-light-bg text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text transition-colors duration-150'
      }
    >
      {!isLanding && <Navbar />}
      <main className={`flex-1 flex flex-col ${isLanding ? '' : 'pt-20 sm:pt-24'}`}>{children}</main>
      {showFooter && !isLanding && <Footer />}
    </div>
  );
};
