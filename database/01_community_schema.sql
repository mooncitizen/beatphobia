-- =====================================================
-- BEATPHOBIA COMMUNITY FORUM DATABASE SCHEMA
-- =====================================================
-- Copy this entire file and run it in Supabase SQL Editor
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 0. UPDATE PROFILE TABLE FOR USERNAMES
-- =====================================================
-- Ensure username column exists and has proper constraints
ALTER TABLE profile ADD COLUMN IF NOT EXISTS username TEXT;

-- Add unique constraint on username (case-insensitive)
CREATE UNIQUE INDEX IF NOT EXISTS profile_username_unique_lower 
ON profile (LOWER(username));

-- Add check constraint to ensure username is lowercase
ALTER TABLE profile DROP CONSTRAINT IF EXISTS profile_username_lowercase_check;
ALTER TABLE profile ADD CONSTRAINT profile_username_lowercase_check 
CHECK (username = LOWER(username));

-- Add check constraint for username length (3-30 characters)
ALTER TABLE profile DROP CONSTRAINT IF EXISTS profile_username_length_check;
ALTER TABLE profile ADD CONSTRAINT profile_username_length_check 
CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 30);

-- Add check constraint for valid username characters (alphanumeric, underscore, hyphen)
ALTER TABLE profile DROP CONSTRAINT IF EXISTS profile_username_format_check;
ALTER TABLE profile ADD CONSTRAINT profile_username_format_check 
CHECK (username ~ '^[a-z0-9_-]+$');

-- Create index for faster username lookups
CREATE INDEX IF NOT EXISTS profile_username_idx ON profile (username);

-- =====================================================
-- 1. COMMUNITY TOPICS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    post_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default topics
INSERT INTO community_topics (name, slug, description, icon, color) VALUES
    ('Notices', 'notices', 'Official announcements and important updates', 'megaphone.fill', '#F59E0B'),
    ('Phobias', 'phobias', 'Share experiences and support for specific phobias', 'exclamationmark.triangle.fill', '#FF3B30'),
    ('Stress', 'stress', 'Discuss stress management and coping strategies', 'wind', '#FF9500'),
    ('Anxiety', 'anxiety', 'General anxiety discussions and support', 'heart.circle.fill', '#FFCC00'),
    ('General', 'general', 'General discussions about mental health', 'bubble.left.and.bubble.right.fill', '#34C759'),
    ('Success', 'success', 'Celebrate your victories and progress', 'star.fill', '#32ADE6'),
    ('Help', 'help', 'Ask for help and support from the community', 'hand.raised.fill', '#5856D6'),
    ('Question', 'question', 'Ask questions about techniques and strategies', 'questionmark.circle.fill', '#AF52DE'),
    ('Discussion', 'discussion', 'Open discussions on mental health topics', 'person.3.fill', '#FF2D55'),
    ('App Suggestions', 'app-suggestions', 'Share ideas and feedback for the app', 'lightbulb.fill', '#A2845E')
ON CONFLICT (slug) DO NOTHING;

-- =====================================================
-- 2. COMMUNITY POSTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES community_topics(id) ON DELETE CASCADE,
    
    -- Post content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('support', 'success', 'question', 'discussion')),
    
    -- Engagement metrics
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    
    -- Tags (stored as array)
    tags TEXT[] DEFAULT '{}',
    
    -- Moderation
    is_deleted BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    
    -- Trending (set by external systems only)
    trending BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 3. COMMUNITY COMMENTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Comment content
    content TEXT NOT NULL,
    
    -- Optional: reply to another comment (for nested threads)
    parent_comment_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
    
    -- Engagement
    likes_count INTEGER DEFAULT 0,
    
    -- Moderation
    is_deleted BOOLEAN DEFAULT FALSE,
    is_flagged BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- 4. POST LIKES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_post_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a user can only like a post once
    UNIQUE(post_id, user_id)
);

