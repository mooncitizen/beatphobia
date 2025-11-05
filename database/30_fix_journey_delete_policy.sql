-- =====================================================
-- FIX JOURNEY DELETE RLS POLICY
-- =====================================================
-- The current "delete" policy blocks setting is_deleted = true
-- because it requires is_deleted = FALSE in the USING clause.
-- We need to remove that restriction.

-- CRITICAL: UPDATE policies need SELECT access to the row.
-- So we need to allow users to SELECT their own deleted rows
-- (even though they won't show in the app - we filter them)

-- Drop the problematic delete policy that blocks is_deleted updates
DROP POLICY IF EXISTS "Users can delete own journeys" ON journeys;
DROP POLICY IF EXISTS "Users can soft delete own journeys" ON journeys;

-- Update SELECT policy to allow seeing own deleted rows (for UPDATE purposes)
DROP POLICY IF EXISTS "Users can view own journeys" ON journeys;

CREATE POLICY "Users can view own journeys" ON journeys
    FOR SELECT
    USING (auth.uid() = user_id);  -- Removed is_deleted = FALSE restriction

-- Drop and recreate the update policy to ensure it allows is_deleted updates
DROP POLICY IF EXISTS "Users can update own journeys" ON journeys;

CREATE POLICY "Users can update own journeys" ON journeys
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Do the same for journey_data
DROP POLICY IF EXISTS "Users can delete own journey data" ON journey_data;
DROP POLICY IF EXISTS "Users can soft delete own journey data" ON journey_data;

-- Update SELECT policy for journey_data
DROP POLICY IF EXISTS "Users can view own journey data" ON journey_data;

CREATE POLICY "Users can view own journey data" ON journey_data
    FOR SELECT
    USING (auth.uid() = user_id);  -- Removed is_deleted = FALSE restriction

-- Drop and recreate the journey_data update policy
DROP POLICY IF EXISTS "Users can update own journey data" ON journey_data;

CREATE POLICY "Users can update own journey data" ON journey_data
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

