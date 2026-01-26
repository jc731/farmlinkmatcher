-- Illinois Farmlink App - Initial Database Schema
-- This migration creates all tables, enums, and basic structure

-- ============================================================================
-- ENUMS
-- ============================================================================

-- User roles
CREATE TYPE user_role AS ENUM ('farmer', 'landowner', 'admin');

-- User status (approval-driven)
CREATE TYPE user_status AS ENUM ('pending', 'approved', 'rejected', 'suspended');

-- Listing status
CREATE TYPE listing_status AS ENUM ('draft', 'pending', 'approved', 'rejected', 'archived');

-- Inquiry status
CREATE TYPE inquiry_status AS ENUM ('open', 'closed', 'blocked');

-- Listing media types
CREATE TYPE media_type AS ENUM ('photo', 'aerial', 'map');

-- ============================================================================
-- TABLES
-- ============================================================================

-- Base profiles table (linked to auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    status user_status NOT NULL DEFAULT 'pending',
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    address TEXT,
    city TEXT,
    state TEXT NOT NULL DEFAULT 'IL',
    zip TEXT,
    terms_accepted BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_phone CHECK (phone IS NULL OR phone ~ '^[0-9+\-(). ]+$'),
    CONSTRAINT valid_zip CHECK (zip IS NULL OR zip ~ '^[0-9]{5}(-[0-9]{4})?$')
);

-- Farmer profiles (extends profiles)
CREATE TABLE farmer_profiles (
    profile_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    farming_plans_and_goals TEXT,
    farming_status TEXT,
    farming_status_notes TEXT,
    counties TEXT[] DEFAULT '{}',
    farmable_acreage_range TEXT,
    infrastructure_needed TEXT[] DEFAULT '{}',
    infrastructure_notes TEXT,
    crops TEXT[] DEFAULT '{}',
    livestock TEXT[] DEFAULT '{}',
    crops_livestock_notes TEXT,
    farming_methods TEXT[] DEFAULT '{}',
    farming_methods_notes TEXT,
    business_plan_status TEXT,
    business_plan_summary TEXT,
    tenure_options_desired TEXT[] DEFAULT '{}',
    tenure_notes TEXT,
    experience_education TEXT[] DEFAULT '{}',
    experience_notes TEXT,
    referral_source TEXT,
    -- Admin-only demographic fields
    gender TEXT,
    age_range TEXT,
    veteran_status BOOLEAN,
    race TEXT[] DEFAULT '{}',
    ethnicity TEXT,
    disability_status BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Landowner profiles (extends profiles)
CREATE TABLE landowner_profiles (
    profile_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    referral_source TEXT,
    -- Admin-only demographic fields
    gender TEXT,
    age_range TEXT,
    veteran_status BOOLEAN,
    race TEXT[] DEFAULT '{}',
    ethnicity TEXT,
    disability_status BOOLEAN,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Listings (farmland/opportunities)
CREATE TABLE listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status listing_status NOT NULL DEFAULT 'draft',
    property_name TEXT NOT NULL,
    street_address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'IL',
    zip TEXT NOT NULL,
    county TEXT NOT NULL,
    total_acreage NUMERIC(10, 2),
    farmable_acreage NUMERIC(10, 2),
    natural_area_acreage NUMERIC(10, 2),
    infrastructure_available TEXT[] DEFAULT '{}',
    infrastructure_notes TEXT,
    crops_permitted TEXT[] DEFAULT '{}',
    livestock_permitted TEXT[] DEFAULT '{}',
    crops_livestock_notes TEXT,
    property_history_notes TEXT,
    preferred_farming_methods TEXT[] DEFAULT '{}',
    stewardship_values TEXT,
    certified_organic_or_eligible BOOLEAN DEFAULT false,
    tenure_options_offered TEXT[] DEFAULT '{}',
    tenure_availability_timing TEXT,
    tenure_notes TEXT,
    zoning_appropriate BOOLEAN,
    conservation_easement BOOLEAN DEFAULT false,
    public_access_allowed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_zip CHECK (zip ~ '^[0-9]{5}(-[0-9]{4})?$'),
    CONSTRAINT valid_acreage CHECK (
        (total_acreage IS NULL OR total_acreage >= 0) AND
        (farmable_acreage IS NULL OR farmable_acreage >= 0) AND
        (natural_area_acreage IS NULL OR natural_area_acreage >= 0)
    )
);

-- Listing media (photos, aerial images, maps)
CREATE TABLE listing_media (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    type media_type NOT NULL,
    storage_path TEXT NOT NULL,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_storage_path CHECK (storage_path ~ '^[a-zA-Z0-9_\-/]+\.(jpg|jpeg|png|gif|webp|pdf)$')
);

-- Inquiries (farmer expressions of interest)
CREATE TABLE inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    from_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    to_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    status inquiry_status NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_inquiry_profiles CHECK (
        from_profile_id != to_profile_id
    )
);

