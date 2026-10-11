import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase, isSupabaseConfigured } from '../services/supabase.js';
import { apiClient } from '../services/api.js';

export interface User {
  id: string;
  email: string;
  displayName?: string;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isConfigured: boolean;
  signIn: (email: string, pass: string) => Promise<{ error?: string }>;
  signUp: (email: string, pass: string) => Promise<{ error?: string }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  isConfigured: false,
  signIn: async () => ({}),
  signUp: async () => ({}),
  signOut: async () => {},
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!isSupabaseConfigured || !supabase) {
      // Check if user previously logged in via local evaluation mode
      const savedLocalUser = localStorage.getItem('sayn-local-user');
      if (savedLocalUser) {
        try {
          const parsed = JSON.parse(savedLocalUser);
          setUser(parsed);
          apiClient.setToken('mock-session-token');
        } catch {
          // ignore
        }
      }
      setLoading(false);
      return;
    }

    // Supabase is configured
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        setUser({
          id: session.user.id,
          email: session.user.email || '',
          displayName: session.user.user_metadata?.full_name || session.user.email?.split('@')[0],
        });
        apiClient.setToken(session.access_token);
      }
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session?.user) {
        setUser({
          id: session.user.id,
          email: session.user.email || '',
          displayName: session.user.user_metadata?.full_name || session.user.email?.split('@')[0],
        });
        apiClient.setToken(session.access_token);
      } else {
        setUser(null);
        apiClient.setToken(null);
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, pass: string) => {
    if (!isSupabaseConfigured || !supabase) {
      // Local evaluation mode
      if (!email.includes('@') || pass.length < 6) {
        return { error: 'Please enter a valid email and minimum 6 character password' };
      }
      const localUser: User = {
        id: 'user-' + btoa(email).slice(0, 8),
        email,
        displayName: email.split('@')[0],
      };
      setUser(localUser);
      localStorage.setItem('sayn-local-user', JSON.stringify(localUser));
      apiClient.setToken('mock-session-token');
      return {};
    }

    const { error } = await supabase.auth.signInWithPassword({ email, password: pass });
    if (error) return { error: error.message };
    return {};
  };

  const signUp = async (email: string, pass: string) => {
    if (!isSupabaseConfigured || !supabase) {
      if (!email.includes('@') || pass.length < 6) {
        return { error: 'Please enter a valid email and minimum 6 character password' };
      }
      const localUser: User = {
        id: 'user-' + btoa(email).slice(0, 8),
        email,
        displayName: email.split('@')[0],
      };
      setUser(localUser);
      localStorage.setItem('sayn-local-user', JSON.stringify(localUser));
      apiClient.setToken('mock-session-token');
      return {};
    }

    const { error } = await supabase.auth.signUp({ email, password: pass });
    if (error) return { error: error.message };
    return {};
  };

  const signOut = async () => {
    if (isSupabaseConfigured && supabase) {
      await supabase.auth.signOut();
    }
    setUser(null);
    localStorage.removeItem('sayn-local-user');
    apiClient.setToken(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        isConfigured: isSupabaseConfigured,
        signIn,
        signUp,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
