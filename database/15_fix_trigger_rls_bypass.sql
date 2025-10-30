-- =====================================================
-- FIX TRIGGERS TO BYPASS RLS
-- =====================================================
-- Database triggers need to bypass RLS to update counts on any post/comment
-- This migration recreates the trigger functions with SECURITY DEFINER

-- =====================================================
-- POST LIKES COUNT TRIGGER (BYPASS RLS)
-- =====================================================

DROP TRIGGER IF EXISTS trigger_post_likes_count ON community_post_likes;
DROP FUNCTION IF EXISTS update_post_likes_count();

-- Create function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.post_id;
        
        RAISE LOG 'Post % likes_count incremented', NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts 
        SET likes_count = GREATEST(0, likes_count - 1) 
        WHERE id = OLD.post_id;
        
        RAISE LOG 'Post % likes_count decremented', OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_post_likes_count
    AFTER INSERT OR DELETE ON community_post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- =====================================================
-- COMMENT LIKES COUNT TRIGGER (BYPASS RLS)
-- =====================================================

DROP TRIGGER IF EXISTS trigger_comment_likes_count ON community_comment_likes;
DROP FUNCTION IF EXISTS update_comment_likes_count();

-- Create function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_comments 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.comment_id;
        
        RAISE LOG 'Comment % likes_count incremented', NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_comments 
        SET likes_count = GREATEST(0, likes_count - 1) 
        WHERE id = OLD.comment_id;
        
        RAISE LOG 'Comment % likes_count decremented', OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_comment_likes_count
    AFTER INSERT OR DELETE ON community_comment_likes
    FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- =====================================================
-- POST COMMENTS COUNT TRIGGER (BYPASS RLS)
-- =====================================================

DROP TRIGGER IF EXISTS trigger_post_comments_count ON community_comments;
DROP FUNCTION IF EXISTS update_post_comments_count();

-- Create function with SECURITY DEFINER to bypass RLS
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER 
SECURITY DEFINER -- This allows the function to bypass RLS
SET search_path = public
AS $$
DECLARE
    target_post_id UUID;
BEGIN
    -- Get the post_id (could be from NEW or OLD depending on operation)
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
    
    RAISE LOG 'Post % comments_count updated', target_post_id;
    
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_post_comments_count
    AFTER INSERT OR UPDATE OR DELETE ON community_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- =====================================================
-- VERIFY TRIGGERS ARE WORKING
-- =====================================================

-- Test the triggers (optional, for verification)
DO $$
DECLARE
    test_result TEXT;
BEGIN
    -- Check if triggers exist
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_post_likes_count'
    ) THEN
        RAISE NOTICE '✅ trigger_post_likes_count exists';
    ELSE
        RAISE WARNING '❌ trigger_post_likes_count missing';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_comment_likes_count'
    ) THEN
        RAISE NOTICE '✅ trigger_comment_likes_count exists';
    ELSE
        RAISE WARNING '❌ trigger_comment_likes_count missing';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM pg_trigger 
        WHERE tgname = 'trigger_post_comments_count'
    ) THEN
        RAISE NOTICE '✅ trigger_post_comments_count exists';
    ELSE
        RAISE WARNING '❌ trigger_post_comments_count missing';
    END IF;
END $$;

SELECT 'Triggers recreated with RLS bypass (SECURITY DEFINER)' as status;

