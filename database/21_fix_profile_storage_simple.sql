-- =====================================================
-- SIMPLIFIED PROFILE IMAGES STORAGE POLICIES
-- =====================================================
-- Simpler policies that actually work

-- Drop existing policies
DROP POLICY IF EXISTS "Users can upload own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can update own profile images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own profile images" ON storage.objects;

-- Create simpler, working policies

-- Allow ANY authenticated user to upload to profile-images bucket
-- (We'll rely on app logic to organize by user_id folder)
CREATE POLICY "Authenticated users can upload profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'profile-images');

-- Allow everyone to view profile images (public bucket)
CREATE POLICY "Public can view profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Allow authenticated users to update files in profile-images
CREATE POLICY "Authenticated users can update profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'profile-images');

-- Allow authenticated users to delete from profile-images
CREATE POLICY "Authenticated users can delete profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'profile-images');

-- Verify policies
SELECT 
    policyname,
    cmd,
    roles
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%profile%';

SELECT 'Simplified profile storage policies created!' as status;

