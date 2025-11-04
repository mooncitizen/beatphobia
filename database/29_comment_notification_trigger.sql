-- =====================================================
-- COMMENT NOTIFICATION TRIGGER
-- =====================================================
-- This trigger creates a notification when someone replies
-- to a post or comment
-- =====================================================

-- Drop existing trigger first (it depends on the function)
DROP TRIGGER IF EXISTS trigger_notify_comment_reply ON community_comments;

-- Drop existing function if it exists (cleanup from previous implementation)
DROP FUNCTION IF EXISTS notify_comment_reply();

-- Create function to create notification when comment is created
CREATE FUNCTION notify_comment_reply()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_recipient_user_id UUID;
BEGIN
  -- Skip notifications for deleted comments
  IF NEW.is_deleted = TRUE THEN
    RETURN NEW;
  END IF;
  
  -- Check if this is a reply to a post or to another comment
  IF NEW.parent_comment_id IS NULL THEN
    -- Reply to a post
    -- Get post author
    SELECT user_id INTO v_recipient_user_id
    FROM community_posts
    WHERE id = NEW.post_id;
    
    -- Don't notify if replying to own post
    IF v_recipient_user_id = NEW.user_id THEN
      RETURN NEW;
    END IF;
    
    -- Create notification for post reply
    INSERT INTO notifications (
      "from",
      "to",
      type,
      post_id,
      reply_id
    ) VALUES (
      NEW.user_id,
      v_recipient_user_id,
      'reply',
      NEW.post_id,
      NEW.id
    );
  ELSE
    -- Reply to a comment
    -- Get parent comment author
    SELECT user_id INTO v_recipient_user_id
    FROM community_comments
    WHERE id = NEW.parent_comment_id;
    
    -- Don't notify if replying to own comment
    IF v_recipient_user_id = NEW.user_id THEN
      RETURN NEW;
    END IF;
    
    -- Create notification for comment reply
    INSERT INTO notifications (
      "from",
      "to",
      type,
      post_id,
      reply_id
    ) VALUES (
      NEW.user_id,
      v_recipient_user_id,
      'reply',
      NEW.post_id,
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$;

-- Create trigger (already dropped above, so just create)
CREATE TRIGGER trigger_notify_comment_reply
  AFTER INSERT ON community_comments
  FOR EACH ROW
  WHEN (NEW.is_deleted = FALSE)
  EXECUTE FUNCTION notify_comment_reply();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION notify_comment_reply() TO authenticated;

