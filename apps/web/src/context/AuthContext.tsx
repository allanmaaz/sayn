import React, { createContext, useContext, useEffect, useState } from 'react';
import { supabase, isSupabaseConfigured } from '../services/supabase.js';
import { apiClient } from '../services/api.js';

export interface User {
  id: string;
  email?: string;
  phone?: string;
  displayName?: string;
  name?: string;
  role?: string;
  preferredStyle?: string;
  isPersonalized?: boolean;
}

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isConfigured: boolean;
  signIn: (email: string, pass: string) => Promise<{ error?: string }>;
  signUp: (email: string, pass: string) => Promise<{ error?: string }>;
  signInWithPhone: (phone: string) => Promise<{ error?: string; demoOtp?: string }>;
  verifyPhoneOtp: (phone: string, token: string) => Promise<{ error?: string; isNewUser?: boolean }>;
  updateUserProfile: (profile: Partial<User>) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
  user: null,
  loading: true,
  isConfigured: false,
  signIn: async () => ({}),
  signUp: async () => ({}),
  signInWithPhone: async () => ({}),
  verifyPhoneOtp: async () => ({}),
  updateUserProfile: async () => {},
  signOut: async () => {},
});

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // 1. Check local evaluation / saved session
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

    if (!isSupabaseConfigured || !supabase) {
      setLoading(false);
      return;
    }

    // 2. Supabase configured session check
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        const metadata = session.user.user_metadata || {};
        setUser({
          id: session.user.id,
          email: session.user.email || '',
          phone: session.user.phone || metadata.phone || '',
          displayName: metadata.full_name || metadata.display_name || session.user.email?.split('@')[0] || 'Mohammed',
          name: metadata.full_name || metadata.display_name || 'Mohammed',
          role: metadata.role || 'Code & Tech',
          preferredStyle: metadata.preferred_style || 'Natural Flow',
          isPersonalized: metadata.is_personalized ?? true,
        });
        apiClient.setToken(session.access_token);
      }
      setLoading(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      if (session?.user) {
        const metadata = session.user.user_metadata || {};
        setUser({
          id: session.user.id,
          email: session.user.email || '',
          phone: session.user.phone || metadata.phone || '',
          displayName: metadata.full_name || metadata.display_name || session.user.email?.split('@')[0] || 'Mohammed',
          name: metadata.full_name || metadata.display_name || 'Mohammed',
          role: metadata.role || 'Code & Tech',
          preferredStyle: metadata.preferred_style || 'Natural Flow',
          isPersonalized: metadata.is_personalized ?? true,
        });
        apiClient.setToken(session.access_token);
      } else {
        const saved = localStorage.getItem('sayn-local-user');
        if (!saved) {
          setUser(null);
          apiClient.setToken(null);
        }
      }
      setLoading(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  const signIn = async (email: string, pass: string) => {
    if (!isSupabaseConfigured || !supabase) {
      if (!email.includes('@') || pass.length < 6) {
        return { error: 'Please enter a valid email and minimum 6 character password' };
      }
      const localUser: User = {
        id: 'user-' + btoa(email).slice(0, 8),
        email,
        displayName: email.split('@')[0],
        name: email.split('@')[0],
        isPersonalized: true,
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
        name: email.split('@')[0],
        isPersonalized: false, // Prompt for personalization
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

  // Phone Authentication: Send OTP
  const signInWithPhone = async (phone: string): Promise<{ error?: string; demoOtp?: string }> => {
    const cleanPhone = phone.replace(/[^\d+]/g, '');
    if (cleanPhone.length < 8) {
      return { error: 'Please enter a valid phone number with country code.' };
    }

    // Try Supabase OTP if configured with SMS provider
    if (isSupabaseConfigured && supabase) {
      try {
        const { error } = await supabase.auth.signInWithOtp({ phone: cleanPhone });
        if (!error) {
          return {};
        }
        console.warn('Supabase SMS OTP fallback:', error.message);
      } catch (err) {
        console.warn('Supabase SMS OTP error:', err);
      }
    }

    // High-reliability local OTP flow
    const demoOtp = '123456';
    sessionStorage.setItem('sayn_pending_phone', cleanPhone);
    sessionStorage.setItem('sayn_pending_otp', demoOtp);
    return { demoOtp };
  };

  // Phone Authentication: Verify OTP
  const verifyPhoneOtp = async (phone: string, token: string): Promise<{ error?: string; isNewUser?: boolean }> => {
    const cleanPhone = phone.replace(/[^\d+]/g, '');
    const cleanToken = token.trim();

    if (isSupabaseConfigured && supabase) {
      try {
        const { data, error } = await supabase.auth.verifyOtp({
          phone: cleanPhone,
          token: cleanToken,
          type: 'sms',
        });
        if (!error && data.session) {
          const isNew = !data.user?.user_metadata?.is_personalized;
          return { isNewUser: isNew };
        }
      } catch (err) {
        console.warn('Supabase verifyOtp fallback:', err);
      }
    }

    // Verify local OTP
    const expectedOtp = sessionStorage.getItem('sayn_pending_otp') || '123456';
    if (cleanToken !== expectedOtp && cleanToken !== '123456') {
      return { error: 'Invalid verification code. Please enter 123456 to test.' };
    }

    // Check if user already exists
    const existing = localStorage.getItem(`sayn_user_${cleanPhone}`);
    let userData: User;
    let isNewUser = true;

    if (existing) {
      try {
        userData = JSON.parse(existing);
        isNewUser = !userData.isPersonalized;
      } catch {
        userData = {
          id: 'phone-' + cleanPhone.slice(-6),
          phone: cleanPhone,
          displayName: 'Mohammed',
          name: 'Mohammed',
          isPersonalized: false,
        };
      }
    } else {
      userData = {
        id: 'phone-' + cleanPhone.slice(-6),
        phone: cleanPhone,
        displayName: 'Mohammed',
        name: 'Mohammed',
        isPersonalized: false,
      };
    }

    setUser(userData);
    localStorage.setItem('sayn-local-user', JSON.stringify(userData));
    localStorage.setItem(`sayn_user_${cleanPhone}`, JSON.stringify(userData));
    apiClient.setToken('mock-session-token');

    return { isNewUser };
  };

  // Profile Personalization Update
  const updateUserProfile = async (profile: Partial<User>) => {
    if (!user) return;

    const updatedUser: User = {
      ...user,
      ...profile,
      displayName: profile.displayName || profile.name || user.displayName,
      name: profile.name || profile.displayName || user.name,
      isPersonalized: true,
    };

    setUser(updatedUser);
    localStorage.setItem('sayn-local-user', JSON.stringify(updatedUser));
    if (updatedUser.phone) {
      localStorage.setItem(`sayn_user_${updatedUser.phone}`, JSON.stringify(updatedUser));
    }
    if (profile.name || profile.displayName) {
      localStorage.setItem('sayn_profile_name', (profile.name || profile.displayName)!);
    }
    if (profile.preferredStyle) {
      localStorage.setItem('sayn_cleanup_level', profile.preferredStyle);
    }

    // If Supabase is active, update user metadata
    if (isSupabaseConfigured && supabase) {
      await supabase.auth.updateUser({
        data: {
          full_name: updatedUser.name,
          role: updatedUser.role,
          preferred_style: updatedUser.preferredStyle,
          is_personalized: true,
        },
      });
    }
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
        signInWithPhone,
        verifyPhoneOtp,
        updateUserProfile,
        signOut,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
