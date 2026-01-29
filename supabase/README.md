# Supabase Database Setup

This directory contains database migrations for the Illinois Farmlink App.

## Migration Files

1. **20240126000001_initial_schema.sql**
   - Creates all enums (user_role, user_status, listing_status, inquiry_status, media_type)
   - Creates all tables (profiles, farmer_profiles, landowner_profiles, listings, listing_media, inquiries, inquiry_messages)
   - Creates indexes for performance
   - Creates triggers for updated_at timestamps
   - Creates validation functions and triggers

2. **20240126000002_rls_policies.sql**
   - Enables Row Level Security (RLS) on all tables
   - Creates helper functions (is_admin, is_approved, get_user_status)
   - Creates comprehensive RLS policies for all access patterns

3. **20240126000003_storage_setup.sql**
   - Creates storage bucket for listing media
   - Creates storage policies for file access

## Running Migrations

### Using Supabase CLI (Recommended)

This project uses **pnpm** and the Supabase CLI as a dev dependency.

1. **Install dependencies**
   ```bash
   pnpm install
   ```

2. **Log in to Supabase** (once)
   ```bash
   pnpm supabase login
   ```

3. **Link to your project** (uses `project_id` from `.env`)
   ```bash
   pnpm db:link
   ```

4. **Run migrations**
   ```bash
   pnpm db:push
   ```

Or run the CLI directly: `pnpm supabase <command>` (e.g. `pnpm supabase db push`).

### Using Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run each migration file in order:
   - `20240126000001_initial_schema.sql`
   - `20240126000002_rls_policies.sql`
   - `20240126000003_storage_setup.sql`

## Required Supabase Setup

Before running migrations, ensure you have:

1. **Created a Supabase project** at https://supabase.com
2. **Obtained your project credentials**:
   - Project URL
   - Anon key
   - Service role key (for admin operations)

3. **Environment variables** set in your `.env` file:
   ```env
   PUBLIC_SUPABASE_URL=your_supabase_project_url
   PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
   SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

## Post-Migration Setup

After running migrations:

1. **Create your first admin user**:
   - Sign up through the app (or create directly in Supabase Auth)
   - Manually update the profile in the database:
     ```sql
     UPDATE profiles SET role = 'admin', status = 'approved' WHERE id = 'your-user-id';
     ```

2. **Verify RLS policies**:
   - Test that pending users cannot see contact details
   - Test that approved users can see approved listings
   - Test that admins can see all data including demographics

3. **Test storage bucket**:
   - Verify the `listing-media` bucket exists
   - Test file upload permissions

## Schema Overview

### Tables

- **profiles**: Base user records (linked to auth.users)
- **farmer_profiles**: Extended farmer information + admin-only demographics
- **landowner_profiles**: Extended landowner information + admin-only demographics
- **listings**: Farmland/opportunity listings
- **listing_media**: Photos, aerial images, maps for listings
- **inquiries**: Farmer expressions of interest
- **inquiry_messages**: Messages within inquiries

### Key Constraints

- Profile role must match extended profile type (farmer/landowner)
- Inquiries can only be created by approved farmers on approved listings
- Listings require approval before public visibility
- Demographic data is admin-only (enforced by RLS)

## Troubleshooting

### Migration Errors

If you encounter errors:

1. Check that you're running migrations in order
2. Verify your Supabase project is active
3. Check that RLS is enabled on auth.users (should be by default)
4. Ensure you have proper permissions (service role key for admin operations)

### RLS Policy Issues

If RLS policies aren't working:

1. Verify RLS is enabled: `SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public';`
2. Check helper functions exist: `SELECT proname FROM pg_proc WHERE proname IN ('is_admin', 'is_approved');`
3. Test policies with different user roles and statuses

### Storage Issues

If storage uploads fail:

1. Verify bucket exists: Check in Supabase Dashboard > Storage
2. Check storage policies are applied
3. Verify file size and MIME type restrictions
4. Check file path format matches policy expectations
