-- =====================================================
-- Fix Comment RLS Policies (Same as Posts Fix)
-- =====================================================

-- Drop and recreate the SELECT policy to allow users to see their own comments
DROP POLICY IF EXISTS "Comments are viewable by everyone" ON community_comments;

CREATE POLICY "Comments are viewable by everyone" ON community_comments
    FOR SELECT 
    USING (
        is_deleted = FALSE AND is_flagged = FALSE
        OR
        auth.uid() = user_id  -- Users can see their own comments even if deleted/flagged
    );

-- Drop and recreate UPDATE policy with WITH CHECK
DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;

CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Verify the policies
SELECT 
    policyname,
    cmd,
    qual as using_clause,
    with_check as with_check_clause
FROM pg_policies 
WHERE tablename = 'community_comments'
ORDER BY cmd, policyname;

