-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
-- This ensures users can only access data they're allowed to see
-- Copy this entire file and run it in Supabase SQL Editor AFTER running 01_community_schema.sql
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE community_topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_friends ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_messages ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- COMMUNITY TOPICS POLICIES
-- =====================================================

-- Everyone can view topics
CREATE POLICY "Topics are viewable by everyone" ON community_topics
    FOR SELECT USING (true);

-- =====================================================
-- COMMUNITY POSTS POLICIES
-- =====================================================

-- Everyone can view non-deleted posts
CREATE POLICY "Posts are viewable by everyone" ON community_posts
    FOR SELECT USING (is_deleted = FALSE);

-- Users can insert their own posts
CREATE POLICY "Users can create posts" ON community_posts
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own posts
CREATE POLICY "Users can update own posts" ON community_posts
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete (soft delete) their own posts
CREATE POLICY "Users can delete own posts" ON community_posts
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- COMMUNITY COMMENTS POLICIES
-- =====================================================

-- Everyone can view non-deleted comments on non-deleted posts
CREATE POLICY "Comments are viewable by everyone" ON community_comments
    FOR SELECT USING (
        is_deleted = FALSE AND 
        EXISTS (SELECT 1 FROM community_posts WHERE id = post_id AND is_deleted = FALSE)
    );

-- Users can create comments
CREATE POLICY "Users can create comments" ON community_comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own comments
CREATE POLICY "Users can update own comments" ON community_comments
    FOR UPDATE 
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete own comments" ON community_comments
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- POST LIKES POLICIES
-- =====================================================

-- Users can view all post likes
CREATE POLICY "Post likes are viewable by everyone" ON community_post_likes
    FOR SELECT USING (true);

-- Users can like posts
CREATE POLICY "Users can like posts" ON community_post_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can unlike posts (delete their own likes)
CREATE POLICY "Users can unlike posts" ON community_post_likes
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- COMMENT LIKES POLICIES
-- =====================================================

-- Users can view all comment likes
CREATE POLICY "Comment likes are viewable by everyone" ON community_comment_likes
    FOR SELECT USING (true);

-- Users can like comments
CREATE POLICY "Users can like comments" ON community_comment_likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can unlike comments
CREATE POLICY "Users can unlike comments" ON community_comment_likes
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- POST BOOKMARKS POLICIES
-- =====================================================

-- Users can only view their own bookmarks
CREATE POLICY "Users can view own bookmarks" ON community_post_bookmarks
    FOR SELECT USING (auth.uid() = user_id);

-- Users can create bookmarks
CREATE POLICY "Users can create bookmarks" ON community_post_bookmarks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can delete their own bookmarks
CREATE POLICY "Users can delete own bookmarks" ON community_post_bookmarks
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- FRIENDS POLICIES
-- =====================================================

-- Users can view friendships they're part of
CREATE POLICY "Users can view their friendships" ON community_friends
    FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can create friend requests
CREATE POLICY "Users can create friend requests" ON community_friends
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update friendships they're part of (to accept/block)
CREATE POLICY "Users can update their friendships" ON community_friends
    FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Users can delete friendships they're part of
CREATE POLICY "Users can delete their friendships" ON community_friends
    FOR DELETE USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- =====================================================
-- MESSAGES POLICIES
-- =====================================================

-- Users can view messages they sent or received (if not deleted by them)
CREATE POLICY "Users can view their messages" ON community_messages
    FOR SELECT USING (
        (auth.uid() = sender_id AND is_deleted_by_sender = FALSE) OR
        (auth.uid() = recipient_id AND is_deleted_by_recipient = FALSE)
    );

-- Users can send messages
CREATE POLICY "Users can send messages" ON community_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can update messages they received (to mark as read)
CREATE POLICY "Recipients can update messages" ON community_messages
    FOR UPDATE USING (auth.uid() = recipient_id);

-- Users can delete their messages
CREATE POLICY "Users can delete their messages" ON community_messages
    FOR DELETE USING (auth.uid() = sender_id OR auth.uid() = recipient_id);