-- =====================================================
-- 5. COMMENT LIKES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_comment_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    comment_id UUID NOT NULL REFERENCES community_comments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a user can only like a comment once
    UNIQUE(comment_id, user_id)
);

-- =====================================================
-- 6. POST BOOKMARKS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_post_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure a user can only bookmark a post once
    UNIQUE(post_id, user_id)
);

-- =====================================================
-- 7. USER FRIENDS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_friends (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure unique friendship pairs
    UNIQUE(user_id, friend_id),
    -- Ensure users can't friend themselves
    CHECK (user_id != friend_id)
);

-- =====================================================
-- 8. DIRECT MESSAGES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS community_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    recipient_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Message content
    content TEXT NOT NULL,
    
    -- Message status
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted_by_sender BOOLEAN DEFAULT FALSE,
    is_deleted_by_recipient BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Topics indexes
CREATE INDEX idx_community_topics_slug ON community_topics(slug);

-- Posts indexes
CREATE INDEX idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX idx_community_posts_topic_id ON community_posts(topic_id);
CREATE INDEX idx_community_posts_category ON community_posts(category);
CREATE INDEX idx_community_posts_created_at ON community_posts(created_at DESC);
CREATE INDEX idx_community_posts_is_deleted ON community_posts(is_deleted) WHERE is_deleted = FALSE;

-- Comments indexes
CREATE INDEX idx_community_comments_post_id ON community_comments(post_id);
CREATE INDEX idx_community_comments_user_id ON community_comments(user_id);
CREATE INDEX idx_community_comments_parent_id ON community_comments(parent_comment_id);

-- Likes indexes
CREATE INDEX idx_post_likes_post_id ON community_post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON community_post_likes(user_id);
CREATE INDEX idx_comment_likes_comment_id ON community_comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON community_comment_likes(user_id);

-- Bookmarks indexes
CREATE INDEX idx_bookmarks_user_id ON community_post_bookmarks(user_id);
CREATE INDEX idx_bookmarks_post_id ON community_post_bookmarks(post_id);

-- Friends indexes
CREATE INDEX idx_friends_user_id ON community_friends(user_id);
CREATE INDEX idx_friends_friend_id ON community_friends(friend_id);
CREATE INDEX idx_friends_status ON community_friends(status);

-- Messages indexes
CREATE INDEX idx_messages_sender_id ON community_messages(sender_id);
CREATE INDEX idx_messages_recipient_id ON community_messages(recipient_id);
CREATE INDEX idx_messages_created_at ON community_messages(created_at DESC);
CREATE INDEX idx_messages_is_read ON community_messages(is_read) WHERE is_read = FALSE;

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
CREATE TRIGGER update_community_posts_updated_at BEFORE UPDATE ON community_posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_comments_updated_at BEFORE UPDATE ON community_comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_community_friends_updated_at BEFORE UPDATE ON community_friends
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- TRIGGERS FOR MAINTAINING ENGAGEMENT COUNTS
-- =====================================================

-- Update post likes count
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_post_likes_count
    AFTER INSERT OR DELETE ON community_post_likes
    FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Update comment likes count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_comment_likes_count
    AFTER INSERT OR DELETE ON community_comment_likes
    FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- Update post comments count
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_post_comments_count
    AFTER INSERT OR DELETE ON community_comments
    FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Update topic post count
CREATE OR REPLACE FUNCTION update_topic_post_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE community_topics SET post_count = post_count + 1 WHERE id = NEW.topic_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE community_topics SET post_count = GREATEST(0, post_count - 1) WHERE id = OLD.topic_id;
    ELSIF TG_OP = 'UPDATE' AND NEW.topic_id != OLD.topic_id THEN
        UPDATE community_topics SET post_count = GREATEST(0, post_count - 1) WHERE id = OLD.topic_id;
        UPDATE community_topics SET post_count = post_count + 1 WHERE id = NEW.topic_id;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_topic_post_count
    AFTER INSERT OR UPDATE OR DELETE ON community_posts
    FOR EACH ROW EXECUTE FUNCTION update_topic_post_count();

