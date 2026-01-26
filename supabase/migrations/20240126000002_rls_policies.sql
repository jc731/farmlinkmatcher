-- Illinois Farmlink App - Row Level Security (RLS) Policies
-- This migration enables RLS and creates all security policies

-- ============================================================================
-- ENABLE RLS ON ALL TABLES
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE landowner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE inquiry_messages ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is approved
CREATE OR REPLACE FUNCTION is_approved()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid()
        AND status = 'approved'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's profile status
CREATE OR REPLACE FUNCTION get_user_status()
RETURNS user_status AS $$
DECLARE
    user_status_val user_status;
BEGIN
    SELECT status INTO user_status_val
    FROM profiles
    WHERE id = auth.uid();
    RETURN COALESCE(user_status_val, 'pending'::user_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- PROFILES TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (id = auth.uid());

-- Approved users can view approved users' profiles (with contact info)
CREATE POLICY "Approved users can view approved profiles"
    ON profiles FOR SELECT
    USING (
        status = 'approved'
        AND (is_approved() OR is_admin())
    );

-- Pending users can view approved users' profiles (without contact info)
-- This is handled by a view or application logic that excludes contact fields
-- For RLS, we allow viewing but application will filter contact info

-- Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
    ON profiles FOR SELECT
    USING (is_admin());

-- Users can insert their own profile (on sign-up)
CREATE POLICY "Users can insert own profile"
    ON profiles FOR INSERT
    WITH CHECK (id = auth.uid());

-- Users can update their own profile (pending or approved)
CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());

-- Admins can update any profile (for approval/rejection/suspension)
CREATE POLICY "Admins can update any profile"
    ON profiles FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());

-- ============================================================================
-- FARMER_PROFILES TABLE POLICIES
-- ============================================================================

-- Users can view their own farmer profile
CREATE POLICY "Users can view own farmer profile"
    ON farmer_profiles FOR SELECT
    USING (profile_id = auth.uid());

-- Admins can view all farmer profiles (including demographics)
CREATE POLICY "Admins can view all farmer profiles"
    ON farmer_profiles FOR SELECT
    USING (is_admin());

-- Farmers can insert their own farmer profile
CREATE POLICY "Farmers can insert own farmer profile"
    ON farmer_profiles FOR INSERT
    WITH CHECK (
        profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'farmer')
    );

-- Farmers can update their own farmer profile
CREATE POLICY "Farmers can update own farmer profile"
    ON farmer_profiles FOR UPDATE
    USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

-- Admins can update any farmer profile
CREATE POLICY "Admins can update any farmer profile"
    ON farmer_profiles FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());

-- ============================================================================
-- LANDOWNER_PROFILES TABLE POLICIES
-- ============================================================================

-- Users can view their own landowner profile
CREATE POLICY "Users can view own landowner profile"
    ON landowner_profiles FOR SELECT
    USING (profile_id = auth.uid());

-- Admins can view all landowner profiles (including demographics)
CREATE POLICY "Admins can view all landowner profiles"
    ON landowner_profiles FOR SELECT
    USING (is_admin());

-- Landowners can insert their own landowner profile
CREATE POLICY "Landowners can insert own landowner profile"
    ON landowner_profiles FOR INSERT
    WITH CHECK (
        profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'landowner')
    );

-- Landowners can update their own landowner profile
CREATE POLICY "Landowners can update own landowner profile"
    ON landowner_profiles FOR UPDATE
    USING (profile_id = auth.uid())
    WITH CHECK (profile_id = auth.uid());

-- Admins can update any landowner profile
CREATE POLICY "Admins can update any landowner profile"
    ON landowner_profiles FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());

-- ============================================================================
-- LISTINGS TABLE POLICIES
-- ============================================================================

-- Approved users can view approved listings
CREATE POLICY "Approved users can view approved listings"
    ON listings FOR SELECT
    USING (
        status = 'approved'
        AND (is_approved() OR is_admin())
    );

-- Landowners can view their own listings (all statuses)
CREATE POLICY "Landowners can view own listings"
    ON listings FOR SELECT
    USING (
        owner_profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'landowner')
    );

-- Admins can view all listings
CREATE POLICY "Admins can view all listings"
    ON listings FOR SELECT
    USING (is_admin());

-- Approved landowners can insert listings
CREATE POLICY "Approved landowners can insert listings"
    ON listings FOR INSERT
    WITH CHECK (
        owner_profile_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'landowner'
            AND status = 'approved'
        )
    );

-- Landowners can update their own listings
CREATE POLICY "Landowners can update own listings"
    ON listings FOR UPDATE
    USING (
        owner_profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'landowner')
    )
    WITH CHECK (
        owner_profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'landowner')
    );

