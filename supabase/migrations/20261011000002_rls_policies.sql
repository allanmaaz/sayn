-- Migration: 20261011000002_rls_policies.sql
-- Description: Applies Row Level Security (RLS) policies to ensure strict tenant data isolation

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.writing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_prompts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_events ENABLE ROW LEVEL SECURITY;

-- 1. PROFILES POLICIES
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- 2. USER PREFERENCES POLICIES
CREATE POLICY "Users can view own preferences"
    ON public.user_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
    ON public.user_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
    ON public.user_preferences FOR UPDATE
    USING (auth.uid() = user_id);

-- 3. WRITING HISTORY POLICIES
CREATE POLICY "Users can view own writing history"
    ON public.writing_history FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own writing history"
    ON public.writing_history FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own writing history"
    ON public.writing_history FOR DELETE
    USING (auth.uid() = user_id);

-- 4. SAVED PROMPTS POLICIES
CREATE POLICY "Users can view own saved prompts"
    ON public.saved_prompts FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own saved prompts"
    ON public.saved_prompts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own saved prompts"
    ON public.saved_prompts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own saved prompts"
    ON public.saved_prompts FOR DELETE
    USING (auth.uid() = user_id);

-- 5. USAGE EVENTS POLICIES
-- Users can inspect their own usage records for transparency
CREATE POLICY "Users can view own usage events"
    ON public.usage_events FOR SELECT
    USING (auth.uid() = user_id);

-- Only service role can insert or modify trusted usage events
-- No direct client insert policy for public/authenticated role on usage_events
