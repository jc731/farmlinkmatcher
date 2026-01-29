-- Illinois Farmlink App - Fix function search_path (security)
-- Addresses Security Advisor: function_search_path_mutable (0011)
-- Sets search_path on all SECURITY DEFINER / trigger functions used by RLS

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION validate_profile_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
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
$$;

CREATE OR REPLACE FUNCTION validate_inquiry_roles()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.from_profile_id AND role = 'farmer') THEN
        RAISE EXCEPTION 'Inquiry from_profile_id must be a farmer';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = NEW.to_profile_id AND role = 'landowner') THEN
        RAISE EXCEPTION 'Inquiry to_profile_id must be a landowner';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM listings WHERE id = NEW.listing_id AND owner_profile_id = NEW.to_profile_id) THEN
        RAISE EXCEPTION 'Inquiry listing owner must match to_profile_id';
    END IF;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    );
END;
$$;

CREATE OR REPLACE FUNCTION is_approved()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND status = 'approved'
    );
END;
$$;

CREATE OR REPLACE FUNCTION get_user_status()
RETURNS user_status
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_status_val user_status;
BEGIN
    SELECT status INTO user_status_val
    FROM profiles
    WHERE id = auth.uid();
    RETURN COALESCE(user_status_val, 'pending'::user_status);
END;
$$;
