-- =====================================================
-- ACCOUNT DELETION FUNCTION
-- =====================================================
-- Creates a function that allows users to delete their own account
-- Complies with Apple's account deletion requirements

-- Create function to delete user account and all associated data
CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER -- Run with elevated privileges
SET search_path = public
AS $$
DECLARE
    user_id_to_delete UUID;
BEGIN
    -- Get the current user's ID
    user_id_to_delete := auth.uid();
    
    IF user_id_to_delete IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    RAISE LOG 'Deleting account for user: %', user_id_to_delete;
    
    -- Delete user data in order (respecting foreign keys)
    -- Community data
    DELETE FROM community_post_bookmarks WHERE user_id = user_id_to_delete;
    DELETE FROM community_comment_likes WHERE user_id = user_id_to_delete;
    DELETE FROM community_post_likes WHERE user_id = user_id_to_delete;
    DELETE FROM community_attachments WHERE user_id = user_id_to_delete;
    DELETE FROM community_comments WHERE user_id = user_id_to_delete;
    DELETE FROM community_posts WHERE user_id = user_id_to_delete;
    DELETE FROM community_messages WHERE sender_id = user_id_to_delete OR recipient_id = user_id_to_delete;
    DELETE FROM community_friends WHERE user_id = user_id_to_delete OR friend_id = user_id_to_delete;
    
    -- Journal data (if exists)
    -- DELETE FROM journal_entries WHERE user_id = user_id_to_delete;
    
    -- Profile (this will be deleted when auth user is deleted)
    DELETE FROM profile WHERE id = user_id_to_delete;
    
    -- Delete from auth.users (this is the final step)
    DELETE FROM auth.users WHERE id = user_id_to_delete;
    
    RAISE LOG 'Account deleted successfully for user: %', user_id_to_delete;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;

-- Add comment
COMMENT ON FUNCTION delete_user_account() IS 'Allows users to delete their own account and all associated data. Called from app Profile settings.';

SELECT 'Account deletion function created successfully!' as status;

