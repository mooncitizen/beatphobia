-- =====================================================
-- Migration: Fix RLS Update Policies for Posts and Comments
-- =====================================================
-- This migration fixes the Row Level Security policies to allow
-- users to update (including soft delete) their own posts and comments.
-- 
-- Run this in your Supabase SQL Editor to fix the "new row violates 
-- row-level security policy" error when deleting posts/comments.
-- =====================================================

-- Drop existing update policies
DROP POLICY IF EXISTS "Users can update own posts" ON community_posts;
DROP POLICY IF EXISTS "Users can update own comments" ON community_comments;

-- Recreate with proper WITH CHECK clause
CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('community_posts', 'community_comments')
AND policyname LIKE '%update%'
ORDER BY tablename, policyname;

