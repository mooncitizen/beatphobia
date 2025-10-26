-- =====================================================
-- Migration: Add Trending Column to Community Posts
-- =====================================================
-- This migration adds a 'trending' column to the community_posts table.
-- The trending flag is set by external systems (not by the app).

-- Add trending column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'community_posts' 
        AND column_name = 'trending'
    ) THEN
        ALTER TABLE community_posts 
        ADD COLUMN trending BOOLEAN DEFAULT FALSE;
        
        RAISE NOTICE 'Successfully added trending column to community_posts table';
    ELSE
        RAISE NOTICE 'trending column already exists in community_posts table';
    END IF;
END $$;

-- Create an index on trending for faster queries
CREATE INDEX IF NOT EXISTS idx_community_posts_trending 
ON community_posts(trending) 
WHERE trending = TRUE;

-- Add a comment explaining the column
COMMENT ON COLUMN community_posts.trending IS 'Flag indicating if a post is trending. Set by external systems only, not by the app.';

