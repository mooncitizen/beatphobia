# Comment Notification Setup Guide

This guide will help you set up push notifications for comment replies.

## Prerequisites

1. **APNs (Apple Push Notification service) Key**:
   - Go to Apple Developer Portal → Certificates, Identifiers & Profiles → Keys
   - Create a new key with "Apple Push Notifications service (APNs)" enabled
   - Download the .p8 file (you can only download it once!)
   - Note your Key ID and Team ID

2. **Supabase CLI**:
   ```bash
   npm install -g supabase
   ```

## Step 1: Configure Database Settings

Run this in your Supabase SQL Editor to set the required database settings:

```sql
-- Set Supabase URL and anon key for trigger to use
ALTER DATABASE postgres SET app.supabase_url = 'https://your-project-id.supabase.co';
ALTER DATABASE postgres SET app.supabase_anon_key = 'your-anon-key-here';
```

**Note**: Replace `your-project-id` and `your-anon-key-here` with your actual Supabase project values.
- Find your project URL in Supabase Dashboard → Settings → API
- Find your anon key in Supabase Dashboard → Settings → API → Project API keys

## Step 2: Run Database Trigger SQL

Run the SQL file in your Supabase SQL Editor:

```sql
-- Copy and paste the contents of database/29_comment_notification_trigger.sql
-- Or run it directly from the file
```

This will:
- Enable the `pg_net` extension (for HTTP requests from database)
- Create the `notify_comment_reply()` function
- Create the trigger that fires when comments are created

## Step 3: Deploy Edge Function

1. **Link your Supabase project** (if not already linked):
   ```bash
   cd /Users/paul/ios-projects/beatphobia
   supabase link --project-ref your-project-ref
   ```

2. **Deploy the function**:
   ```bash
   supabase functions deploy send-comment-notification
   ```

## Step 4: Configure Edge Function Secrets

Set the required environment variables for the Edge Function:

```bash
# Get your APNs credentials from Apple Developer Portal
# Key ID is shown when you create/download the key
# Team ID is in Membership page

# Read your .p8 file and convert to single-line string
# (Remove line breaks and keep as a single string)
cat your-apns-key.p8 | tr -d '\n'

# Set the secrets
supabase secrets set APNS_KEY_ID="your_key_id_here"
supabase secrets set APNS_TEAM_ID="your_team_id_here"
supabase secrets set APNS_BUNDLE_ID="com.beatphobia.app"
supabase secrets set APNS_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nYOUR_KEY_CONTENT_HERE\n-----END PRIVATE KEY-----"
supabase secrets set APNS_PRODUCTION="true"  # Use "false" for sandbox/testing
```

**Important Notes**:
- `APNS_PRIVATE_KEY` should be the full PEM content including the BEGIN/END markers
- Use `\n` for newlines in the secret string
- For testing, set `APNS_PRODUCTION="false"` to use sandbox environment
- Make sure your app's bundle ID matches `APNS_BUNDLE_ID`

## Step 5: Verify Setup

1. **Check trigger is created**:
   ```sql
   SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_comment_reply';
   ```

2. **Check function exists**:
   ```sql
   SELECT proname FROM pg_proc WHERE proname = 'notify_comment_reply';
   ```

3. **Test the edge function manually**:
   ```bash
   curl -X POST 'https://your-project-id.supabase.co/functions/v1/send-comment-notification' \
     -H 'Authorization: Bearer your-anon-key' \
     -H 'Content-Type: application/json' \
     -d '{
       "type": "post_reply",
       "recipient_user_id": "test-user-uuid",
       "commenter_user_id": "test-commenter-uuid",
       "commenter_username": "testuser",
       "post_id": "test-post-uuid",
       "post_title": "Test Post",
       "comment_id": "test-comment-uuid",
       "comment_preview": "This is a test comment..."
     }'
   ```

## How It Works

1. **User creates a comment** → Database trigger (`trigger_notify_comment_reply`) fires
2. **Trigger checks**:
   - Is it a reply to a post? → Notify post author
   - Is it a reply to a comment? → Notify parent comment author
   - Skip if user is replying to their own content
3. **Trigger calls Edge Function** via HTTP POST using `pg_net`
4. **Edge Function**:
   - Checks if recipient has blocked the commenter (skips if blocked)
   - Fetches all push tokens for recipient user
   - Generates APNs JWT token
   - Sends push notification to all recipient's devices

## Troubleshooting

### Trigger not firing
- Check that the trigger exists: `SELECT * FROM pg_trigger WHERE tgname = 'trigger_notify_comment_reply';`
- Check trigger logs in Supabase Dashboard → Logs → Postgres Logs
- Verify `app.supabase_url` and `app.supabase_anon_key` are set

### Edge function not being called
- Check that `pg_net` extension is enabled: `SELECT * FROM pg_extension WHERE extname = 'pg_net';`
- Check function logs in Supabase Dashboard → Edge Functions → send-comment-notification → Logs
- Verify database settings are configured correctly

### Notifications not received
- Check device token exists in `push_tokens` table
- Verify APNs credentials are correct (Key ID, Team ID, Bundle ID)
- Check APNs production vs sandbox matches your app environment
- Review Edge Function logs for APNs errors
- Make sure APNs is enabled in your app's capabilities

### JWT signing errors
- Verify `APNS_PRIVATE_KEY` is in correct PEM format
- Check `APNS_KEY_ID` matches the key ID from Apple Developer Portal
- Verify `APNS_TEAM_ID` is correct (from Membership page)
- Ensure the .p8 key has "Apple Push Notifications service (APNs)" enabled

## Additional Configuration

### Update Database Settings

If you need to update the Supabase URL or anon key:

```sql
ALTER DATABASE postgres SET app.supabase_url = 'https://new-url.supabase.co';
ALTER DATABASE postgres SET app.supabase_anon_key = 'new-anon-key';
```

### Disable Notifications Temporarily

To disable notifications without removing the trigger:

```sql
ALTER TABLE community_comments DISABLE TRIGGER trigger_notify_comment_reply;
```

To re-enable:

```sql
ALTER TABLE community_comments ENABLE TRIGGER trigger_notify_comment_reply;
```

