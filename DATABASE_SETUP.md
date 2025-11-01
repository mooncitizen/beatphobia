# Database Setup & Architecture

This document describes the complete database setup, models, connections, and sync architecture for the BeatPhobia iOS app.

---

## Table of Contents

1. [Overview](#overview)
2. [Local Database (Realm)](#local-database-realm)
3. [Cloud Database (Supabase)](#cloud-database-supabase)
4. [Database Models](#database-models)
5. [Sync Services](#sync-services)
6. [Row Level Security (RLS)](#row-level-security-rls)
7. [Storage Buckets](#storage-buckets)
8. [Connection Configuration](#connection-configuration)
9. [Schema Migrations](#schema-migrations)
10. [Data Relationships](#data-relationships)

---

## Overview

The BeatPhobia app uses a **hybrid database architecture**:

- **Local Database**: Realm (offline-first, primary storage)
- **Cloud Database**: Supabase PostgreSQL (cloud sync, Pro feature)
- **Storage**: Supabase Storage (images, attachments)

### Key Principles

1. **Offline-First**: All data is stored locally in Realm first
2. **Cloud Sync**: Pro users get automatic bidirectional sync to Supabase
3. **Data Ownership**: Users can only access their own data (RLS enforced)
4. **Soft Deletes**: Deleted records are marked, not permanently removed

---

## Local Database (Realm)

### Configuration

**File**: `beatphobia/Config/RealmConfiguration.swift`

- **Current Schema Version**: 5
- **Location**: Local device storage (managed by Realm)
- **Migration**: Automatic via migration blocks

### Schema Versions

1. **Version 1**: Initial schema
2. **Version 2**: Added sync properties to `JournalEntryModel`
3. **Version 3**: Added location tracking models (`JourneyRealm`, `PathPointRealm`, `FeelingCheckpointRealm`)
4. **Version 4**: Added sync properties to `Journey` model
5. **Version 5**: Added sync properties to `JourneyRealm` model

### Realm Models

#### JournalEntryModel

```swift
class JournalEntryModel: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var mood: Mood // Enum: happy, angry, excited, stressed, sad, none
    @Persisted var text: String
    @Persisted var date: Date
    
    // Sync metadata
    @Persisted var isSynced: Bool = false
    @Persisted var needsSync: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted var lastSyncedAt: Date?
    @Persisted var updatedAt: Date
}
```

#### Journey (Metadata)

```swift
class Journey: Object {
    @Persisted(primaryKey: true) var id: UUID
    @Persisted var type: JourneyType // Enum: Agoraphobia, GeneralAnxiety, None
    @Persisted var startDate: Date
    @Persisted var isCompleted: Bool = false
    @Persisted var current: Bool = true
    
    // Sync metadata
    @Persisted var isSynced: Bool = false
    @Persisted var needsSync: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted var lastSyncedAt: Date?
    @Persisted var updatedAt: Date
}
```

#### JourneyRealm (Tracking Data)

```swift
class JourneyRealm: Object {
    @Persisted(primaryKey: true) var id: String // UUID as String
    @Persisted var startTime: Date
    @Persisted var endTime: Date
    @Persisted var distance: Double // in meters
    @Persisted var duration: Int // in seconds
    @Persisted var pathPoints = RealmSwift.List<PathPointRealm>()
    @Persisted var checkpoints = RealmSwift.List<FeelingCheckpointRealm>()
    
    // Sync metadata
    @Persisted var isSynced: Bool = false
    @Persisted var needsSync: Bool = false
    @Persisted var isDeleted: Bool = false
    @Persisted var lastSyncedAt: Date?
    @Persisted var updatedAt: Date
}
```

#### PathPointRealm

```swift
class PathPointRealm: Object {
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    @Persisted var timestamp: Date
}
```

#### FeelingCheckpointRealm

```swift
class FeelingCheckpointRealm: Object {
    @Persisted var id: String // UUID as String
    @Persisted var latitude: Double
    @Persisted var longitude: Double
    @Persisted var feeling: String // Feeling level enum
    @Persisted var timestamp: Date
}
```

#### PanicEpisode

```swift
class PanicEpisode: Object {
    @Persisted(primaryKey: true) var id: String
    @Persisted var userId: String
    @Persisted var timestamp: Date
    
    // Core metrics
    @Persisted var initialIntensity: Int // 0-10
    @Persisted var peakIntensity: Int // 0-10
    @Persisted var finalIntensity: Int // 0-10
    @Persisted var duration: TimeInterval
    
    // Physical symptoms (0-10 each)
    @Persisted var heartRate: Int
    @Persisted var breathingDifficulty: Int
    @Persisted var chestTightness: Int
    @Persisted var sweating: Int
    @Persisted var trembling: Int
    @Persisted var dizziness: Int
    @Persisted var nausea: Int
    
    // Cognitive symptoms (0-10 each)
    @Persisted var fearOfDying: Int
    @Persisted var fearOfLosingControl: Int
    @Persisted var derealization: Int
    @Persisted var racingThoughts: Int
    
    // Context
    @Persisted var location: String
    @Persisted var trigger: String
    @Persisted var timeOfDay: String
    @Persisted var aloneOrWithOthers: String
    
    // Coping strategies
    @Persisted var copingStrategiesUsed: RealmSwift.List<String>
    @Persisted var strategyEffectiveness: Int // 0-10
    
    // Aftermath
    @Persisted var recoveryTime: TimeInterval
    @Persisted var afterEffects: RealmSwift.List<String>
    @Persisted var notes: String
}
```

---

## Cloud Database (Supabase)

### Connection

**File**: `beatphobia/Supabase.swift`

- **URL**: `https://dktqwcqucsykjayyibuj.supabase.co`
- **Client**: Supabase Swift SDK
- **Date Encoding**: ISO8601
- **Date Decoding**: ISO8601

### Supabase Tables

#### Profile Table

**Primary table for user profiles** (created by Supabase Auth)

```sql
CREATE TABLE profile (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    username TEXT UNIQUE,
    profile_image_url TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Key Features:**
- Linked to `auth.users` via foreign key
- Username is unique and lowercase (3-30 chars, alphanumeric/hyphen/underscore)
- Role field supports: 'user' or 'admin'
- Profile images stored in Supabase Storage

#### Journal Entries Table

```sql
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Journal content
    mood TEXT NOT NULL CHECK (mood IN ('happy', 'angry', 'excited', 'stressed', 'sad', 'none')),
    text TEXT NOT NULL,
    entry_date TIMESTAMPTZ NOT NULL,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);
```

**Indexes:**
- `idx_journal_entries_user_id` on `user_id`
- `idx_journal_entries_entry_date` on `entry_date DESC`
- `idx_journal_entries_user_date` on `(user_id, entry_date DESC)`
- `idx_journal_entries_is_deleted` on `is_deleted WHERE is_deleted = FALSE`

#### Journeys Table

```sql
CREATE TABLE journeys (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Journey metadata
    type INTEGER NOT NULL CHECK (type IN (0, 1, 2)), -- 0: Agoraphobia, 1: GeneralAnxiety, 2: None
    start_date TIMESTAMPTZ NOT NULL,
    is_completed BOOLEAN DEFAULT FALSE,
    current BOOLEAN DEFAULT FALSE,
    
    -- Sync metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);
```

**Indexes:**
- `idx_journeys_user_id` on `user_id`
- `idx_journeys_start_date` on `start_date DESC`
- `idx_journeys_user_date` on `(user_id, start_date DESC)`
- `idx_journeys_is_deleted` on `is_deleted WHERE is_deleted = FALSE`
- `idx_journeys_current` on `(user_id, current) WHERE current = TRUE`

#### Journey Data Table

```sql
CREATE TABLE journey_data (
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
```

**Indexes:**
- `idx_journey_data_journey_id` on `journey_id`
- `idx_journey_data_user_id` on `user_id`
- `idx_journey_data_start_time` on `start_time DESC`

#### Path Points Table

```sql
CREATE TABLE path_points (
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
```

**Indexes:**
- `idx_path_points_journey_data_id` on `journey_data_id`
- `idx_path_points_timestamp` on `timestamp`
- `idx_path_points_user_id` on `user_id`

#### Feeling Checkpoints Table

```sql
CREATE TABLE feeling_checkpoints (
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
```

**Indexes:**
- `idx_feeling_checkpoints_journey_data_id` on `journey_data_id`
- `idx_feeling_checkpoints_timestamp` on `timestamp`
- `idx_feeling_checkpoints_user_id` on `user_id`

#### Community Topics Table

```sql
CREATE TABLE community_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Topic content
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    category TEXT,
    
    -- Engagement metrics
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    is_trending BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);
```

**Indexes:**
- `idx_topics_user_id` on `user_id`
- `idx_topics_created_at` on `created_at DESC`
- `idx_topics_is_trending` on `is_trending WHERE is_trending = TRUE`

#### Comments Table

```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES community_topics(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Comment content
    content TEXT NOT NULL,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);
```

**Indexes:**
- `idx_comments_topic_id` on `topic_id`
- `idx_comments_user_id` on `user_id`
- `idx_comments_created_at` on `created_at DESC`

#### Topic Likes Table

```sql
CREATE TABLE topic_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID NOT NULL REFERENCES community_topics(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(topic_id, user_id)
);
```

#### Attachments Table

```sql
CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journal_entry_id UUID REFERENCES journal_entries(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profile(id) ON DELETE CASCADE,
    
    -- Attachment metadata
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    file_size BIGINT,
    mime_type TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Indexes:**
- `idx_attachments_journal_entry_id` on `journal_entry_id`
- `idx_attachments_user_id` on `user_id`

---

## Sync Services

### Journal Sync Service

**File**: `beatphobia/Services/JournalSyncService.swift`

**Features:**
- Automatic bidirectional sync every 5 minutes (Pro only)
- Push local changes to cloud
- Pull cloud changes to local
- Conflict resolution: Local wins (last write wins)
- Soft delete support

**Sync Flow:**

1. **Push Local Changes**
   - Find all `JournalEntryModel` with `needsSync == true` and `isDeleted == false`
   - Upsert to `journal_entries` table
   - Mark as synced (`isSynced = true`, `needsSync = false`)

2. **Pull Cloud Changes**
   - Fetch all journal entries from cloud for current user
   - Compare `updated_at` timestamps
   - Update local if cloud is newer or entry doesn't exist locally
   - Mark as synced

**Methods:**
- `startAutoSync()`: Start automatic sync (Pro only)
- `stopAutoSync()`: Stop automatic sync
- `syncAll()`: Manual sync (push + pull)
- `pushLocalChanges()`: Push local changes to cloud
- `pullCloudChanges()`: Pull cloud changes to local

### Journey Sync Service

**File**: `beatphobia/Services/JourneySyncService.swift`

**Features:**
- Automatic bidirectional sync every 5 minutes (Pro only)
- Syncs both `Journey` metadata and `JourneyRealm` tracking data
- Handles related data (path points, checkpoints)
- Conflict resolution: Local wins

**Sync Flow:**

1. **Push Local Changes**
   - Sync `Journey` objects (metadata)
   - Sync `JourneyRealm` objects (tracking data)
   - Create/update `journeys` table
   - Create/update `journey_data` table
   - Sync `path_points` and `feeling_checkpoints`

2. **Pull Cloud Changes**
   - Fetch all journeys from cloud
   - Fetch all journey data
   - Update local if cloud is newer
   - Create missing local entries

**Data Mapping:**

- `Journey` (Realm) ↔ `journeys` (Supabase)
- `JourneyRealm` (Realm) ↔ `journey_data` (Supabase)
- `PathPointRealm` (Realm) ↔ `path_points` (Supabase)
- `FeelingCheckpointRealm` (Realm) ↔ `feeling_checkpoints` (Supabase)

**Methods:**
- `startAutoSync()`: Start automatic sync (Pro only)
- `stopAutoSync()`: Stop automatic sync
- `syncAll()`: Manual sync (push + pull)
- `pushLocalChanges()`: Push local changes to cloud
- `pullCloudChanges()`: Pull cloud changes to local
- `syncJourneyData()`: Sync journey tracking data (path points, checkpoints)

---

## Row Level Security (RLS)

All Supabase tables have Row Level Security enabled to ensure users can only access their own data.

### Journal Entries RLS

```sql
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
```

### Journeys RLS

```sql
-- Similar policies for journeys, journey_data, path_points, feeling_checkpoints
-- All enforce: auth.uid() = user_id
```

### Community RLS

**Topics:**
- Users can view all non-deleted topics
- Users can create topics (must be their own)
- Users can update/delete their own topics

**Comments:**
- Users can view all non-deleted comments
- Users can create comments (must be their own)
- Users can update/delete their own comments

**Likes:**
- Users can view all likes
- Users can like/unlike topics (own likes only)

### Profile RLS

- Users can view all profiles (for username display)
- Users can only update their own profile
- Profile images: Public read, owner write

---

## Storage Buckets

### Profile Images Bucket

**Bucket Name**: `profile-images`

**Policies:**
- **Public Read**: Anyone can view profile images
- **Owner Write**: Only profile owner can upload/update their image

**File Path**: `{userId}/profile_image.jpg`

### Journal Attachments Bucket

**Bucket Name**: `journal-attachments`

**Policies:**
- **Private**: Only authenticated users can access
- **Owner Only**: Users can only access their own attachments

**File Path**: `{userId}/{journalEntryId}/{filename}`

---

## Connection Configuration

### Supabase Client Setup

**File**: `beatphobia/Supabase.swift`

```swift
let supabase: SupabaseClient = {
    let supabaseUrl = URL(string: SUPABASE_URL)!
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    return SupabaseClient(
        supabaseURL: supabaseUrl,
        supabaseKey: SUPABASE_ANON_KEY,
        options: SupabaseClientOptions(
            db: SupabaseClientOptions.DatabaseOptions(
                encoder: encoder,
                decoder: decoder
            )
        )
    )
}()
```

### Realm Configuration

**File**: `beatphobia/Config/RealmConfiguration.swift`

```swift
Realm.Configuration(
    schemaVersion: 5,
    migrationBlock: { migration, oldSchemaVersion in
        // Handle migrations...
    }
)
```

**Initialization**: Called in `beatphobiaApp.swift` on app launch

---

## Schema Migrations

### Realm Migrations

**Current Version**: 5

**Migration History:**

1. **Version 1 → 2**: Added sync properties to `JournalEntryModel`
   - `isSynced`, `needsSync`, `isDeleted`, `lastSyncedAt`, `updatedAt`

2. **Version 2 → 3**: Added location tracking models
   - `JourneyRealm`, `PathPointRealm`, `FeelingCheckpointRealm`

3. **Version 3 → 4**: Added sync properties to `Journey`
   - `isSynced`, `needsSync`, `isDeleted`, `lastSyncedAt`, `updatedAt`

4. **Version 4 → 5**: Added sync properties to `JourneyRealm`
   - `isSynced`, `needsSync`, `isDeleted`, `lastSyncedAt`, `updatedAt`

### Supabase Migrations

**Migration Files**: Located in `database/` directory

**Key Migrations:**

1. `01_community_schema.sql`: Community forum tables
2. `13_journal_schema.sql`: Journal entries table
3. `24_journey_sync_schema.sql`: Journey sync tables
4. `25_add_journey_data_tables.sql`: Journey data tables
5. `16_add_attachments_table.sql`: Journal attachments
6. `18_add_profile_images.sql`: Profile image support

**Migration Order:**
- Run migrations sequentially by number
- Check for `IF NOT EXISTS` clauses
- Always backup before running migrations

---

## Data Relationships

### Entity Relationship Diagram

```
┌─────────────┐
│   Profile   │
│  (auth.users│
└──────┬──────┘
       │
       ├─────────────────────┬─────────────────────┬─────────────────────┐
       │                     │                     │                     │
       ▼                     ▼                     ▼                     ▼
┌──────────────┐    ┌─────────────┐      ┌──────────────┐      ┌──────────────┐
│   Journal    │    │  Journey    │      │  Community   │      │ Attachments  │
│   Entries    │    │             │      │   Topics     │      │              │
└──────┬───────┘    └──────┬──────┘      └──────┬───────┘      └──────┬───────┘
       │                   │                     │                     │
       │                   ▼                     │                     │
       │            ┌──────────────┐            │                     │
       │            │ Journey Data │            │                     │
       │            └──────┬───────┘            │                     │
       │                   │                    │                     │
       │                   ├──────────┬─────────┤                     │
       │                   │          │         │                     │
       │                   ▼          ▼         ▼                     │
       │            ┌──────────┐ ┌──────────┐ ┌──────────┐            │
       │            │   Path   │ │ Feeling  │ │ Comments │            │
       │            │  Points  │ │Checkpoint│ │          │            │
       │            └──────────┘ └──────────┘ └──────────┘            │
       │                                                                 │
       └───────────────────────────────────────────────────────────────┘
```

### Relationship Details

1. **Profile → Journal Entries**
   - One-to-Many
   - Foreign Key: `journal_entries.user_id → profile.id`
   - Cascade Delete: Yes

2. **Profile → Journeys**
   - One-to-Many
   - Foreign Key: `journeys.user_id → profile.id`
   - Cascade Delete: Yes

3. **Journey → Journey Data**
   - One-to-One (typically)
   - Foreign Key: `journey_data.journey_id → journeys.id`
   - Cascade Delete: Yes

4. **Journey Data → Path Points**
   - One-to-Many
   - Foreign Key: `path_points.journey_data_id → journey_data.id`
   - Cascade Delete: Yes

5. **Journey Data → Feeling Checkpoints**
   - One-to-Many
   - Foreign Key: `feeling_checkpoints.journey_data_id → journey_data.id`
   - Cascade Delete: Yes

6. **Profile → Community Topics**
   - One-to-Many
   - Foreign Key: `community_topics.user_id → profile.id`
   - Cascade Delete: Yes

7. **Community Topic → Comments**
   - One-to-Many
   - Foreign Key: `comments.topic_id → community_topics.id`
   - Cascade Delete: Yes

8. **Journal Entry → Attachments**
   - One-to-Many
   - Foreign Key: `attachments.journal_entry_id → journal_entries.id`
   - Cascade Delete: Yes

---

## Sync Metadata Pattern

All syncable models follow this pattern:

### Local (Realm)

```swift
@Persisted var isSynced: Bool = false      // Has been synced to cloud
@Persisted var needsSync: Bool = false     // Needs to be synced (create/update)
@Persisted var isDeleted: Bool = false     // Soft delete flag
@Persisted var lastSyncedAt: Date? = nil   // Last successful sync timestamp
@Persisted var updatedAt: Date = Date()     // Last local update
```

### Cloud (Supabase)

```sql
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()
is_deleted BOOLEAN DEFAULT FALSE
```

### Sync Logic

1. **Create/Update**: Set `needsSync = true`, `isSynced = false`
2. **After Sync**: Set `isSynced = true`, `needsSync = false`, `lastSyncedAt = Date()`
3. **Delete**: Set `isDeleted = true`, `needsSync = true`
4. **Conflict Resolution**: Compare `updated_at` timestamps, latest wins

---

## Feature Gating

### Pro Features

- **Journal Sync**: `subscriptionManager?.isPro == true`
- **Journey Sync**: `subscriptionManager?.canSyncJourneyToCloud() == true`
- **Cloud Storage**: Pro users only
- **Unlimited History**: Pro users can view all journeys (free users limited to 3)

### Free Tier Limitations

- **Journal Sync**: Disabled
- **Journey Sync**: Disabled
- **Journey History**: Limited to 3 most recent journeys
- **Storage**: Limited to local only

---

## Best Practices

1. **Always Save Locally First**: Write to Realm before attempting cloud sync
2. **Handle Offline Gracefully**: App should work fully offline
3. **Sync in Background**: Don't block UI for sync operations
4. **Respect RLS**: Never bypass RLS policies
5. **Use Soft Deletes**: Mark records as deleted, don't remove immediately
6. **Index Frequently Queried Fields**: User ID, timestamps, etc.
7. **Monitor Sync Status**: Log sync operations for debugging
8. **Validate Data**: Check data integrity before sync

---

## Troubleshooting

### Common Issues

1. **Sync Not Working**
   - Check Pro subscription status
   - Verify Supabase connection
   - Check RLS policies
   - Review sync logs

2. **Data Not Appearing**
   - Verify `isDeleted = false` filter
   - Check `needsSync` flag
   - Confirm user authentication

3. **Migration Failures**
   - Backup Realm database
   - Check migration block logic
   - Verify schema version increment

4. **Performance Issues**
   - Check indexes on frequently queried fields
   - Optimize Realm queries
   - Limit batch sync sizes

---

## Related Documentation

- `database/README.md` - Database setup guide
- `JOURNAL_SYNC_INTEGRATION.md` - Journal sync implementation details
- `IMAGE_ATTACHMENTS_SETUP.md` - Storage bucket configuration
- `COMMUNITY_SETUP_COMPLETE.md` - Community forum setup

---

**Last Updated**: 2025-10-25  
**Schema Version**: Realm 5, Supabase Latest

