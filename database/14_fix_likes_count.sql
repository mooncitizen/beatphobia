-- =====================================================
-- FIX LIKES COUNT - RECALCULATE ALL COUNTS
-- =====================================================
-- This migration ensures likes count triggers are working
-- and recalculates all counts to match actual data

-- First, verify the triggers exist and recreate them if needed

-- Drop and recreate post likes count trigger
DROP TRIGGER IF EXISTS trigger_post_likes_count ON community_post_likes;
DROP FUNCTION IF EXISTS update_post_likes_count();

CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
        RAISE NOTICE 'Incremented likes_count for post %', NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
        RAISE NOTICE 'Decremented likes_count for post %', OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_post_likes_count
    AFTER INSERT OR DELETE ON community_post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Drop and recreate comment likes count trigger
DROP TRIGGER IF EXISTS trigger_comment_likes_count ON community_comment_likes;
DROP FUNCTION IF EXISTS update_comment_likes_count();

CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
        RAISE NOTICE 'Incremented likes_count for comment %', NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
        RAISE NOTICE 'Decremented likes_count for comment %', OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_comment_likes_count
    AFTER INSERT OR DELETE ON community_comment_likes
    FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- =====================================================
-- RECALCULATE ALL EXISTING COUNTS
-- =====================================================

-- Fix all post likes counts by recalculating from actual likes
UPDATE community_posts 
SET likes_count = (
    SELECT COUNT(*) 
    FROM community_post_likes 
    WHERE community_post_likes.post_id = community_posts.id
);

-- Fix all comment likes counts by recalculating from actual likes
UPDATE community_comments 
SET likes_count = (
    SELECT COUNT(*) 
    FROM community_comment_likes 
    WHERE community_comment_likes.comment_id = community_comments.id
);

-- Fix all post comments counts (already done in migration 12, but ensure it's correct)
UPDATE community_posts 
SET comments_count = (
    SELECT COUNT(*) 
    FROM community_comments 
    WHERE community_comments.post_id = community_posts.id 
    AND community_comments.is_deleted = FALSE 
    AND community_comments.is_flagged = FALSE
);

-- Verify counts for debugging
DO $$
DECLARE
    post_record RECORD;
    actual_likes INTEGER;
    stored_likes INTEGER;
BEGIN
    FOR post_record IN SELECT id, likes_count FROM community_posts LOOP
        SELECT COUNT(*) INTO actual_likes 
        FROM community_post_likes 
        WHERE post_id = post_record.id;
        
        IF actual_likes != post_record.likes_count THEN
            RAISE NOTICE 'Post % has mismatch: DB has %, actual is %', 
                post_record.id, post_record.likes_count, actual_likes;
        END IF;
    END LOOP;
END $$;

SELECT 'Likes count fix completed!' as status;

