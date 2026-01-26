-- Illinois Farmlink App - Storage Bucket Setup
-- This migration creates storage buckets for listing media

-- ============================================================================
-- STORAGE BUCKETS
-- ============================================================================

-- Create bucket for listing media (photos, aerial images, maps)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'listing-media',
    'listing-media',
    true, -- Public bucket for approved listings
    10485760, -- 10MB file size limit
    ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE POLICIES
-- ============================================================================

-- Allow authenticated users to upload to listing-media bucket
CREATE POLICY "Authenticated users can upload listing media"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'listing-media'
        AND auth.role() = 'authenticated'
    );

-- Allow users to view their own uploads
CREATE POLICY "Users can view own uploads"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'listing-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow approved users to view approved listing media
-- Note: This is a simplified policy. In practice, you may want to check
-- if the listing is approved by joining with listings table.
-- For MVP, we'll allow viewing if the file path matches a listing_media record
-- with an approved listing. This can be refined later.
CREATE POLICY "Approved users can view approved listing media"
    ON storage.objects FOR SELECT
    USING (
        bucket_id = 'listing-media'
        AND (
            is_approved()
            OR is_admin()
            OR (storage.foldername(name))[1] = auth.uid()::text
        )
    );

-- Allow users to update their own uploads
CREATE POLICY "Users can update own uploads"
    ON storage.objects FOR UPDATE
    USING (
        bucket_id = 'listing-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    )
    WITH CHECK (
        bucket_id = 'listing-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow users to delete their own uploads
CREATE POLICY "Users can delete own uploads"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'listing-media'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Admins can manage all files
CREATE POLICY "Admins can manage all listing media"
    ON storage.objects FOR ALL
    USING (
        bucket_id = 'listing-media'
        AND is_admin()
    )
    WITH CHECK (
        bucket_id = 'listing-media'
        AND is_admin()
    );
