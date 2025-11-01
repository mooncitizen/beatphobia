-- =====================================================
-- CONTENT REPORTS TABLE
-- =====================================================
-- This table stores user reports/flags for posts and comments
-- Copy this entire file and run it in Supabase SQL Editor
-- =====================================================

-- Create content_reports table
CREATE TABLE IF NOT EXISTS content_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who is reporting
    reporter_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- What is being reported (one of these must be set)
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
    
    -- Report reason
    reason TEXT NOT NULL CHECK (reason IN (
        'spam',
        'harassment',
        'hate_speech',
        'inappropriate_content',
        'misinformation',
        'self_harm',
        'violence',
        'other'
    )),
    
    -- Optional additional details
    details TEXT,
    
    -- Status tracking
    status TEXT NOT NULL CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')) DEFAULT 'pending',
    
    -- Admin review info (optional)
    reviewed_by UUID REFERENCES profile(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    admin_notes TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure either post_id or comment_id is set, but not both
    CHECK (
        (post_id IS NOT NULL AND comment_id IS NULL) OR
        (post_id IS NULL AND comment_id IS NOT NULL)
    ),
    
    -- Prevent duplicate reports from same user for same content
    UNIQUE(reporter_id, post_id, comment_id)
);

-- =====================================================
-- USER BLOCKS TABLE
-- =====================================================
-- This table stores blocked users
-- =====================================================

-- Create user_blocks table
CREATE TABLE IF NOT EXISTS user_blocks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who is blocking
    blocker_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Who is being blocked
    blocked_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Optional reason
    reason TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure users can't block themselves
    CHECK (blocker_id != blocked_id),
    
    -- Ensure unique block relationships
    UNIQUE(blocker_id, blocked_id)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Content reports indexes
CREATE INDEX idx_content_reports_reporter_id ON content_reports(reporter_id);
CREATE INDEX idx_content_reports_post_id ON content_reports(post_id) WHERE post_id IS NOT NULL;
CREATE INDEX idx_content_reports_comment_id ON content_reports(comment_id) WHERE comment_id IS NOT NULL;
CREATE INDEX idx_content_reports_status ON content_reports(status);
CREATE INDEX idx_content_reports_created_at ON content_reports(created_at DESC);

-- User blocks indexes
CREATE INDEX idx_user_blocks_blocker_id ON user_blocks(blocker_id);
CREATE INDEX idx_user_blocks_blocked_id ON user_blocks(blocked_id);
CREATE INDEX idx_user_blocks_created_at ON user_blocks(created_at DESC);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================

CREATE TRIGGER update_content_reports_updated_at BEFORE UPDATE ON content_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on tables
ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- CONTENT REPORTS POLICIES
-- =====================================================

-- Users can view their own reports
CREATE POLICY "Users can view own reports" ON content_reports
    FOR SELECT USING (auth.uid() = reporter_id);

-- Admins can view all reports
CREATE POLICY "Admins can view all reports" ON content_reports
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profile 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Users can create reports
CREATE POLICY "Users can create reports" ON content_reports
    FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Only admins can update reports
CREATE POLICY "Admins can update reports" ON content_reports
    FOR UPDATE 
    USING (
        EXISTS (
            SELECT 1 FROM profile 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM profile 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- Users cannot delete reports (only admins can)
-- No DELETE policy means users cannot delete

-- =====================================================
-- USER BLOCKS POLICIES
-- =====================================================

-- Users can view blocks they created
CREATE POLICY "Users can view own blocks" ON user_blocks
    FOR SELECT USING (auth.uid() = blocker_id);

-- Users can create blocks
CREATE POLICY "Users can create blocks" ON user_blocks
    FOR INSERT WITH CHECK (auth.uid() = blocker_id);

-- Users can unblock (delete their own blocks)
CREATE POLICY "Users can unblock" ON user_blocks
    FOR DELETE USING (auth.uid() = blocker_id);

-- Users cannot update blocks
-- No UPDATE policy means users cannot modify blocks

