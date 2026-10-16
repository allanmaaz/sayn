import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext.js';
import {
  ArrowRight,
  AlertCircle,
  Lock,
  Mail,
  Phone,
  Sparkles,
  CheckCircle2,
  Code,
  Briefcase,
  BookOpen,
  PenTool,
  Check,
  ChevronDown
} from 'lucide-react';
import saynLogo from '../../assets/logo.png';

const COUNTRY_CODES = [
  { code: '+91', country: 'India', flag: '🇮🇳' },
  { code: '+1', country: 'US / Canada', flag: '🇺🇸' },
  { code: '+44', country: 'United Kingdom', flag: '🇬🇧' },
  { code: '+971', country: 'UAE', flag: '🇦🇪' },
  { code: '+966', country: 'Saudi Arabia', flag: '🇸🇦' },
  { code: '+61', country: 'Australia', flag: '🇦🇺' },
  { code: '+49', country: 'Germany', flag: '🇩🇪' },
  { code: '+65', country: 'Singapore', flag: '🇸🇬' },
];

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { signIn, signInWithPhone, verifyPhoneOtp, updateUserProfile } = useAuth();

  // Mode: phone vs email
  const [authMethod, setAuthMethod] = useState<'phone' | 'email'>('phone');

  // Phone Auth State
  const [countryCode, setCountryCode] = useState('+91');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [otpDigits, setOtpDigits] = useState(['', '', '', '', '', '']);
  const [demoCodeNotice, setDemoCodeNotice] = useState<string | null>(null);
  const [resendCountdown, setResendCountdown] = useState(45);

  // Email Auth State
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  // Personalization State
  const [showPersonalization, setShowPersonalization] = useState(false);
  const [fullName, setFullName] = useState('Mohammed Maaz');
  const [selectedRole, setSelectedRole] = useState('Code & Tech');
  const [selectedStyle, setSelectedStyle] = useState('Natural Flow');

  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  // OTP Input Refs for auto-focus
  const otpRefs = useRef<(HTMLInputElement | null)[]>([]);

  useEffect(() => {
    let timer: any;
    if (otpSent && resendCountdown > 0) {
      timer = setInterval(() => setResendCountdown(prev => prev - 1), 1000);
    }
    return () => clearInterval(timer);
  }, [otpSent, resendCountdown]);

  // Step 1: Send OTP
  const handleSendOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const fullPhone = `${countryCode}${phoneNumber.replace(/\D/g, '')}`;
    try {
      const { error: sendError, demoOtp } = await signInWithPhone(fullPhone);
      if (sendError) {
        setError(sendError);
      } else {
        setOtpSent(true);
        setDemoCodeNotice(demoOtp || '123456');
        setResendCountdown(45);
        setTimeout(() => otpRefs.current[0]?.focus(), 100);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to send verification code');
    } finally {
      setLoading(false);
    }
  };

  // Step 2: Handle OTP Digit Change & Auto-Advance
  const handleDigitChange = (index: number, val: string) => {
    const char = val.slice(-1);
    const newDigits = [...otpDigits];
    newDigits[index] = char;
    setOtpDigits(newDigits);

    if (char && index < 5) {
      otpRefs.current[index + 1]?.focus();
    }
  };

  const handleDigitKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otpDigits[index] && index > 0) {
      otpRefs.current[index - 1]?.focus();
    }
  };

  const handleDigitPaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
    e.preventDefault();
    const paste = e.clipboardData.getData('text').trim();
    if (/^\d{6}$/.test(paste)) {
      const digits = paste.split('');
      setOtpDigits(digits);
      otpRefs.current[5]?.focus();
    }
  };

  // Step 3: Verify OTP
  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const token = otpDigits.join('');
    if (token.length < 6) {
      setError('Please enter all 6 digits of your verification code.');
      return;
    }

    setLoading(true);
    const fullPhone = `${countryCode}${phoneNumber.replace(/\D/g, '')}`;

    try {
      const { error: verifyError, isNewUser } = await verifyPhoneOtp(fullPhone, token);
      if (verifyError) {
        setError(verifyError);
      } else {
        // Show Personalization Step so user customizes their experience!
        setShowPersonalization(true);
      }
    } catch (err: any) {
      setError(err.message || 'Verification failed');
    } finally {
      setLoading(false);
    }
  };

  // Step 4: Complete Personalization
  const handleCompletePersonalization = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      await updateUserProfile({
        name: fullName.trim() || 'Mohammed',
        displayName: fullName.trim() || 'Mohammed',
        role: selectedRole,
        preferredStyle: selectedStyle,
      });
      navigate('/workspace');
    } catch (err: any) {
      setError(err.message || 'Failed to save personalization preferences');
    } finally {
      setLoading(false);
    }
  };

  // Fallback: Email Login
  const handleEmailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    try {
      const { error: signInError } = await signIn(email, password);
      if (signInError) {
        setError(signInError);
      } else {
        navigate('/workspace');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to sign in');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex-1 flex items-center justify-center p-4 bg-[#FAF9F5] min-h-screen select-none">
      <div className="w-full max-w-md p-8 rounded-3xl bg-white border border-[#EBE8DF] shadow-2xl transition-all">
        {/* Brand Header */}
        <div className="text-center mb-6">
          <div className="inline-flex items-center justify-center w-12 h-12 rounded-2xl bg-[#0D3832] text-white font-bold text-lg mb-3 shadow-md">
            ||||
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-[#1A1A1A]">
            {showPersonalization
              ? 'Personalize Your Flow'
              : 'Sign in to SAYN'}
          </h1>
          <p className="text-xs text-[#706E6B] mt-1">
            {showPersonalization
              ? 'Tailor speech styles, vocabulary, and shortcuts to your workflow.'
              : 'Don’t type, just speak. Works anywhere you write.'}
          </p>
        </div>

        {error && (
          <div className="mb-4 p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-600 flex items-start space-x-2">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        {/* STEP 3: PERSONALIZATION SCREEN */}
        {showPersonalization ? (
          <form onSubmit={handleCompletePersonalization} className="space-y-5">
            {/* Display Name */}
            <div>
              <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                What should SAYN call you?
              </label>
              <input
                type="text"
                required
                value={fullName}
                onChange={e => setFullName(e.target.value)}
                placeholder="Mohammed Maaz"
                className="w-full px-3.5 py-2.5 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-sm text-[#1A1A1A] focus:outline-hidden focus:border-[#0D3832]"
              />
            </div>

            {/* What do you write most? */}
            <div>
              <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                What is your primary writing focus?
              </label>
              <div className="grid grid-cols-2 gap-2">
                {[
                  { id: 'Code & Tech', label: 'Code & Tech', icon: Code, desc: 'Terminal, Git, PRs' },
                  { id: 'Work & Comms', label: 'Work & Comms', icon: Briefcase, desc: 'Slack, Gmail, Docs' },
                  { id: 'Study & Notes', label: 'Study & Notes', icon: BookOpen, desc: 'Research & Summaries' },
                  { id: 'Creative', label: 'Creative', icon: PenTool, desc: 'Ideas & Brain dumps' },
                ].map(r => {
                  const Icon = r.icon;
                  const isSelected = selectedRole === r.id;
                  return (
                    <button
                      type="button"
                      key={r.id}
                      onClick={() => setSelectedRole(r.id)}
                      className={`p-3 rounded-xl border text-left transition-all ${
                        isSelected
                          ? 'border-[#0D3832] bg-[#0D3832]/5 text-[#0D3832]'
                          : 'border-[#EBE8DF] bg-[#FAF9F5] text-[#706E6B] hover:border-[#D6D2C4]'
                      }`}
                    >
                      <Icon className="w-4 h-4 mb-1.5" />
                      <p className="text-xs font-bold text-[#1A1A1A]">{r.label}</p>
                      <p className="text-[10px] text-[#706E6B]">{r.desc}</p>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Preferred Speaking Style */}
            <div>
              <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                Default Speaking Style
              </label>
              <div className="space-y-1.5">
                {[
                  { id: 'Natural Flow', title: '🌊 Natural Flow', desc: 'Smooth human phrasing, zero filler words' },
                  { id: 'Direct & Concise', title: '⚡ Direct & Concise', desc: 'Fast, compact, cuts fluff automatically' },
                  { id: 'Executive Formal', title: '👔 Executive Formal', desc: 'Polished corporate tone with complete sentences' },
                ].map(s => {
                  const isSelected = selectedStyle === s.id;
                  return (
                    <div
                      key={s.id}
                      onClick={() => setSelectedStyle(s.id)}
                      className={`p-2.5 rounded-xl border cursor-pointer flex items-center justify-between transition-all ${
                        isSelected
                          ? 'border-[#0D3832] bg-[#0D3832]/5'
                          : 'border-[#EBE8DF] bg-[#FAF9F5] hover:border-[#D6D2C4]'
                      }`}
                    >
                      <div>
                        <p className="text-xs font-bold text-[#1A1A1A]">{s.title}</p>
                        <p className="text-[10px] text-[#706E6B]">{s.desc}</p>
                      </div>
                      {isSelected && <Check className="w-4 h-4 text-[#0D3832]" />}
                    </div>
                  );
                })}
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 rounded-xl text-sm font-semibold text-white bg-[#0D3832] hover:bg-[#144D45] active:scale-[0.99] disabled:opacity-50 transition-all flex items-center justify-center space-x-2 shadow-md"
            >
              <span>Complete Personalization & Launch</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>
        ) : (
          <>
            {/* Auth Method Switcher */}
            <div className="flex p-1 rounded-2xl bg-[#F0EDE4] mb-6">
              <button
                type="button"
                onClick={() => {
                  setAuthMethod('phone');
                  setError(null);
                }}
                className={`flex-1 py-1.5 rounded-xl text-xs font-semibold flex items-center justify-center space-x-1.5 transition-all ${
                  authMethod === 'phone'
                    ? 'bg-white text-[#1A1A1A] shadow-xs'
                    : 'text-[#706E6B] hover:text-[#1A1A1A]'
                }`}
              >
                <Phone className="w-3.5 h-3.5" />
                <span>Phone Number</span>
              </button>
              <button
                type="button"
                onClick={() => {
                  setAuthMethod('email');
                  setError(null);
                }}
                className={`flex-1 py-1.5 rounded-xl text-xs font-semibold flex items-center justify-center space-x-1.5 transition-all ${
                  authMethod === 'email'
                    ? 'bg-white text-[#1A1A1A] shadow-xs'
                    : 'text-[#706E6B] hover:text-[#1A1A1A]'
                }`}
              >
                <Mail className="w-3.5 h-3.5" />
                <span>Email Address</span>
              </button>
            </div>

            {/* PHONE NUMBER LOGIN FLOW */}
            {authMethod === 'phone' && (
              <>
                {!otpSent ? (
                  <form onSubmit={handleSendOtp} className="space-y-4">
                    <div>
                      <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                        Enter your mobile number
                      </label>
                      <div className="flex space-x-2">
                        {/* Country Code Picker */}
                        <div className="relative shrink-0">
                          <select
                            value={countryCode}
                            onChange={e => setCountryCode(e.target.value)}
                            className="appearance-none pl-3 pr-7 py-2.5 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-xs font-medium text-[#1A1A1A] focus:outline-hidden focus:border-[#0D3832]"
                          >
                            {COUNTRY_CODES.map(c => (
                              <option key={c.code} value={c.code}>
                                {c.flag} {c.code}
                              </option>
                            ))}
                          </select>
                          <ChevronDown className="w-3 h-3 text-[#706E6B] absolute right-2.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                        </div>

                        {/* Phone Number */}
                        <input
                          type="tel"
                          required
                          value={phoneNumber}
                          onChange={e => setPhoneNumber(e.target.value)}
                          placeholder="98765 43210"
                          className="flex-1 px-3.5 py-2.5 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-sm text-[#1A1A1A] focus:outline-hidden focus:border-[#0D3832]"
                        />
                      </div>
                    </div>

                    <button
                      type="submit"
                      disabled={loading || phoneNumber.trim().length < 5}
                      className="w-full py-3 rounded-xl text-sm font-semibold text-white bg-[#0D3832] hover:bg-[#144D45] active:scale-[0.99] disabled:opacity-50 transition-all flex items-center justify-center space-x-2 shadow-md"
                    >
                      {loading ? (
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      ) : (
                        <>
                          <span>Send Verification Code</span>
                          <ArrowRight className="w-4 h-4" />
                        </>
                      )}
                    </button>
                  </form>
                ) : (
                  <form onSubmit={handleVerifyOtp} className="space-y-5">
                    <div>
                      <div className="flex items-center justify-between mb-2">
                        <label className="text-xs font-bold text-[#1A1A1A]">
                          Enter 6-digit code sent to {countryCode} {phoneNumber}
                        </label>
                        <button
                          type="button"
                          onClick={() => setOtpSent(false)}
                          className="text-[11px] text-[#0D3832] hover:underline font-semibold"
                        >
                          Change
                        </button>
                      </div>

                      {/* 6 Digit Inputs */}
                      <div className="flex justify-between gap-2" onPaste={handleDigitPaste}>
                        {otpDigits.map((digit, i) => (
                          <input
                            key={i}
                            ref={el => (otpRefs.current[i] = el)}
                            type="text"
                            inputMode="numeric"
                            maxLength={1}
                            value={digit}
                            onChange={e => handleDigitChange(i, e.target.value)}
                            onKeyDown={e => handleDigitKeyDown(i, e)}
                            className="w-11 h-12 text-center text-lg font-bold rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] focus:border-[#0D3832] focus:bg-white focus:outline-hidden transition"
                          />
                        ))}
                      </div>

                      {/* Instant Testing Helper Notice */}
                      {demoCodeNotice && (
                        <div className="mt-3 p-2.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-xs text-amber-900 flex items-center justify-between">
                          <span>Demo verification code: <strong>{demoCodeNotice}</strong></span>
                          <button
                            type="button"
                            onClick={() => {
                              setOtpDigits(demoCodeNotice.split(''));
                              otpRefs.current[5]?.focus();
                            }}
                            className="text-[11px] font-bold text-amber-950 underline hover:no-underline"
                          >
                            Fill in
                          </button>
                        </div>
                      )}
                    </div>

                    <button
                      type="submit"
                      disabled={loading || otpDigits.join('').length < 6}
                      className="w-full py-3 rounded-xl text-sm font-semibold text-white bg-[#0D3832] hover:bg-[#144D45] active:scale-[0.99] disabled:opacity-50 transition-all flex items-center justify-center space-x-2 shadow-md"
                    >
                      {loading ? (
                        <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      ) : (
                        <>
                          <span>Verify & Personalize</span>
                          <ArrowRight className="w-4 h-4" />
                        </>
                      )}
                    </button>

                    <div className="text-center text-xs text-[#706E6B]">
                      {resendCountdown > 0 ? (
                        <span>Resend code in {resendCountdown}s</span>
                      ) : (
                        <button
                          type="button"
                          onClick={handleSendOtp}
                          className="text-[#0D3832] font-semibold hover:underline"
                        >
                          Resend verification code
                        </button>
                      )}
                    </div>
                  </form>
                )}
              </>
            )}

            {/* EMAIL LOGIN FLOW */}
            {authMethod === 'email' && (
              <form onSubmit={handleEmailSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    Email Address
                  </label>
                  <div className="relative">
                    <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#706E6B]" />
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={e => setEmail(e.target.value)}
                      placeholder="name@example.com"
                      className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-sm text-[#1A1A1A] focus:outline-hidden focus:border-[#0D3832]"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-[#1A1A1A] mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <Lock className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-[#706E6B]" />
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={e => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className="w-full pl-9 pr-3.5 py-2.5 rounded-xl bg-[#FAF9F5] border border-[#EBE8DF] text-sm text-[#1A1A1A] focus:outline-hidden focus:border-[#0D3832]"
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 rounded-xl text-sm font-semibold text-white bg-[#0D3832] hover:bg-[#144D45] active:scale-[0.99] disabled:opacity-50 transition-all flex items-center justify-center space-x-2 shadow-md"
                >
                  {loading ? (
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  ) : (
                    <>
                      <span>Sign In</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>
            )}

            <div className="mt-6 text-center text-xs text-[#706E6B]">
              New to SAYN?{' '}
              <button
                type="button"
                onClick={() => setAuthMethod('phone')}
                className="text-[#0D3832] hover:underline font-bold"
              >
                Sign in with phone number
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
};
