-- =====================================================
-- ADD ATTACHMENTS TABLE FOR POSTS AND COMMENTS
-- =====================================================
-- This creates a flexible attachments system that can be used
-- for posts, comments, and other features in the future

-- =====================================================
-- 1. CREATE ATTACHMENTS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS community_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign keys (nullable to allow different attachment sources)
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Attachment metadata
    file_url TEXT NOT NULL,
    file_type TEXT NOT NULL CHECK (file_type IN ('image', 'video', 'document')),
    file_size INTEGER, -- Size in bytes
    mime_type TEXT,    -- e.g., "image/jpeg", "image/png"
    
    -- Image-specific metadata
    width INTEGER,
    height INTEGER,
    
    -- Moderation
    is_nsfw BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure attachment belongs to either a post or a comment, not both
    CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    )
);

-- =====================================================
-- 2. ADD INDEXES
-- =====================================================

CREATE INDEX idx_attachments_post_id ON community_attachments(post_id) WHERE post_id IS NOT NULL;
CREATE INDEX idx_attachments_comment_id ON community_attachments(comment_id) WHERE comment_id IS NOT NULL;
CREATE INDEX idx_attachments_user_id ON community_attachments(user_id);
CREATE INDEX idx_attachments_file_type ON community_attachments(file_type);
CREATE INDEX idx_attachments_is_nsfw ON community_attachments(is_nsfw) WHERE is_nsfw = TRUE;

-- =====================================================
-- 3. ROW LEVEL SECURITY POLICIES
-- =====================================================

ALTER TABLE community_attachments ENABLE ROW LEVEL SECURITY;

-- Everyone can view non-deleted, non-flagged attachments
CREATE POLICY "Attachments are viewable by everyone" ON community_attachments
    FOR SELECT USING (
        is_deleted = FALSE AND is_flagged = FALSE
    );

-- Users can upload attachments
CREATE POLICY "Users can upload attachments" ON community_attachments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own attachments (e.g., mark as NSFW)
CREATE POLICY "Users can update own attachments" ON community_attachments
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own attachments
CREATE POLICY "Users can delete own attachments" ON community_attachments
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- 4. HELPER FUNCTIONS
-- =====================================================

-- Function to get attachment count for a post
CREATE OR REPLACE FUNCTION get_post_attachment_count(p_post_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM community_attachments
        WHERE post_id = p_post_id
        AND is_deleted = FALSE
        AND is_flagged = FALSE
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get attachment count for a comment
CREATE OR REPLACE FUNCTION get_comment_attachment_count(p_comment_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM community_attachments
        WHERE comment_id = p_comment_id
        AND is_deleted = FALSE
        AND is_flagged = FALSE
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- =====================================================
-- 5. STORAGE BUCKET SETUP INSTRUCTIONS
-- =====================================================

-- You need to create the "community-attachments" bucket in Supabase Dashboard → Storage
-- Then run these policies in the SQL editor:

/*
-- Allow authenticated users to upload attachments
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-attachments');

-- Allow everyone to view attachments
CREATE POLICY "Anyone can view attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'community-attachments');

-- Allow users to delete their own attachments (based on user_id in path)
CREATE POLICY "Users can delete own attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'community-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
*/

-- =====================================================
-- 6. USAGE CONSTRAINTS
-- =====================================================

-- Add a function to enforce max 3 attachments per post
CREATE OR REPLACE FUNCTION check_max_attachments_per_post()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.post_id IS NOT NULL THEN
        IF (SELECT COUNT(*) FROM community_attachments 
            WHERE post_id = NEW.post_id AND is_deleted = FALSE) >= 3 THEN
            RAISE EXCEPTION 'Maximum 3 attachments allowed per post';
        END IF;
    END IF;
    
    IF NEW.comment_id IS NOT NULL THEN
        IF (SELECT COUNT(*) FROM community_attachments 
            WHERE comment_id = NEW.comment_id AND is_deleted = FALSE) >= 3 THEN
            RAISE EXCEPTION 'Maximum 3 attachments allowed per comment';
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_check_max_attachments
    BEFORE INSERT ON community_attachments
    FOR EACH ROW EXECUTE FUNCTION check_max_attachments_per_post();

COMMENT ON TABLE community_attachments IS 'Stores attachments (images, videos, documents) for posts and comments. Max 3 per post/comment.';

SELECT 'Attachments table created successfully! Remember to create the "community-attachments" bucket in Supabase Dashboard.' as status;

