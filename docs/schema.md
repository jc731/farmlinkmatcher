# Database Schema Documentation

## Overview

The Illinois Farmlink App uses PostgreSQL via Supabase with Row Level Security (RLS) for all data access control. This document describes the complete database schema.

## Enums

### `user_role`
- `farmer`: User seeking farmland access
- `landowner`: User offering farmland
- `admin`: Platform administrator

### `user_status`
- `pending`: Awaiting admin approval
- `approved`: Active and fully functional
- `rejected`: Denied access
- `suspended`: Temporarily disabled

### `listing_status`
- `draft`: Not yet submitted for approval
- `pending`: Awaiting admin approval
- `approved`: Publicly visible to approved farmers
- `rejected`: Denied approval
- `archived`: No longer active

### `inquiry_status`
- `open`: Active inquiry
- `closed`: Inquiry closed by either party
- `blocked`: Blocked by landowner or admin

### `media_type`
- `photo`: Regular photograph
- `aerial`: Aerial/satellite image
- `map`: Map image

## Tables

### `profiles`

Base user record linked to Supabase Auth (`auth.users`).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK, FK → auth.users | User ID (matches auth.users.id) |
| `role` | user_role | NOT NULL | User role (farmer/landowner/admin) |
| `status` | user_status | NOT NULL, DEFAULT 'pending' | Approval status |
| `first_name` | TEXT | NOT NULL | First name |
| `last_name` | TEXT | NOT NULL | Last name |
| `phone` | TEXT | CHECK (phone format) | Phone number |
| `address` | TEXT | | Street address |
| `city` | TEXT | | City |
| `state` | TEXT | NOT NULL, DEFAULT 'IL' | State (defaults to IL) |
| `zip` | TEXT | CHECK (zip format) | ZIP code |
| `terms_accepted` | BOOLEAN | NOT NULL, DEFAULT false | Terms acceptance flag |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_profiles_role` on `role`
- `idx_profiles_status` on `status`
- `idx_profiles_role_status` on `(role, status)`
- `idx_profiles_state` on `state`
- `idx_profiles_city` on `city`

### `farmer_profiles`

Extended profile information for farmers. Includes admin-only demographic fields.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `profile_id` | UUID | PK, FK → profiles | Profile ID |
| `farming_plans_and_goals` | TEXT | | Farming plans and goals |
| `farming_status` | TEXT | | Current farming status |
| `farming_status_notes` | TEXT | | Additional status notes |
| `counties` | TEXT[] | DEFAULT '{}' | Counties of interest |
| `farmable_acreage_range` | TEXT | | Desired acreage range |
| `infrastructure_needed` | TEXT[] | DEFAULT '{}' | Infrastructure needs |
| `infrastructure_notes` | TEXT | | Infrastructure notes |
| `crops` | TEXT[] | DEFAULT '{}' | Crops of interest |
| `livestock` | TEXT[] | DEFAULT '{}' | Livestock types |
| `crops_livestock_notes` | TEXT | | Additional notes |
| `farming_methods` | TEXT[] | DEFAULT '{}' | Preferred farming methods |
| `farming_methods_notes` | TEXT | | Farming methods notes |
| `business_plan_status` | TEXT | | Business plan status |
| `business_plan_summary` | TEXT | | Business plan summary |
| `tenure_options_desired` | TEXT[] | DEFAULT '{}' | Desired tenure options |
| `tenure_notes` | TEXT | | Tenure notes |
| `experience_education` | TEXT[] | DEFAULT '{}' | Experience and education |
| `experience_notes` | TEXT | | Experience notes |
| `referral_source` | TEXT | | How they heard about the platform |
| `gender` | TEXT | **ADMIN ONLY** | Gender (admin-only) |
| `age_range` | TEXT | **ADMIN ONLY** | Age range (admin-only) |
| `veteran_status` | BOOLEAN | **ADMIN ONLY** | Veteran status (admin-only) |
| `race` | TEXT[] | **ADMIN ONLY** | Race (admin-only) |
| `ethnicity` | TEXT | **ADMIN ONLY** | Ethnicity (admin-only) |
| `disability_status` | BOOLEAN | **ADMIN ONLY** | Disability status (admin-only) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_farmer_profiles_counties` (GIN) on `counties`
- `idx_farmer_profiles_crops` (GIN) on `crops`
- `idx_farmer_profiles_livestock` (GIN) on `livestock`

