-- =====================================================
-- ADD HESITATION POINTS JSON COLUMN
-- =====================================================
-- This migration adds hesitation_points_json column to journey_data
-- to store hesitation detection data as JSON arrays
-- =====================================================

-- Add hesitation_points_json column to journey_data table
ALTER TABLE journey_data 
ADD COLUMN IF NOT EXISTS hesitation_points_json JSONB DEFAULT '[]'::jsonb;

-- Create index for JSON hesitation points (optional, for queries)
CREATE INDEX IF NOT EXISTS idx_journey_data_hesitation_points_gin 
ON journey_data USING GIN (hesitation_points_json);

-- Note: Existing journey_data rows will have an empty array [] as default
-- New hesitation points will be stored in this JSON column going forward
