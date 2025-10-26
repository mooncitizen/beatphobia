-- =====================================================
-- Debug Authentication and User ID
-- =====================================================
-- Run this to check if auth.uid() is working correctly
-- =====================================================

-- Check your current user ID
SELECT auth.uid() as current_user_id;

-- Check the type of auth.uid()
SELECT pg_typeof(auth.uid()) as auth_uid_type;

-- Check if you have any posts
SELECT id, user_id, title, is_deleted 
FROM community_posts 
WHERE user_id = auth.uid()
LIMIT 5;

-- Check if the user_id matches auth.uid() for your posts
SELECT 
    id,
    user_id,
    auth.uid() as current_auth_uid,
    (user_id = auth.uid()) as ids_match,
    is_deleted
FROM community_posts 
WHERE user_id = auth.uid()
LIMIT 5;

-- Try to manually update a post (replace YOUR_POST_ID with actual ID)
-- UPDATE community_posts 
-- SET is_deleted = true 
-- WHERE id = 'YOUR_POST_ID'::uuid 
-- AND user_id = auth.uid();

