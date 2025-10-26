-- =====================================================
-- Simplified Update Policy (For Testing Only)
-- =====================================================
-- This creates a very permissive update policy to test
-- if the issue is with the policy conditions
-- WARNING: This is for testing only - it's less secure
-- =====================================================

-- Drop the existing update policies
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;

-- Create simplified update policies that are more permissive
-- These allow users to update their own posts/comments without complex checks
CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (user_id::text = auth.uid()::text);

CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (user_id::text = auth.uid()::text);

-- Verify
SELECT tablename, policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename IN ('community_posts', 'community_comments')
AND policyname LIKE '%update%';

-- Test if this works by trying to update one of your posts
-- SELECT id, user_id, is_deleted FROM community_posts WHERE user_id = auth.uid() LIMIT 1;
-- Then use that ID below:
-- UPDATE community_posts SET is_deleted = true WHERE id = 'YOUR_POST_ID' AND user_id = auth.uid();

