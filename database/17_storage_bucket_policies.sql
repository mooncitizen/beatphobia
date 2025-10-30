-- =====================================================
-- STORAGE BUCKET POLICIES FOR COMMUNITY ATTACHMENTS
-- =====================================================
-- Run this AFTER creating the "community-attachments" bucket
-- in Supabase Dashboard → Storage

-- First, ensure the bucket exists and is public
-- (This is just for reference - create bucket in Dashboard UI)
-- Bucket name: community-attachments
-- Public: YES

-- =====================================================
-- STORAGE POLICIES
-- =====================================================

-- Allow authenticated users to upload/insert files
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-attachments');

-- Allow everyone (including public/anon) to view/select files
CREATE POLICY "Anyone can view attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'community-attachments');

-- Allow authenticated users to update their own files
CREATE POLICY "Users can update attachments"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'community-attachments');

-- Allow authenticated users to delete their own files
CREATE POLICY "Users can delete attachments"  
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'community-attachments');

-- Verify policies were created
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%attachments%';

SELECT 'Storage bucket policies created successfully!' as status;

