-- =====================================================
-- OPTIMIZE PATH POINTS STORAGE
-- =====================================================
-- This migration optimizes path points storage by storing them
-- as JSON arrays in journey_data instead of separate rows
-- =====================================================

-- Add path_points_json column to journey_data table
ALTER TABLE journey_data 
ADD COLUMN IF NOT EXISTS path_points_json JSONB DEFAULT '[]'::jsonb;

-- Migrate existing path_points to JSON array
UPDATE journey_data 
SET path_points_json = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'latitude', latitude,
            'longitude', longitude,
            'timestamp', timestamp
        ) ORDER BY timestamp
    )
    FROM path_points
    WHERE path_points.journey_data_id = journey_data.id
)
WHERE EXISTS (
    SELECT 1 FROM path_points 
    WHERE path_points.journey_data_id = journey_data.id
);

-- Create index for JSON path points (optional, for queries)
CREATE INDEX IF NOT EXISTS idx_journey_data_path_points_gin 
ON journey_data USING GIN (path_points_json);

-- Add checkpoints_json column to journey_data table
ALTER TABLE journey_data 
ADD COLUMN IF NOT EXISTS checkpoints_json JSONB DEFAULT '[]'::jsonb;

-- Migrate existing checkpoints to JSON array
UPDATE journey_data 
SET checkpoints_json = (
    SELECT jsonb_agg(
        jsonb_build_object(
            'id', id,
            'latitude', latitude,
            'longitude', longitude,
            'feeling', feeling,
            'timestamp', timestamp
        ) ORDER BY timestamp
    )
    FROM feeling_checkpoints
    WHERE feeling_checkpoints.journey_data_id = journey_data.id
)
WHERE EXISTS (
    SELECT 1 FROM feeling_checkpoints 
    WHERE feeling_checkpoints.journey_data_id = journey_data.id
);

-- Create index for JSON checkpoints (optional)
CREATE INDEX IF NOT EXISTS idx_journey_data_checkpoints_gin 
ON journey_data USING GIN (checkpoints_json);

-- Note: path_points and feeling_checkpoints tables are kept for now
-- for backward compatibility, but new data should use JSON columns
-- Old tables can be dropped after verifying migration worked correctly