**Constraints:**
- Profile must have `role = 'farmer'` (enforced by trigger)

### `landowner_profiles`

Extended profile information for landowners. Includes admin-only demographic fields.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `profile_id` | UUID | PK, FK → profiles | Profile ID |
| `referral_source` | TEXT | | How they heard about the platform |
| `gender` | TEXT | **ADMIN ONLY** | Gender (admin-only) |
| `age_range` | TEXT | **ADMIN ONLY** | Age range (admin-only) |
| `veteran_status` | BOOLEAN | **ADMIN ONLY** | Veteran status (admin-only) |
| `race` | TEXT[] | **ADMIN ONLY** | Race (admin-only) |
| `ethnicity` | TEXT | **ADMIN ONLY** | Ethnicity (admin-only) |
| `disability_status` | BOOLEAN | **ADMIN ONLY** | Disability status (admin-only) |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- Profile must have `role = 'landowner'` (enforced by trigger)

### `listings`

Farmland/opportunity listings created by landowners.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Listing ID |
| `owner_profile_id` | UUID | NOT NULL, FK → profiles | Owner profile ID |
| `status` | listing_status | NOT NULL, DEFAULT 'draft' | Listing status |
| `property_name` | TEXT | NOT NULL | Property name |
| `street_address` | TEXT | NOT NULL | Street address |
| `city` | TEXT | NOT NULL | City |
| `state` | TEXT | NOT NULL, DEFAULT 'IL' | State |
| `zip` | TEXT | NOT NULL, CHECK (zip format) | ZIP code |
| `county` | TEXT | NOT NULL | County |
| `total_acreage` | NUMERIC(10,2) | CHECK (>= 0) | Total acreage |
| `farmable_acreage` | NUMERIC(10,2) | CHECK (>= 0) | Farmable acreage |
| `natural_area_acreage` | NUMERIC(10,2) | CHECK (>= 0) | Natural area acreage |
| `infrastructure_available` | TEXT[] | DEFAULT '{}' | Available infrastructure |
| `infrastructure_notes` | TEXT | | Infrastructure notes |
| `crops_permitted` | TEXT[] | DEFAULT '{}' | Permitted crops |
| `livestock_permitted` | TEXT[] | DEFAULT '{}' | Permitted livestock |
| `crops_livestock_notes` | TEXT | | Additional notes |
| `property_history_notes` | TEXT | | Property history |
| `preferred_farming_methods` | TEXT[] | DEFAULT '{}' | Preferred farming methods |
| `stewardship_values` | TEXT | | Stewardship values |
| `certified_organic_or_eligible` | BOOLEAN | DEFAULT false | Organic certification status |
| `tenure_options_offered` | TEXT[] | DEFAULT '{}' | Tenure options offered |
| `tenure_availability_timing` | TEXT | | When tenure is available |
| `tenure_notes` | TEXT | | Tenure notes |
| `zoning_appropriate` | BOOLEAN | | Zoning appropriateness |
| `conservation_easement` | BOOLEAN | DEFAULT false | Conservation easement status |
| `public_access_allowed` | BOOLEAN | DEFAULT false | Public access allowed |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Indexes:**
- `idx_listings_owner` on `owner_profile_id`
- `idx_listings_status` on `status`
- `idx_listings_county` on `county`
- `idx_listings_state` on `state`
- `idx_listings_city` on `city`
- `idx_listings_status_approved` on `status` WHERE `status = 'approved'`
- `idx_listings_created_at` on `created_at DESC`

### `listing_media`