-- Admins can update any listing (for approval/rejection)
CREATE POLICY "Admins can update any listing"
    ON listings FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());

-- Landowners can delete their own draft listings
CREATE POLICY "Landowners can delete own draft listings"
    ON listings FOR DELETE
    USING (
        owner_profile_id = auth.uid()
        AND status = 'draft'
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'landowner')
    );

-- ============================================================================
-- LISTING_MEDIA TABLE POLICIES
-- ============================================================================

-- Approved users can view media for approved listings
CREATE POLICY "Approved users can view media for approved listings"
    ON listing_media FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.status = 'approved'
        )
        AND (is_approved() OR is_admin())
    );

-- Landowners can view media for their own listings
CREATE POLICY "Landowners can view own listing media"
    ON listing_media FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    );

-- Admins can view all listing media
CREATE POLICY "Admins can view all listing media"
    ON listing_media FOR SELECT
    USING (is_admin());

-- Approved landowners can insert media for their own listings
CREATE POLICY "Approved landowners can insert listing media"
    ON listing_media FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.owner_profile_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM profiles
                WHERE id = auth.uid()
                AND role = 'landowner'
                AND status = 'approved'
            )
        )
    );

-- Landowners can update media for their own listings
CREATE POLICY "Landowners can update own listing media"
    ON listing_media FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    );

-- Landowners can delete media for their own listings
CREATE POLICY "Landowners can delete own listing media"
    ON listing_media FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = listing_media.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    );

-- ============================================================================
-- INQUIRIES TABLE POLICIES
-- ============================================================================

-- Farmers can view their own inquiries
CREATE POLICY "Farmers can view own inquiries"
    ON inquiries FOR SELECT
    USING (
        from_profile_id = auth.uid()
        AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'farmer')
    );

-- Landowners can view inquiries on their listings
CREATE POLICY "Landowners can view inquiries on their listings"
    ON inquiries FOR SELECT
    USING (
        to_profile_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inquiries.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    );

-- Admins can view all inquiries
CREATE POLICY "Admins can view all inquiries"
    ON inquiries FOR SELECT
    USING (is_admin());

-- Approved farmers can create inquiries on approved listings
CREATE POLICY "Approved farmers can create inquiries"
    ON inquiries FOR INSERT
    WITH CHECK (
        from_profile_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid()
            AND role = 'farmer'
            AND status = 'approved'
        )
        AND EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inquiries.listing_id
            AND listings.status = 'approved'
        )
    );

-- Farmers can update their own inquiries
CREATE POLICY "Farmers can update own inquiries"
    ON inquiries FOR UPDATE
    USING (from_profile_id = auth.uid())
    WITH CHECK (from_profile_id = auth.uid());

-- Landowners can update inquiries on their listings (for blocking/closing)
CREATE POLICY "Landowners can update inquiries on their listings"
    ON inquiries FOR UPDATE
    USING (
        to_profile_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inquiries.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    )
    WITH CHECK (
        to_profile_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM listings
            WHERE listings.id = inquiries.listing_id
            AND listings.owner_profile_id = auth.uid()
        )
    );

-- Admins can update any inquiry
CREATE POLICY "Admins can update any inquiry"
    ON inquiries FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());

-- ============================================================================
-- INQUIRY_MESSAGES TABLE POLICIES
-- ============================================================================

-- Users can view messages in inquiries they're part of
CREATE POLICY "Users can view messages in their inquiries"
    ON inquiry_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM inquiries
            WHERE inquiries.id = inquiry_messages.inquiry_id
            AND (inquiries.from_profile_id = auth.uid() OR inquiries.to_profile_id = auth.uid())
        )
    );

-- Admins can view all messages
CREATE POLICY "Admins can view all messages"
    ON inquiry_messages FOR SELECT
    USING (is_admin());

-- Approved users can send messages in inquiries they're part of
CREATE POLICY "Approved users can send messages"
    ON inquiry_messages FOR INSERT
    WITH CHECK (
        sender_profile_id = auth.uid()
        AND is_approved()
        AND EXISTS (
            SELECT 1 FROM inquiries
            WHERE inquiries.id = inquiry_messages.inquiry_id
            AND (inquiries.from_profile_id = auth.uid() OR inquiries.to_profile_id = auth.uid())
            AND inquiries.status != 'blocked'
        )
    );

-- Users can update their own messages (within time limit - handled by application)
CREATE POLICY "Users can update own messages"
    ON inquiry_messages FOR UPDATE
    USING (sender_profile_id = auth.uid())
    WITH CHECK (sender_profile_id = auth.uid());

-- Admins can update any message
CREATE POLICY "Admins can update any message"
    ON inquiry_messages FOR UPDATE
    USING (is_admin())
    WITH CHECK (is_admin());
