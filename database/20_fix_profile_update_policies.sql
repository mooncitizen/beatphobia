-- =====================================================
-- FIX PROFILE TABLE RLS POLICIES
-- =====================================================
-- Ensures users can update their own profile data including profile image

-- Drop existing profile policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON profile;
DROP POLICY IF EXISTS "Users can insert own profile" ON profile;
DROP POLICY IF EXISTS "Users can update own profile" ON profile;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON profile;

-- Enable RLS on profile table
ALTER TABLE profile ENABLE ROW LEVEL SECURITY;

-- Everyone can view profiles (for community features)
CREATE POLICY "Public profiles are viewable by everyone" 
ON profile FOR SELECT
USING (true);

-- Users can insert their own profile
CREATE POLICY "Users can insert own profile"
ON profile FOR INSERT
WITH CHECK (auth.uid() = id);

-- Users can update their own profile (including profile_image_url)
CREATE POLICY "Users can update own profile"
ON profile FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profile';

SELECT 'Profile RLS policies updated successfully!' as status;