-- Inquiry messages (non-realtime messaging)
CREATE TABLE inquiry_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inquiry_id UUID NOT NULL REFERENCES inquiries(id) ON DELETE CASCADE,
    sender_profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_message_body CHECK (length(body) > 0 AND length(body) <= 5000)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Profiles indexes
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_role_status ON profiles(role, status);
CREATE INDEX idx_profiles_state ON profiles(state);
CREATE INDEX idx_profiles_city ON profiles(city);

-- Farmer profiles indexes
CREATE INDEX idx_farmer_profiles_counties ON farmer_profiles USING GIN(counties);
CREATE INDEX idx_farmer_profiles_crops ON farmer_profiles USING GIN(crops);
CREATE INDEX idx_farmer_profiles_livestock ON farmer_profiles USING GIN(livestock);

-- Listings indexes
CREATE INDEX idx_listings_owner ON listings(owner_profile_id);
CREATE INDEX idx_listings_status ON listings(status);
CREATE INDEX idx_listings_county ON listings(county);
CREATE INDEX idx_listings_state ON listings(state);
CREATE INDEX idx_listings_city ON listings(city);
CREATE INDEX idx_listings_status_approved ON listings(status) WHERE status = 'approved';
CREATE INDEX idx_listings_created_at ON listings(created_at DESC);

-- Listing media indexes
CREATE INDEX idx_listing_media_listing ON listing_media(listing_id);
CREATE INDEX idx_listing_media_sort ON listing_media(listing_id, sort_order);

-- Inquiries indexes
CREATE INDEX idx_inquiries_listing ON inquiries(listing_id);
CREATE INDEX idx_inquiries_from_profile ON inquiries(from_profile_id);
CREATE INDEX idx_inquiries_to_profile ON inquiries(to_profile_id);
CREATE INDEX idx_inquiries_status ON inquiries(status);
CREATE INDEX idx_inquiries_created_at ON inquiries(created_at DESC);

-- Inquiry messages indexes
CREATE INDEX idx_inquiry_messages_inquiry ON inquiry_messages(inquiry_id);
CREATE INDEX idx_inquiry_messages_sender ON inquiry_messages(sender_profile_id);
CREATE INDEX idx_inquiry_messages_created_at ON inquiry_messages(created_at DESC);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_farmer_profiles_updated_at
    BEFORE UPDATE ON farmer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_landowner_profiles_updated_at
    BEFORE UPDATE ON landowner_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_listings_updated_at
    BEFORE UPDATE ON listings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_inquiries_updated_at
    BEFORE UPDATE ON inquiries
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to ensure profile role matches extended profile
CREATE OR REPLACE FUNCTION validate_profile_role()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_TABLE_NAME = 'farmer_profiles' THEN
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.profile_id AND role = 'farmer') THEN
            RAISE EXCEPTION 'Profile role must be farmer for farmer_profiles';
        END IF;
    ELSIF TG_TABLE_NAME = 'landowner_profiles' THEN
        IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.profile_id AND role = 'landowner') THEN
            RAISE EXCEPTION 'Profile role must be landowner for landowner_profiles';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for role validation
CREATE TRIGGER validate_farmer_profile_role
    BEFORE INSERT OR UPDATE ON farmer_profiles
    FOR EACH ROW
    EXECUTE FUNCTION validate_profile_role();

CREATE TRIGGER validate_landowner_profile_role
    BEFORE INSERT OR UPDATE ON landowner_profiles
    FOR EACH ROW
    EXECUTE FUNCTION validate_profile_role();

-- Function to ensure inquiry participants are correct roles
CREATE OR REPLACE FUNCTION validate_inquiry_roles()
RETURNS TRIGGER AS $$
BEGIN
    -- from_profile_id must be a farmer
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.from_profile_id AND role = 'farmer') THEN
        RAISE EXCEPTION 'Inquiry from_profile_id must be a farmer';
    END IF;
    -- to_profile_id must be a landowner
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.to_profile_id AND role = 'landowner') THEN
        RAISE EXCEPTION 'Inquiry to_profile_id must be a landowner';
    END IF;
    -- listing owner must match to_profile_id
    IF NOT EXISTS (SELECT 1 FROM listings WHERE id = NEW.listing_id AND owner_profile_id = NEW.to_profile_id) THEN
        RAISE EXCEPTION 'Inquiry listing owner must match to_profile_id';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_inquiry_roles_trigger
    BEFORE INSERT OR UPDATE ON inquiries
    FOR EACH ROW
    EXECUTE FUNCTION validate_inquiry_roles();
