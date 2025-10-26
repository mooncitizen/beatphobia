-- =====================================================
-- Complete RLS Policy Reset for Posts and Comments
-- =====================================================
-- This completely resets all RLS policies for community_posts 
-- and community_comments to fix the delete/update issue.
-- =====================================================

-- First, let's see what policies exist
SELECT tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename IN ('community_posts', 'community_comments')
ORDER BY tablename, policyname;

-- Drop ALL existing policies for community_posts
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON community_posts;
DROP POLICY IF EXISTS "Users can create posts" ON community_posts;
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON community_posts;

-- Drop ALL existing policies for community_comments
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON community_comments;
DROP POLICY IF EXISTS "Users can create comments" ON community_comments;
DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON community_comments;

-- =====================================================
-- Recreate POSTS policies
-- =====================================================

-- SELECT: Everyone can view non-deleted, non-flagged posts
CREATE POLICY "Posts are viewable by everyone" ON community_posts
    FOR SELECT 
    USING (is_deleted = FALSE AND is_flagged = FALSE);

-- INSERT: Users can create posts
CREATE POLICY "Users can create posts" ON community_posts
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can update their own posts (including soft delete)
CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can delete their own posts (hard delete - not used, but for completeness)
CREATE POLICY "Users can delete own posts" ON community_posts
    FOR DELETE 
    USING (auth.uid() = user_id);

-- =====================================================
-- Recreate COMMENTS policies
-- =====================================================

-- SELECT: Everyone can view non-deleted, non-flagged comments
CREATE POLICY "Comments are viewable by everyone" ON community_comments
    FOR SELECT 
    USING (is_deleted = FALSE AND is_flagged = FALSE);

-- INSERT: Users can create comments
CREATE POLICY "Users can create comments" ON community_comments
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can update their own comments (including soft delete)
CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can delete their own comments (hard delete - not used)
CREATE POLICY "Users can delete own comments" ON community_comments
    FOR DELETE 
    USING (auth.uid() = user_id);

-- =====================================================
-- Verify the new policies
-- =====================================================
SELECT 
    tablename,
    policyname,
    cmd as command,
    CASE 
        WHEN qual IS NOT NULL THEN 'USING: ' || qual
        ELSE 'No USING clause'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'WITH CHECK: ' || with_check
        ELSE 'No WITH CHECK clause'
    END as with_check_clause
FROM pg_policies 
WHERE tablename IN ('community_posts', 'community_comments')
ORDER BY tablename, policyname;

-- =====================================================
-- Test the update policy
-- =====================================================
-- This will help debug if there's still an issue
-- Run this to see if you can update your own post:
-- UPDATE community_posts 
-- SET is_deleted = true 
-- WHERE user_id = auth.uid() 
-- AND id = 'YOUR_POST_ID_HERE';

