# SAYN — Supabase Setup & Security Guide

SAYN utilizes Supabase for authentication, user profiles, preferences, writing history, and usage analytics with PostgreSQL Row Level Security (RLS).

## 1. Quick Setup Options

### Option A: Via Supabase Web Dashboard
1. Create a project at [supabase.com](https://supabase.com).
2. Go to the **SQL Editor**.
3. Run the migrations in order:
   - `supabase/migrations/20261011000001_initial_schema.sql`
   - `supabase/migrations/20261011000002_rls_policies.sql`
4. Copy your **Project URL** and **Anon Public Key** from **Project Settings → API**.

### Option B: Via Supabase CLI
```bash
# Log in to your account
npx supabase login

# Link your local repo to the remote project
npx supabase link --project-ref your-project-id

# Push migrations to the database
npx supabase db push
```

## 2. Security Architecture

- **Row Level Security (RLS)** is enabled on all tables:
  - `profiles`: Users can only read and update their own profile record.
  - `user_preferences`: Users can only view and update their own preferences.
  - `writing_history`: History entries are only stored if the user has history enabled. Accessible only by the owning user.
  - `saved_prompts`: Private to each individual user.
  - `usage_events`: Insertable only by privileged backend services (Cloudflare Worker via Service Role Key). Users have read-only access to their own events for quota display.

- **Automated Profile Trigger:** When a user registers through Supabase Auth, the PostgreSQL trigger `handle_new_user()` automatically initializes a linked record in `profiles` and default values in `user_preferences`.
