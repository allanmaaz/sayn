import React from 'react';
import { GrammarIssue, GrammarlyPillar } from '@sayn/shared-types';
import { Check, X, AlertCircle, Sparkles, Compass, ShieldCheck } from 'lucide-react';

interface GrammarlyIssueCardProps {
  issue: GrammarIssue;
  onAccept: (issue: GrammarIssue) => void;
  onDismiss: (issue: GrammarIssue) => void;
}

const PILLAR_CONFIG: Record<
  GrammarlyPillar,
  { label: string; color: string; bg: string; border: string; icon: any }
> = {
  correctness: {
    label: 'Correctness',
    color: 'text-red-400',
    bg: 'bg-red-500/10',
    border: 'border-red-500/30',
    icon: AlertCircle,
  },
  clarity: {
    label: 'Clarity',
    color: 'text-blue-400',
    bg: 'bg-blue-500/10',
    border: 'border-blue-500/30',
    icon: Compass,
  },
  engagement: {
    label: 'Engagement',
    color: 'text-emerald-400',
    bg: 'bg-emerald-500/10',
    border: 'border-emerald-500/30',
    icon: Sparkles,
  },
  delivery: {
    label: 'Delivery',
    color: 'text-purple-400',
    bg: 'bg-purple-500/10',
    border: 'border-purple-500/30',
    icon: ShieldCheck,
  },
};

export const GrammarlyIssueCard: React.FC<GrammarlyIssueCardProps> = ({
  issue,
  onAccept,
  onDismiss,
}) => {
  const cfg = PILLAR_CONFIG[issue.pillar] || PILLAR_CONFIG.correctness;
  const IconComponent = cfg.icon;

  return (
    <div className={`p-3.5 rounded-xl border ${cfg.border} ${cfg.bg} glass-obsidian shadow-lg space-y-2.5 transition-all animate-in fade-in`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-1.5">
          <IconComponent className={`w-3.5 h-3.5 ${cfg.color}`} />
          <span className={`text-[10px] font-bold uppercase tracking-wider ${cfg.color}`}>
            {cfg.label}
          </span>
          <span className="text-[11px] font-semibold text-sayn-dark-text ml-1">
            • {issue.title}
          </span>
        </div>
        <button
          onClick={() => onDismiss(issue)}
          className="text-sayn-dark-muted hover:text-sayn-dark-text transition-colors p-0.5"
          title="Dismiss suggestion"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>

      <p className="text-xs text-sayn-dark-secondary leading-relaxed">
        {issue.explanation}
      </p>

      <div className="flex items-center justify-between pt-1 border-t border-white/5">
        <div className="flex items-center space-x-2 text-xs">
          <span className="line-through text-sayn-dark-muted font-mono">
            {issue.originalText}
          </span>
          <span className="text-sayn-dark-muted">→</span>
          <span className="font-bold text-sayn-dark-accent font-mono">
            {issue.suggestedReplacement || '(delete)'}
          </span>
        </div>

        <div className="flex items-center space-x-1.5">
          <button
            onClick={() => onAccept(issue)}
            className="inline-flex items-center space-x-1 px-3 py-1 rounded-lg bg-sayn-dark-accent text-black font-bold text-xs hover:brightness-110 shadow-sm transition-all"
          >
            <Check className="w-3 h-3 stroke-[2.5]" />
            <span>Accept</span>
          </button>
        </div>
      </div>
    </div>
  );
};
