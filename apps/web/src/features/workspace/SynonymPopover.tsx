import React from 'react';
import { WordAlternative } from '@sayn/shared-types';
import { Sparkles, X } from 'lucide-react';

interface SynonymPopoverProps {
  alternative: WordAlternative;
  position: { top: number; left: number };
  onSelectSynonym: (newWord: string) => void;
  onClose: () => void;
}

export const SynonymPopover: React.FC<SynonymPopoverProps> = ({
  alternative,
  position,
  onSelectSynonym,
  onClose,
}) => {
  return (
    <div
      style={{
        top: `${position.top}px`,
        left: `${position.left}px`,
      }}
      className="fixed z-50 transform -translate-x-1/2 -translate-y-full mb-2 w-64 rounded-xl bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-accent/40 shadow-2xl p-3 text-xs glass-obsidian animate-in fade-in zoom-in-95 duration-150"
    >
      <div className="flex items-center justify-between pb-2 mb-2 border-b border-sayn-dark-divider">
        <div className="flex items-center space-x-1.5 text-sayn-dark-accent">
          <Sparkles className="w-3.5 h-3.5" />
          <span className="font-bold tracking-wide uppercase text-[10px]">
            Synonym Options
          </span>
        </div>
        <button
          onClick={onClose}
          className="text-sayn-dark-muted hover:text-sayn-dark-text transition-colors"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      <div className="mb-2">
        <span className="text-sayn-dark-muted text-[11px]">Original: </span>
        <span className="font-semibold text-sayn-dark-text line-through opacity-70">
          {alternative.originalWord}
        </span>
      </div>

      <div className="space-y-1 max-h-48 overflow-y-auto pr-1">
        {alternative.synonyms.map((syn, idx) => (
          <button
            key={idx}
            onClick={() => onSelectSynonym(syn)}
            className="w-full text-left px-2.5 py-1.5 rounded-lg text-sayn-dark-text hover:bg-sayn-dark-accent hover:text-black font-medium transition-all flex items-center justify-between group"
          >
            <span>{syn}</span>
            <span className="text-[10px] text-sayn-dark-muted group-hover:text-black/70">
              Apply ↵
            </span>
          </button>
        ))}
      </div>
    </div>
  );
};
