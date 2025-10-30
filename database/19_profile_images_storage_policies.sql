-- =====================================================
-- STORAGE BUCKET POLICIES FOR PROFILE IMAGES
-- =====================================================
-- Run this AFTER creating the "profile-images" bucket
-- in Supabase Dashboard → Storage

-- First, create the bucket in Dashboard:
-- - Name: profile-images
-- - Public: YES
-- - File size limit: 2 MB
-- - Allowed MIME types: image/jpeg, image/png, image/webp

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Allow authenticated users to upload their own profile images
-- (folder structure: user_id/filename.jpg)
CREATE POLICY "Users can upload own profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow everyone to view profile images  
CREATE POLICY "Anyone can view profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Allow users to update their own profile images
CREATE POLICY "Users can update own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow users to delete their own profile images
CREATE POLICY "Users can delete own profile images"  
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- Verify policies were created
SELECT 
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%profile images%';

SELECT 'Profile images storage policies created successfully!' as status;

