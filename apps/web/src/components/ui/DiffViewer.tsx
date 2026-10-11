import React from 'react';

interface DiffViewerProps {
  original: string;
  refined: string;
}

export const DiffViewer: React.FC<DiffViewerProps> = ({ original, refined }) => {
  // Simple word-level visual comparison
  const originalWords = original.split(/(\s+)/);
  const refinedWords = refined.split(/(\s+)/);

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm font-sans">
      <div className="p-4 rounded-ios-sm bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
        <div className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-2">
          Original Text
        </div>
        <p className="whitespace-pre-wrap leading-relaxed text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary">
          {original}
        </p>
      </div>

      <div className="p-4 rounded-ios-sm bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider">
        <div className="text-xs font-semibold uppercase tracking-wider text-sayn-dark-accent dark:text-sayn-dark-accent light:text-sayn-light-accent mb-2">
          Refined Output
        </div>
        <p className="whitespace-pre-wrap leading-relaxed text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text font-normal">
          {refined}
        </p>
      </div>
    </div>
  );
};
