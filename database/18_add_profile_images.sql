-- =====================================================
-- ADD PROFILE IMAGE SUPPORT
-- =====================================================
-- Adds profile_image_url column to profile table

-- Add profile image URL column
ALTER TABLE profile 
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Add index for profiles with images
CREATE INDEX IF NOT EXISTS idx_profile_has_image 
ON profile(profile_image_url) 
WHERE profile_image_url IS NOT NULL;

-- Add comment
COMMENT ON COLUMN profile.profile_image_url IS 'URL to profile image stored in Supabase Storage (bucket: profile-images). Should be square (1:1 aspect ratio).';

SELECT 'Profile image column added successfully!' as status;

-- NOTE: You'll need to create a "profile-images" bucket in Supabase Dashboard → Storage
-- Bucket settings:
-- - Name: profile-images
-- - Public: YES
-- - File size limit: 2 MB (profiles don't need huge images)
-- - Allowed MIME types: image/jpeg, image/png, image/webp

-- Then apply these storage policies in SQL Editor:
/*
CREATE POLICY "Authenticated users can upload profile images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Anyone can view profile images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-images');

CREATE POLICY "Users can update own profile images"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete own profile images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-images' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
*/

