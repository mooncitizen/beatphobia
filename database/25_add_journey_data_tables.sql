-- =====================================================
-- JOURNEY DATA TABLES MIGRATION
-- =====================================================
-- This script adds journey data tables to existing journeys schema
-- Run this if you already have the journeys table from 24_journey_sync_schema.sql

-- =====================================================
-- JOURNEY DATA TABLE
-- =====================================================
-- This table stores journey tracking data (location points, checkpoints, etc.)

CREATE TABLE IF NOT EXISTS journey_data (
    id UUID PRIMARY KEY,
    journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Journey tracking data
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ,
    distance DOUBLE PRECISION DEFAULT 0.0, -- in meters
    duration INTEGER DEFAULT 0, -- in seconds
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- PATH POINTS TABLE
-- =====================================================
-- This table stores GPS location points for journeys

CREATE TABLE IF NOT EXISTS path_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journey_data_id UUID NOT NULL REFERENCES journey_data(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Location data
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- FEELING CHECKPOINTS TABLE
-- =====================================================
-- This table stores emotion/feeling checkpoints during journeys

CREATE TABLE IF NOT EXISTS feeling_checkpoints (
    id UUID PRIMARY KEY,
    journey_data_id UUID NOT NULL REFERENCES journey_data(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Checkpoint data
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    feeling TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
-- Journey data indexes
CREATE INDEX IF NOT EXISTS idx_journey_data_journey_id ON journey_data(journey_id);
CREATE INDEX IF NOT EXISTS idx_journey_data_user_id ON journey_data(user_id);
CREATE INDEX IF NOT EXISTS idx_journey_data_start_time ON journey_data(start_time DESC);

-- Path points indexes
CREATE INDEX IF NOT EXISTS idx_path_points_journey_data_id ON path_points(journey_data_id);
CREATE INDEX IF NOT EXISTS idx_path_points_timestamp ON path_points(timestamp);
CREATE INDEX IF NOT EXISTS idx_path_points_user_id ON path_points(user_id);

-- Feeling checkpoints indexes
CREATE INDEX IF NOT EXISTS idx_feeling_checkpoints_journey_data_id ON feeling_checkpoints(journey_data_id);
CREATE INDEX IF NOT EXISTS idx_feeling_checkpoints_timestamp ON feeling_checkpoints(timestamp);
CREATE INDEX IF NOT EXISTS idx_feeling_checkpoints_user_id ON feeling_checkpoints(user_id);

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================
CREATE TRIGGER update_journey_data_updated_at 
    BEFORE UPDATE ON journey_data
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- RLS POLICIES FOR JOURNEY DATA
-- =====================================================
ALTER TABLE journey_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own journey data" ON journey_data
    FOR SELECT
    USING (auth.uid() = user_id AND is_deleted = FALSE);

CREATE POLICY "Users can insert own journey data" ON journey_data
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own journey data" ON journey_data
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own journey data" ON journey_data
    FOR UPDATE
    USING (auth.uid() = user_id AND is_deleted = FALSE)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- RLS POLICIES FOR PATH POINTS
-- =====================================================
ALTER TABLE path_points ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own path points" ON path_points
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own path points" ON path_points
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own path points" ON path_points
    FOR DELETE
    USING (auth.uid() = user_id);

-- =====================================================
-- RLS POLICIES FOR FEELING CHECKPOINTS
-- =====================================================
ALTER TABLE feeling_checkpoints ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own feeling checkpoints" ON feeling_checkpoints
    FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own feeling checkpoints" ON feeling_checkpoints
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own feeling checkpoints" ON feeling_checkpoints
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own feeling checkpoints" ON feeling_checkpoints
    FOR DELETE
    USING (auth.uid() = user_id);

