import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { History, Search, Trash2, Copy, Check, ArrowRight, AlertCircle } from 'lucide-react';
import { WritingHistoryItem } from '@sayn/shared-types';

export const HistoryPage: React.FC = () => {
  const navigate = useNavigate();
  const [history, setHistory] = useState<WritingHistoryItem[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('sayn-history');
    if (saved) {
      try {
        setHistory(JSON.parse(saved));
      } catch {
        setHistory([]);
      }
    }
  }, []);

  const handleCopy = (id: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const handleDelete = (id: string) => {
    const updated = history.filter((item) => item.id !== id);
    setHistory(updated);
    localStorage.setItem('sayn-history', JSON.stringify(updated));
  };

  const handleClearAll = () => {
    if (window.confirm('Are you sure you want to delete all writing history?')) {
      setHistory([]);
      localStorage.removeItem('sayn-history');
    }
  };

  const filtered = history.filter(
    (item) =>
      item.source_text.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.result_text.toLowerCase().includes(searchQuery.toLowerCase()) ||
      item.writing_mode.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex-1 max-w-5xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center space-x-2">
            <History className="w-5 h-5 text-sayn-dark-accent" />
            <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-sayn-dark-text">
              Writing History
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-sayn-dark-secondary mt-1">
            Review past refinements, re-use original text, or delete stored entries.
          </p>
        </div>

        {history.length > 0 && (
          <button
            onClick={handleClearAll}
            className="inline-flex items-center space-x-1.5 px-3 py-1.5 rounded-ios-sm text-xs font-medium text-sayn-dark-error hover:bg-sayn-dark-error/10 border border-sayn-dark-error/30 transition-colors self-start sm:self-auto"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>Clear All History</span>
          </button>
        )}
      </div>

      {/* Search Input */}
      {history.length > 0 && (
        <div className="relative mb-6">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-sayn-dark-muted" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search within past messages, modes, or transcripts..."
            className="w-full pl-10 pr-4 py-2 rounded-ios-sm bg-sayn-dark-surface border border-sayn-dark-divider text-sm text-sayn-dark-text placeholder:text-sayn-dark-muted focus:outline-none focus:border-sayn-dark-accent transition-colors"
          />
        </div>
      )}

      {/* History List or Empty State */}
      {history.length === 0 ? (
        <div className="p-12 text-center rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider">
          <History className="w-10 h-10 text-sayn-dark-muted mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-sayn-dark-text mb-1">No writing history yet</h3>
          <p className="text-xs text-sayn-dark-secondary max-w-sm mx-auto mb-4">
            Sessions you refine in the workspace will appear here if history is enabled in Settings.
          </p>
          <button
            onClick={() => navigate('/workspace')}
            className="inline-flex items-center space-x-1 px-4 py-2 rounded-ios-sm text-xs font-semibold text-white bg-sayn-dark-accent hover:opacity-90"
          >
            <span>Open Workspace</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      ) : filtered.length === 0 ? (
        <div className="p-8 text-center rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider text-xs text-sayn-dark-secondary">
          No matches found for "{searchQuery}".
        </div>
      ) : (
        <div className="space-y-4">
          {filtered.map((item) => (
            <div
              key={item.id}
              className="p-5 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors space-y-3"
            >
              <div className="flex items-center justify-between text-xs">
                <span className="px-2.5 py-0.5 rounded-ios-pill bg-sayn-dark-surface2 text-sayn-dark-accent font-medium uppercase tracking-wider text-[10px]">
                  {item.writing_mode}
                </span>
                <div className="flex items-center space-x-3 text-sayn-dark-muted text-[11px]">
                  <span>{new Date(item.created_at).toLocaleString()}</span>
                  <button
                    onClick={() => handleDelete(item.id)}
                    className="hover:text-sayn-dark-error transition-colors"
                    title="Delete entry"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
                <div className="p-3 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-secondary leading-relaxed">
                  <div className="text-[10px] uppercase font-semibold text-sayn-dark-muted mb-1">
                    Source
                  </div>
                  <p className="line-clamp-4">{item.source_text}</p>
                </div>

                <div className="p-3 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-accent/30 text-sayn-dark-text leading-relaxed">
                  <div className="flex items-center justify-between text-[10px] uppercase font-semibold text-sayn-dark-accent mb-1">
                    <span>Result</span>
                    <button
                      onClick={() => handleCopy(item.id, item.result_text)}
                      className="text-sayn-dark-secondary hover:text-sayn-dark-text"
                    >
                      {copiedId === item.id ? (
                        <Check className="w-3 h-3 text-sayn-dark-success" />
                      ) : (
                        <Copy className="w-3 h-3" />
                      )}
                    </button>
                  </div>
                  <p className="line-clamp-4">{item.result_text}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
