-- =====================================================
-- JOURNAL ENTRIES TABLE
-- =====================================================
-- This table stores journal entries with cloud sync support

CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Journal content
    mood TEXT NOT NULL CHECK (mood IN ('happy', 'angry', 'excited', 'stressed', 'sad', 'none')),
    text TEXT NOT NULL,
    entry_date TIMESTAMPTZ NOT NULL, -- The date the journal entry is for
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_journal_entries_user_id ON journal_entries(user_id);
CREATE INDEX idx_journal_entries_entry_date ON journal_entries(entry_date DESC);
CREATE INDEX idx_journal_entries_user_date ON journal_entries(user_id, entry_date DESC);
CREATE INDEX idx_journal_entries_is_deleted ON journal_entries(is_deleted) WHERE is_deleted = FALSE;

-- =====================================================
-- TRIGGER FOR AUTO-UPDATING TIMESTAMPS
-- =====================================================
CREATE TRIGGER update_journal_entries_updated_at 
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================
ALTER TABLE journal_entries ENABLE ROW LEVEL SECURITY;

-- Users can view their own non-deleted journal entries
CREATE POLICY "Users can view own journal entries" ON journal_entries
    FOR SELECT
    USING (auth.uid() = user_id AND is_deleted = FALSE);

-- Users can insert their own journal entries
CREATE POLICY "Users can insert own journal entries" ON journal_entries
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own journal entries
CREATE POLICY "Users can update own journal entries" ON journal_entries
    FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Users can soft-delete their own journal entries
CREATE POLICY "Users can delete own journal entries" ON journal_entries
    FOR UPDATE
    USING (auth.uid() = user_id AND is_deleted = FALSE)
    WITH CHECK (auth.uid() = user_id);


