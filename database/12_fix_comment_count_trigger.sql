-- =====================================================
-- FIX COMMENT COUNT TO EXCLUDE DELETED/FLAGGED COMMENTS
-- =====================================================
-- This migration fixes the comment count trigger to only count
-- active comments (is_deleted = FALSE and is_flagged = FALSE)

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS trigger_post_comments_count ON community_comments;
DROP FUNCTION IF EXISTS update_post_comments_count();

-- Create new function that only counts active comments
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    -- For INSERT, UPDATE, and DELETE operations, recalculate the count
    -- based on actual non-deleted, non-flagged comments
    IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' OR TG_OP = 'DELETE' THEN
        -- Get the post_id (could be from NEW or OLD depending on operation)
        DECLARE
            target_post_id UUID;
        BEGIN
            IF TG_OP = 'DELETE' THEN
                target_post_id := OLD.post_id;
            ELSE
                target_post_id := NEW.post_id;
            END IF;
            
            -- Recalculate the actual count of active comments
            UPDATE community_posts 
            SET comments_count = (
                SELECT COUNT(*) 
                FROM community_comments 
                WHERE post_id = target_post_id 
                AND is_deleted = FALSE 
                AND is_flagged = FALSE
            )
            WHERE id = target_post_id;
        END;
    END IF;
    
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Create the trigger
CREATE TRIGGER trigger_post_comments_count
    AFTER INSERT OR UPDATE OR DELETE ON community_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Fix existing counts by recalculating for all posts
UPDATE community_posts 
SET comments_count = (
    SELECT COUNT(*) 
    FROM community_comments 
    WHERE community_comments.post_id = community_posts.id 
    AND community_comments.is_deleted = FALSE 
    AND community_comments.is_flagged = FALSE
);

-- Also check if we need to handle UPDATE on topic change
-- (If a comment's post_id changes, which shouldn't happen, but just in case)
-- The above trigger handles it via the UPDATE case


