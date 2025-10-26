# Community Forum Database Setup

## Quick Setup Instructions

Follow these steps to set up the database in Supabase:

### 1. Access Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar
3. Click **+ New Query**

### 2. Run SQL Files in Order

**Important:** Run these files in the exact order shown below.

#### Step 1: Create Tables and Triggers
1. Open `01_community_schema.sql`
2. Copy **ALL** contents
3. Paste into Supabase SQL Editor
4. Click **Run** (or press Cmd/Ctrl + Enter)
5. You should see: "Success. No rows returned"

#### Step 2: Set Up Security Policies
1. Open `02_rls_policies.sql`
2. Copy **ALL** contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. You should see: "Success. No rows returned"

#### Step 3: Add Sample Data (Optional)
1. **First**, get your user ID:
   - In Supabase SQL Editor, run:
   ```sql
   SELECT id FROM auth.users LIMIT 1;
   ```
   - Copy the UUID that's returned

2. Open `03_sample_data.sql`
3. Replace **ALL** instances of `YOUR_USER_ID_HERE` with your actual user ID (the UUID from step 1)
4. Copy the modified contents
5. Paste into Supabase SQL Editor
6. Click **Run**
7. You should see: "Success. No rows returned"

### 3. Migrations (Run if needed)

#### Migration: Fix Delete/Update Permissions (Required for Edit/Delete Features)
If you're getting errors when trying to delete or edit posts/comments like:
```
new row violates row-level security policy for table "community_posts"
```

Run this migration:
1. Open `05_fix_update_policies.sql`
2. Copy **ALL** contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. You should see a table showing the updated policies

#### Migration: Add Trending Column (Optional)
If you want to use the trending posts feature:
1. Open `04_add_trending_column.sql`
2. Copy **ALL** contents
3. Paste into Supabase SQL Editor
4. Click **Run**

### 4. Verify Installation

Run this query to verify everything is set up correctly:

```sql
-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'community_%'
ORDER BY table_name;
```

You should see 7 tables:
- `community_comments`
- `community_comment_likes`
- `community_friends`
- `community_messages`
- `community_posts`
- `community_post_bookmarks`
- `community_post_likes`

### 4. Check Sample Data (if you ran step 3)

```sql
SELECT id, title, category, likes_count, comments_count 
FROM community_posts 
ORDER BY created_at DESC;
```

## Database Schema Overview

### Tables Created

1. **community_posts** - Forum posts
   - Stores post title, content, category, tags
   - Tracks likes, comments, views
   - Soft delete support

2. **community_comments** - Comments on posts
   - Supports threaded/nested comments
   - Tracks likes per comment

3. **community_post_likes** - Post likes/hearts
   - One like per user per post
   - Auto-updates post like counts

4. **community_comment_likes** - Comment likes
   - One like per user per comment
   - Auto-updates comment like counts

5. **community_post_bookmarks** - Saved posts
   - Users can bookmark posts for later

6. **community_friends** - Friend connections
   - Pending, accepted, blocked statuses
   - Foundation for friends feature

7. **community_messages** - Direct messages
   - Private 1-on-1 messaging
   - Read receipts
   - Soft delete per user

### Features Included

✅ **Automatic Triggers** - Engagement counts update automatically
✅ **Row Level Security** - Users can only access what they should
✅ **Soft Deletes** - Posts/comments marked as deleted, not removed
✅ **Performance Indexes** - Optimized for fast queries
✅ **Timestamp Tracking** - Auto-updates `updated_at` fields

## Troubleshooting

### Error: "relation 'profile' does not exist"
**Solution:** Your profile table might be named differently. Check:
```sql
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%profile%';
```

### Error: "relation already exists"
**Solution:** Tables already exist. You can either:
- Skip this file (if tables are correct)
- Drop tables first:
  ```sql
  DROP TABLE IF EXISTS community_messages CASCADE;
  DROP TABLE IF EXISTS community_friends CASCADE;
  DROP TABLE IF EXISTS community_post_bookmarks CASCADE;
  DROP TABLE IF EXISTS community_comment_likes CASCADE;
  DROP TABLE IF EXISTS community_post_likes CASCADE;
  DROP TABLE IF EXISTS community_comments CASCADE;
  DROP TABLE IF EXISTS community_posts CASCADE;
  ```
  Then run `01_community_schema.sql` again.

### Error: "policy already exists"
**Solution:** Policies already exist. Either skip `02_rls_policies.sql` or drop them first:
```sql
-- Run this to see all policies:
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename LIKE 'community_%';

-- Drop them if needed (replace POLICY_NAME with actual name):
DROP POLICY IF EXISTS "policy_name" ON table_name;
```

### Error: "username violates check constraint"
**Solution:** Make sure your username meets requirements:
```sql
-- Check your username
SELECT id, username FROM profile WHERE id = auth.uid();

-- Set a valid username (lowercase, 3-30 chars, only a-z, 0-9, _, -)
UPDATE profile SET username = 'testuser123' WHERE id = auth.uid();
```

### Error: "duplicate key value violates unique constraint"
**Solution:** Sample data already exists. Either:
- Skip `03_sample_data.sql`
- Delete existing posts first:
  ```sql
  DELETE FROM community_posts;
  ```

## Next Steps

After database setup, the Swift app will automatically connect and use these tables. No additional configuration needed in the app!

The `CommunityService.swift` handles all database operations:
- Fetching posts and comments
- Creating new posts/comments
- Liking/unliking
- Bookmarking
- And more!

