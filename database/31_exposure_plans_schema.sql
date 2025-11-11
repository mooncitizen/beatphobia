-- =====================================================
-- EXPOSURE PLANS SCHEMA
-- =====================================================
-- This schema creates tables for exposure plans and targets
-- =====================================================

-- =====================================================
-- EXPOSURE PLANS TABLE
-- =====================================================
-- This table stores exposure plan metadata with cloud sync support

CREATE TABLE IF NOT EXISTS exposure_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Plan metadata
    name TEXT NOT NULL,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- EXPOSURE TARGETS TABLE
-- =====================================================
-- This table stores targets for exposure plans

CREATE TABLE IF NOT EXISTS exposure_targets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES exposure_plans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Target data
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    wait_time_seconds INTEGER NOT NULL DEFAULT 0,
    order_index INTEGER NOT NULL DEFAULT 0,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- MODIFY JOURNEYS TABLE
-- =====================================================
-- Add linked_plan_id column to journeys table

ALTER TABLE journeys ADD COLUMN IF NOT EXISTS linked_plan_id UUID REFERENCES exposure_plans(id) ON DELETE SET NULL;

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_exposure_plans_user_id ON exposure_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_exposure_plans_created_at ON exposure_plans(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exposure_plans_user_created ON exposure_plans(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_exposure_plans_is_deleted ON exposure_plans(is_deleted) WHERE is_deleted = FALSE;

-- Exposure targets indexes
CREATE INDEX IF NOT EXISTS idx_exposure_targets_plan_id ON exposure_targets(plan_id);
CREATE INDEX IF NOT EXISTS idx_exposure_targets_user_id ON exposure_targets(user_id);
CREATE INDEX IF NOT EXISTS idx_exposure_targets_order_index ON exposure_targets(plan_id, order_index);
CREATE INDEX IF NOT EXISTS idx_exposure_targets_is_deleted ON exposure_targets(is_deleted) WHERE is_deleted = FALSE;

-- Journey linked plan index
CREATE INDEX IF NOT EXISTS idx_journeys_linked_plan_id ON journeys(linked_plan_id) WHERE linked_plan_id IS NOT NULL;

-- =====================================================
-- TRIGGERS FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================
CREATE TRIGGER update_exposure_plans_updated_at 
    BEFORE UPDATE ON exposure_plans
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_exposure_targets_updated_at 
    BEFORE UPDATE ON exposure_targets
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
ALTER TABLE exposure_plans ENABLE ROW LEVEL SECURITY;

-- Users can view their own non-deleted plans
CREATE POLICY "Users can view own exposure plans" ON exposure_plans
    FOR SELECT
    USING (auth.uid() = user_id AND is_deleted = FALSE);

-- Users can insert their own plans
CREATE POLICY "Users can insert own exposure plans" ON exposure_plans
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own plans
CREATE POLICY "Users can update own exposure plans" ON exposure_plans
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can soft-delete their own plans
CREATE POLICY "Users can delete own exposure plans" ON exposure_plans
    FOR UPDATE
    USING (auth.uid() = user_id AND is_deleted = FALSE)
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- RLS POLICIES FOR EXPOSURE TARGETS
-- =====================================================
ALTER TABLE exposure_targets ENABLE ROW LEVEL SECURITY;

-- Users can view their own non-deleted targets
CREATE POLICY "Users can view own exposure targets" ON exposure_targets
    FOR SELECT
    USING (auth.uid() = user_id AND is_deleted = FALSE);

-- Users can insert their own targets
CREATE POLICY "Users can insert own exposure targets" ON exposure_targets
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own targets
CREATE POLICY "Users can update own exposure targets" ON exposure_targets
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can soft-delete their own targets
CREATE POLICY "Users can delete own exposure targets" ON exposure_targets
    FOR UPDATE
    USING (auth.uid() = user_id AND is_deleted = FALSE)
    WITH CHECK (auth.uid() = user_id);

