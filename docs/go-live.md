# Go-Live Strategy

This document describes how to promote the Illinois Farmlink App from development to production: migrations, RLS verification, seeding policy, and rollout steps.

## Principles

- **Migrations are the source of truth**: All schema and RLS changes live in `supabase/migrations/`. Production is updated only via `supabase db push` (or your CI/CD pipeline).
- **No seed in production**: `supabase/seed.sql` is for **local and dev-only** use. Do not run seed against production. Production data comes from real sign-ups and admin actions.
- **RLS is enforced in DB**: Every access path (pending vs approved vs admin) is enforced by Row Level Security. UI and API must not rely on client-side checks alone.

## Pre–go-live checklist

### 1. Migrations

- [ ] All migrations applied and tested locally: `pnpm supabase db reset` (local) and `pnpm db:push` (linked dev/staging).
- [ ] No pending migrations; migration history matches between local and target project.
- [ ] Security advisor clean (Dashboard → Database → Security Advisor). Resolve any function `search_path` or RLS issues.

### 2. RLS verification

- [ ] **Pending user**: Cannot see other users’ contact details; cannot create inquiries; cannot see approved listings (or only limited fields).
- [ ] **Approved farmer**: Can see approved listings; can create inquiries; can send/receive inquiry messages.
- [ ] **Approved landowner**: Can create/edit own listings; can view inquiries on own listings.
- [ ] **Admin**: Can see all profiles (including demographics); can approve/reject users and listings; can suspend users.
- [ ] Demographic fields (farmer_profiles / landowner_profiles) are never selectable by non-admin roles (verify via RLS policies).

Use the project’s **DB tests** (see below) to automate RLS checks where possible.

### 3. Environment and secrets

- [ ] Production Supabase project created (or existing project designated).
- [ ] Production env vars set (e.g. `PUBLIC_SUPABASE_URL`, `PUBLIC_SUPABASE_ANON_KEY`; optional `SUPABASE_SERVICE_ROLE_KEY` for server-only use). No dev or test keys in production.
- [ ] Auth redirect URLs and site URL updated in Supabase Dashboard for production domain.
- [ ] Dev-only routes (`/app/dev/user`, `/api/dev/login-as`) are disabled in production (they check `import.meta.env.DEV` and return 404 when not in dev).

### 4. Seed policy

- **Local**: `supabase db reset` runs `supabase/seed.sql` to create test users and sample data.
- **Hosted dev/staging**: Optional. Either run seed manually once (after creating Auth users) or use a dedicated seed script with known test accounts. Do not rely on production data.
- **Production**: **Do not run seed.** Production starts with empty tables (except migrations). First admin must be created manually (e.g. sign up → then promote to admin in DB: `UPDATE profiles SET role = 'admin', status = 'approved' WHERE id = '<user_id>';`).

## Rollout steps

1. **Create production Supabase project** (if not already).
2. **Link and push migrations**:  
   `pnpm db:link` (with prod project ref in `.env`) then `pnpm db:push`.  
   Or use your CI/CD to run migrations against prod.
3. **Configure production Auth**: Site URL, redirect URLs, email templates as needed.
4. **Deploy app** to production (Astro build + host). Ensure env points to production Supabase.
5. **Create first admin**: Sign up via app (or Dashboard Auth), then run one-time SQL to set role and status:
   ```sql
   UPDATE profiles SET role = 'admin', status = 'approved' WHERE id = '<new_user_uuid>';
   ```
6. **Smoke test**: Log in as admin; approve a test user and listing; verify RLS (e.g. pending cannot see contact details).
7. **Monitor**: Use Supabase Dashboard (logs, Security/Performance Advisors) and app monitoring after go-live.

## DB tests and seeding (dev)

- **DB tests**: Run `pnpm test` (or project test command). Tests should cover critical RLS paths (e.g. anon/pending vs approved vs service role) and basic schema expectations.
- **Dev seeding**: Local dev uses `supabase/seed.sql` on `supabase db reset`. For hosted dev, see “Seed policy” above; do not run seed against production.

## Rollback

- **Schema**: Supabase does not auto-rollback migrations. Rollback is manual: create a new migration that reverts the change (e.g. drop column, drop policy). Prefer forward-only fixes where possible.
- **Data**: Restore from backups (Supabase Dashboard / point-in-time recovery) if a bad migration or script affected data.

## Summary

| Environment   | Migrations        | Seed                    | First admin      |
|---------------|-------------------|-------------------------|------------------|
| Local         | `db reset` / push | `seed.sql` on reset     | From seed        |
| Hosted dev    | `db push`         | Optional manual/script  | Manual or seed   |
| Production    | `db push` only    | **Never**               | Manual SQL once  |
