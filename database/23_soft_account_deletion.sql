-- =====================================================
-- SOFT ACCOUNT DELETION WITH 7-DAY GRACE PERIOD
-- =====================================================
-- Marks account for deletion with 7-day countdown
-- Allows users to cancel before permanent deletion

-- Add deletion tracking columns to profile table
ALTER TABLE profile 
ADD COLUMN IF NOT EXISTS marked_for_deletion BOOLEAN DEFAULT FALSE;

ALTER TABLE profile 
ADD COLUMN IF NOT EXISTS deletion_scheduled_at TIMESTAMPTZ;

-- Add index for finding accounts to delete
CREATE INDEX IF NOT EXISTS idx_profile_marked_for_deletion 
ON profile(marked_for_deletion, deletion_scheduled_at)
WHERE marked_for_deletion = TRUE;

-- Create function to mark account for deletion
CREATE OR REPLACE FUNCTION mark_account_for_deletion()
RETURNS TABLE(deletion_date TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_id_to_mark UUID;
    scheduled_deletion TIMESTAMPTZ;
BEGIN
    -- Get the current user's ID
    user_id_to_mark := auth.uid();
    
    IF user_id_to_mark IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Calculate deletion date (7 days from now)
    scheduled_deletion := NOW() + INTERVAL '7 days';
    
    -- Mark profile for deletion
    UPDATE profile 
    SET 
        marked_for_deletion = TRUE,
        deletion_scheduled_at = scheduled_deletion,
        updated_at = NOW()
    WHERE id = user_id_to_mark;
    
    RAISE LOG 'Account marked for deletion: % (scheduled for: %)', user_id_to_mark, scheduled_deletion;
    
    -- Return the scheduled deletion date
    RETURN QUERY SELECT scheduled_deletion;
END;
$$;

-- Create function to cancel account deletion
CREATE OR REPLACE FUNCTION cancel_account_deletion()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_id_to_restore UUID;
BEGIN
    -- Get the current user's ID
    user_id_to_restore := auth.uid();
    
    IF user_id_to_restore IS NULL THEN
        RAISE EXCEPTION 'Not authenticated';
    END IF;
    
    -- Unmark profile for deletion
    UPDATE profile 
    SET 
        marked_for_deletion = FALSE,
        deletion_scheduled_at = NULL,
        updated_at = NOW()
    WHERE id = user_id_to_restore;
    
    RAISE LOG 'Account deletion cancelled for user: %', user_id_to_restore;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION mark_account_for_deletion() TO authenticated;
GRANT EXECUTE ON FUNCTION cancel_account_deletion() TO authenticated;

-- Create view to find accounts ready for deletion (for your cleanup job)
CREATE OR REPLACE VIEW accounts_to_delete AS
SELECT 
    id,
    name,
    username,
    deletion_scheduled_at,
    AGE(NOW(), deletion_scheduled_at) as time_past_deadline
FROM profile
WHERE 
    marked_for_deletion = TRUE 
    AND deletion_scheduled_at IS NOT NULL
    AND deletion_scheduled_at <= NOW();

-- Add comments
COMMENT ON COLUMN profile.marked_for_deletion IS 'User has requested account deletion. If TRUE, account will be deleted after deletion_scheduled_at date.';
COMMENT ON COLUMN profile.deletion_scheduled_at IS 'Date when account will be permanently deleted (7 days after user requested deletion).';
COMMENT ON FUNCTION mark_account_for_deletion() IS 'Marks user account for deletion with 7-day grace period.';
COMMENT ON FUNCTION cancel_account_deletion() IS 'Cancels pending account deletion before the 7-day period expires.';

SELECT 'Soft deletion system created! Accounts will be marked for deletion with 7-day grace period.' as status;

-- NOTE: You'll need to create a scheduled function or cron job to actually delete accounts
-- where deletion_scheduled_at <= NOW() and marked_for_deletion = TRUE

