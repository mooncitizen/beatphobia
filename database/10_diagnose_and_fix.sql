-- =====================================================
-- Diagnose and Fix RLS Issue
-- =====================================================

-- Step 1: Check current user
SELECT auth.uid() as my_user_id;

-- Step 2: Check your posts
SELECT id, user_id, title, is_deleted, is_flagged
FROM community_posts 
WHERE user_id = auth.uid()
LIMIT 5;

-- Step 3: Check ALL policies on community_posts
SELECT 
    policyname,
    cmd,
    permissive,
    roles,
    qual as using_clause,
    with_check
FROM pg_policies 
WHERE tablename = 'community_posts'
ORDER BY cmd, policyname;

-- Step 4: Try a simple manual update (get a post ID from step 2 first)
-- Replace YOUR_POST_ID below with an actual ID from your posts
-- UPDATE community_posts 
-- SET is_deleted = true 
-- WHERE id = 'YOUR_POST_ID'::uuid;

-- Step 5: If manual update works but app doesn't, the issue is in the app code
-- If manual update fails, we need to adjust policies

-- =====================================================
-- POTENTIAL FIX: Make UPDATE policy more permissive
-- =====================================================

-- Drop and recreate with explicit permission to update is_deleted
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;

CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Also ensure the SELECT policy doesn't prevent seeing the row before update
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON community_posts;

CREATE POLICY "Posts are viewable by everyone" ON community_posts
    FOR SELECT 
    USING (
        is_deleted = FALSE AND is_flagged = FALSE
        OR
        auth.uid() = user_id  -- Users can see their own posts even if deleted/flagged
    );

-- Verify
SELECT policyname, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'community_posts'
ORDER BY cmd, policyname;

