-- =====================================================
-- NOTIFICATIONS TABLE
-- =====================================================
-- Table to store notifications for users
-- This can be used for replies, messages, friend requests, etc.
-- =====================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- From/To users
    "from" UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    "to" UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Notification type
    type TEXT NOT NULL CHECK (type IN (
        'reply',           -- Reply to post or comment
        'message',         -- Direct message
        'friend_request',  -- Friend request
        'like',            -- Post or comment like
        'mention',         -- User mentioned in post/comment
        'other'            -- Other notification types
    )),
    
    -- Related content (nullable - depends on type)
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
    reply_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
    
    -- Date
    date TIMESTAMPTZ DEFAULT NOW(),
    
    -- Notification status
    read BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_notifications_to_user_id ON notifications("to");
CREATE INDEX idx_notifications_to_user_read ON notifications("to", read);
CREATE INDEX idx_notifications_date ON notifications(date DESC);
CREATE INDEX idx_notifications_type ON notifications(type);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view their own notifications
CREATE POLICY "Users can view own notifications" ON notifications
    FOR SELECT USING (auth.uid() = "to");

-- System can create notifications (via triggers)
CREATE POLICY "System can create notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications" ON notifications
    FOR UPDATE 
    USING (auth.uid() = "to")
    WITH CHECK (auth.uid() = "to");

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications" ON notifications
    FOR DELETE USING (auth.uid() = "to");

