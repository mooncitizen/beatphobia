-- =====================================================
-- Fix RLS Policies - Remove WITH CHECK for Updates
-- =====================================================
-- The WITH CHECK clause might be causing issues.
-- For update operations where we're only checking ownership,
-- USING clause alone is sufficient.
-- =====================================================

-- Drop existing update policies
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;

-- Recreate update policies WITHOUT WITH CHECK clause
-- USING clause is sufficient to ensure only owners can update
CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- Verify the policies
SELECT 
    tablename,
    policyname,
    cmd,
    qual as using_clause,
    with_check as with_check_clause
FROM pg_policies 
WHERE tablename IN ('community_posts', 'community_comments')
AND cmd = 'UPDATE'
ORDER BY tablename;

-- Test: Try to update one of your posts
-- First, get a post ID:
SELECT id, user_id, title, is_deleted 
FROM community_posts 
WHERE user_id = auth.uid() 
LIMIT 1;

-- Then test the update (replace with your actual post ID):
-- UPDATE community_posts 
-- SET is_deleted = true 
-- WHERE id = 'YOUR_POST_ID_HERE'::uuid;

