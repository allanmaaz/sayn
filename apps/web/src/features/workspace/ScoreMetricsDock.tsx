import React from 'react';
import { DocumentScoreMetrics } from '@sayn/shared-types';
import { Clock, BookOpen, AlertCircle, Compass, Sparkles, ShieldCheck, Gauge } from 'lucide-react';

interface ScoreMetricsDockProps {
  metrics: DocumentScoreMetrics;
}

export const ScoreMetricsDock: React.FC<ScoreMetricsDockProps> = ({ metrics }) => {
  const getScoreColor = (score: number) => {
    if (score >= 85) return 'text-sayn-dark-accent border-sayn-dark-accent';
    if (score >= 70) return 'text-amber-400 border-amber-400';
    return 'text-rose-400 border-rose-400';
  };

  return (
    <div className="p-4 rounded-2xl bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider glass-obsidian shadow-xl">
      <div className="flex flex-col lg:flex-row items-center justify-between gap-6">
        {/* Left: Overall Performance Circle & Grade Level */}
        <div className="flex items-center space-x-4 w-full lg:w-auto">
          <div
            className={`w-14 h-14 rounded-full border-2 flex flex-col items-center justify-center font-bold shadow-inner ${getScoreColor(
              metrics.overallScore
            )}`}
          >
            <span className="text-xl leading-none">{metrics.overallScore}</span>
            <span className="text-[9px] font-semibold tracking-wider text-sayn-dark-muted">SCORE</span>
          </div>

          <div>
            <div className="flex items-center space-x-1.5">
              <Gauge className="w-3.5 h-3.5 text-sayn-dark-accent" />
              <h4 className="text-xs font-bold text-sayn-dark-text tracking-wide uppercase">
                Writing Performance
              </h4>
            </div>
            <p className="text-xs text-sayn-dark-secondary mt-0.5">
              Level: <span className="font-semibold text-sayn-dark-text">{metrics.gradeLevel}</span> • Ease:{' '}
              <span className="font-semibold text-sayn-dark-accent">{metrics.readabilityScore}/100</span>
            </p>
          </div>
        </div>

        {/* Center: Issue Breakdown Pillars */}
        <div className="flex items-center gap-3 overflow-x-auto w-full lg:w-auto py-1">
          <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-red-500/10 border border-red-500/20 text-xs text-red-400 whitespace-nowrap">
            <AlertCircle className="w-3.5 h-3.5" />
            <span className="font-semibold">Correctness:</span>
            <span className="font-bold">{metrics.issuesCount.correctness}</span>
          </div>

          <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-blue-500/10 border border-blue-500/20 text-xs text-blue-400 whitespace-nowrap">
            <Compass className="w-3.5 h-3.5" />
            <span className="font-semibold">Clarity:</span>
            <span className="font-bold">{metrics.issuesCount.clarity}</span>
          </div>

          <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-xs text-emerald-400 whitespace-nowrap">
            <Sparkles className="w-3.5 h-3.5" />
            <span className="font-semibold">Engagement:</span>
            <span className="font-bold">{metrics.issuesCount.engagement}</span>
          </div>

          <div className="flex items-center space-x-1.5 px-3 py-1.5 rounded-xl bg-purple-500/10 border border-purple-500/20 text-xs text-purple-400 whitespace-nowrap">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span className="font-semibold">Delivery:</span>
            <span className="font-bold">{metrics.issuesCount.delivery}</span>
          </div>
        </div>

        {/* Right: Document Quick Stats */}
        <div className="flex items-center space-x-5 text-xs text-sayn-dark-muted border-t lg:border-t-0 lg:border-l border-sayn-dark-divider pt-3 lg:pt-0 lg:pl-6 w-full lg:w-auto justify-between lg:justify-end">
          <div className="flex items-center space-x-1.5">
            <BookOpen className="w-3.5 h-3.5" />
            <span>
              <strong className="text-sayn-dark-text font-bold">{metrics.wordCount}</strong> words
            </span>
          </div>

          <div className="flex items-center space-x-1.5">
            <Clock className="w-3.5 h-3.5" />
            <span>
              <strong className="text-sayn-dark-text font-bold">{metrics.readingTimeMinutes}</strong> min read
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