Media files (photos, aerial images, maps) for listings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Media ID |
| `listing_id` | UUID | NOT NULL, FK → listings | Listing ID |
| `type` | media_type | NOT NULL | Media type |
| `storage_path` | TEXT | NOT NULL, CHECK (path format) | Storage path in bucket |
| `sort_order` | INTEGER | NOT NULL, DEFAULT 0 | Display order |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |

**Indexes:**
- `idx_listing_media_listing` on `listing_id`
- `idx_listing_media_sort` on `(listing_id, sort_order)`

### `inquiries`

Farmer expressions of interest in listings.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Inquiry ID |
| `listing_id` | UUID | NOT NULL, FK → listings | Listing ID |
| `from_profile_id` | UUID | NOT NULL, FK → profiles | Farmer profile ID |
| `to_profile_id` | UUID | NOT NULL, FK → profiles | Landowner profile ID |
| `status` | inquiry_status | NOT NULL, DEFAULT 'open' | Inquiry status |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Last update timestamp |

**Constraints:**
- `from_profile_id` must be a farmer (enforced by trigger)
- `to_profile_id` must be a landowner (enforced by trigger)
- Listing owner must match `to_profile_id` (enforced by trigger)
- `from_profile_id != to_profile_id` (enforced by constraint)

**Indexes:**
- `idx_inquiries_listing` on `listing_id`
- `idx_inquiries_from_profile` on `from_profile_id`
- `idx_inquiries_to_profile` on `to_profile_id`
- `idx_inquiries_status` on `status`
- `idx_inquiries_created_at` on `created_at DESC`

### `inquiry_messages`

Messages within inquiries (non-realtime in MVP).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Message ID |
| `inquiry_id` | UUID | NOT NULL, FK → inquiries | Inquiry ID |
| `sender_profile_id` | UUID | NOT NULL, FK → profiles | Sender profile ID |
| `body` | TEXT | NOT NULL, CHECK (length 1-5000) | Message body |
| `created_at` | TIMESTAMPTZ | NOT NULL, DEFAULT NOW() | Creation timestamp |

**Indexes:**
- `idx_inquiry_messages_inquiry` on `inquiry_id`
- `idx_inquiry_messages_sender` on `sender_profile_id`
- `idx_inquiry_messages_created_at` on `created_at DESC`

## Row Level Security (RLS)

All tables have RLS enabled. Key access patterns:

### Pending Users
- Can view and edit own profile
- Cannot see contact details of other users
- Cannot create inquiries
- Cannot see approved listings (or see limited info)

### Approved Users
- Can view approved users' profiles with contact info
- Can view approved listings
- Can create inquiries on approved listings
- Can send/receive inquiry messages

### Admins
- Can view all profiles (including demographics)
- Can view all listings
- Can view all inquiries and messages
- Can update any profile or listing status

See `supabase/migrations/20240126000002_rls_policies.sql` for complete policy definitions.

## Storage

### Bucket: `listing-media`

- **Public**: Yes (for approved listings)
- **File size limit**: 10MB
- **Allowed MIME types**: image/jpeg, image/jpg, image/png, image/gif, image/webp, application/pdf

Storage policies enforce:
- Authenticated users can upload
- Users can view their own uploads
- Approved users can view approved listing media
- Admins can manage all files

## Triggers

### Automatic `updated_at` Updates
All tables with `updated_at` columns have triggers that automatically update the timestamp on row updates.

### Role Validation
Triggers ensure:
- `farmer_profiles` can only be linked to profiles with `role = 'farmer'`
- `landowner_profiles` can only be linked to profiles with `role = 'landowner'`

### Inquiry Validation
Triggers ensure:
- Inquiries can only be created by farmers
- Inquiries must target landowners
- Listing owner must match inquiry `to_profile_id`

## Helper Functions

### `is_admin()`
Returns true if the current user (auth.uid()) has role = 'admin'.

### `is_approved()`
Returns true if the current user has status = 'approved'.

### `get_user_status()`
Returns the status of the current user.

All helper functions are `SECURITY DEFINER` to allow RLS policies to use them.
