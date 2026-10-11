import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bookmark, Plus, Trash2, ArrowRight, Edit2, Check, X } from 'lucide-react';
import { SavedPrompt } from '@sayn/shared-types';

export const SavedPromptsPage: React.FC = () => {
  const navigate = useNavigate();
  const [prompts, setPrompts] = useState<SavedPrompt[]>([]);
  const [isAdding, setIsAdding] = useState(false);
  const [newName, setNewName] = useState('');
  const [newInstruction, setNewInstruction] = useState('');

  useEffect(() => {
    const saved = localStorage.getItem('sayn-saved-prompts');
    if (saved) {
      try {
        setPrompts(JSON.parse(saved));
      } catch {
        setPrompts([]);
      }
    } else {
      // Sensible initial defaults
      const defaults: SavedPrompt[] = [
        {
          id: '1',
          user_id: 'default',
          name: 'Polite Engineering Slack',
          instruction: 'Rewrite as a concise, friendly Slack message for an engineering team channel.',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
        {
          id: '2',
          user_id: 'default',
          name: 'Executive Investor Update',
          instruction: 'Frame as a formal, high-impact monthly update for seed investors with bolded metrics.',
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        },
      ];
      setPrompts(defaults);
      localStorage.setItem('sayn-saved-prompts', JSON.stringify(defaults));
    }
  }, []);

  const handleSavePrompt = () => {
    if (!newName.trim() || !newInstruction.trim()) return;

    const newPrompt: SavedPrompt = {
      id: Date.now().toString(),
      user_id: 'local',
      name: newName.trim(),
      instruction: newInstruction.trim(),
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    const updated = [newPrompt, ...prompts];
    setPrompts(updated);
    localStorage.setItem('sayn-saved-prompts', JSON.stringify(updated));
    setNewName('');
    setNewInstruction('');
    setIsAdding(false);
  };

  const handleDelete = (id: string) => {
    const updated = prompts.filter((p) => p.id !== id);
    setPrompts(updated);
    localStorage.setItem('sayn-saved-prompts', JSON.stringify(updated));
  };

  const handleUsePrompt = (instruction: string) => {
    sessionStorage.setItem('sayn-active-custom-prompt', instruction);
    navigate('/workspace');
  };

  return (
    <div className="flex-1 max-w-5xl mx-auto w-full px-4 sm:px-6 lg:px-8 py-8">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center space-x-2">
            <Bookmark className="w-5 h-5 text-sayn-dark-accent" />
            <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-sayn-dark-text">
              Saved Prompts
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-sayn-dark-secondary mt-1">
            Store bespoke instructions for consistent, repeatable AI writing refinement.
          </p>
        </div>

        <button
          onClick={() => setIsAdding(true)}
          className="inline-flex items-center space-x-1.5 px-3.5 py-2 rounded-ios-sm text-xs font-semibold text-white bg-sayn-dark-accent hover:opacity-90 transition-all self-start sm:self-auto shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>New Prompt</span>
        </button>
      </div>

      {/* Add Prompt Modal / Card */}
      {isAdding && (
        <div className="mb-6 p-5 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider space-y-4 animate-in fade-in duration-150">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-sayn-dark-text">Create Saved Prompt</h3>
            <button
              onClick={() => setIsAdding(false)}
              className="text-sayn-dark-secondary hover:text-sayn-dark-text"
            >
              <X className="w-4 h-4" />
            </button>
          </div>

          <div className="space-y-3 text-xs">
            <div>
              <label className="block font-semibold uppercase tracking-wider text-sayn-dark-muted mb-1">
                Prompt Name
              </label>
              <input
                type="text"
                value={newName}
                onChange={(e) => setNewName(e.target.value)}
                placeholder="e.g., Executive Email or Recruiter Outreach"
                className="w-full px-3 py-2 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text placeholder:text-sayn-dark-muted focus:outline-none focus:border-sayn-dark-accent"
              />
            </div>

            <div>
              <label className="block font-semibold uppercase tracking-wider text-sayn-dark-muted mb-1">
                Instruction
              </label>
              <textarea
                value={newInstruction}
                onChange={(e) => setNewInstruction(e.target.value)}
                placeholder="Explain exactly how SAYN should transform text using this prompt..."
                rows={3}
                className="w-full p-3 rounded-ios-sm bg-sayn-dark-surface2 border border-sayn-dark-divider text-sayn-dark-text placeholder:text-sayn-dark-muted focus:outline-none focus:border-sayn-dark-accent"
              />
            </div>
          </div>

          <div className="flex items-center justify-end space-x-2 pt-2">
            <button
              onClick={() => setIsAdding(false)}
              className="px-3 py-1.5 rounded-ios-sm text-xs text-sayn-dark-secondary hover:text-sayn-dark-text"
            >
              Cancel
            </button>
            <button
              onClick={handleSavePrompt}
              disabled={!newName.trim() || !newInstruction.trim()}
              className="px-4 py-1.5 rounded-ios-sm text-xs font-semibold text-white bg-sayn-dark-accent hover:opacity-90 disabled:opacity-40"
            >
              Save Prompt
            </button>
          </div>
        </div>
      )}

      {/* Prompts Grid */}
      {prompts.length === 0 ? (
        <div className="p-12 text-center rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider">
          <Bookmark className="w-10 h-10 text-sayn-dark-muted mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-sayn-dark-text mb-1">No saved prompts yet</h3>
          <p className="text-xs text-sayn-dark-secondary max-w-sm mx-auto mb-4">
            Save custom refinement instructions to easily apply them to any text.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {prompts.map((p) => (
            <div
              key={p.id}
              className="p-5 rounded-ios bg-sayn-dark-surface border border-sayn-dark-divider hover:border-sayn-dark-muted transition-colors flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-semibold text-sm text-sayn-dark-text">{p.name}</h3>
                  <button
                    onClick={() => handleDelete(p.id)}
                    className="text-sayn-dark-muted hover:text-sayn-dark-error transition-colors"
                    title="Delete prompt"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
                <p className="text-xs text-sayn-dark-secondary leading-relaxed mb-4">
                  {p.instruction}
                </p>
              </div>

              <div className="pt-3 border-t border-sayn-dark-divider flex items-center justify-between">
                <span className="text-[10px] text-sayn-dark-muted">
                  {new Date(p.created_at).toLocaleDateString()}
                </span>
                <button
                  onClick={() => handleUsePrompt(p.instruction)}
                  className="inline-flex items-center space-x-1 text-xs font-medium text-sayn-dark-accent hover:underline"
                >
                  <span>Apply in Workspace</span>
                  <ArrowRight className="w-3 h-3" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
