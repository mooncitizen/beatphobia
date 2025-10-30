-- =====================================================
-- ALTERNATIVE: PRIVATE BUCKET WITH SIGNED URLs
-- =====================================================
-- Use this if you want tighter control over image access
-- (Not recommended for public forum, but good for private features)

-- Create bucket as PRIVATE in Dashboard:
-- - Name: community-attachments  
-- - Public: NO (unchecked)
-- - Then run these policies:

-- Allow authenticated users to upload
CREATE POLICY "Authenticated users can upload to private bucket"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-attachments');

-- Allow authenticated users to view files
-- (They'll need to request signed URLs from your app)
CREATE POLICY "Authenticated users can view attachments"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'community-attachments');

-- Allow users to delete their own files
CREATE POLICY "Users can delete own private attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'community-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- NOTE: With private bucket, you'll need to modify ImageManager to use signed URLs:
-- let signedURL = try await supabase.storage
--     .from("community-attachments")
--     .createSignedURL(path: filename, expiresIn: 3600)

SELECT 'Private bucket policies created. Remember to update ImageManager for signed URLs.' as status;

