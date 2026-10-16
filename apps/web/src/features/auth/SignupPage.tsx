import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.js';
import { ArrowRight, AlertCircle, Lock, Mail, User } from 'lucide-react';
import saynLogo from '../../assets/logo.png';

export const SignupPage: React.FC = () => {
  const navigate = useNavigate();
  const { signUp } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const { error: signUpError } = await signUp(email, password);
      if (signUpError) {
        setError(signUpError);
      } else {
        navigate('/workspace');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to sign up');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center p-4">
      <div className="w-full max-w-md p-8 rounded-ios bg-sayn-dark-surface dark:bg-sayn-dark-surface light:bg-sayn-light-surface border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider shadow-xl transition-colors">
        <div className="text-center mb-8">
          <img src={saynLogo} alt="SAYN" className="w-10 h-10 mx-auto rounded-lg mb-3" />
          <h1 className="text-2xl font-bold tracking-tight text-sayn-dark-text dark:text-sayn-dark-text light:text-sayn-light-text">
            Create your SAYN account
          </h1>
          <p className="text-xs text-sayn-dark-secondary dark:text-sayn-dark-secondary light:text-sayn-light-secondary mt-1">
            Say it. Refine it. Send it.
          </p>
        </div>

        {error && (
          <div className="mb-4 p-3 rounded-ios-sm bg-sayn-dark-error/10 border border-sayn-dark-error/30 text-xs text-sayn-dark-error flex items-start space-x-2">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-sayn-dark-muted" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full pl-9 pr-3 py-2 rounded-ios-sm bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-sm text-sayn-dark-text focus:outline-none focus:border-sayn-dark-accent"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold uppercase tracking-wider text-sayn-dark-muted dark:text-sayn-dark-muted light:text-sayn-light-muted mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-sayn-dark-muted" />
              <input
                type="password"
                required
                minLength={6}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Minimum 6 characters"
                className="w-full pl-9 pr-3 py-2 rounded-ios-sm bg-sayn-dark-surface2 dark:bg-sayn-dark-surface2 light:bg-sayn-light-surface2 border border-sayn-dark-divider dark:border-sayn-dark-divider light:border-sayn-light-divider text-sm text-sayn-dark-text focus:outline-none focus:border-sayn-dark-accent"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2.5 rounded-ios-sm text-sm font-semibold text-white bg-sayn-dark-accent hover:opacity-90 active:scale-[0.99] disabled:opacity-50 transition-all flex items-center justify-center space-x-2 shadow-sm"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <span>Get Started</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="mt-6 text-center text-xs text-sayn-dark-secondary">
          Already have an account?{' '}
          <Link to="/login" className="text-sayn-dark-accent hover:underline font-medium">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
};
