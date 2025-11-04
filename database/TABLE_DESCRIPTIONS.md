# Database Table Descriptions

## notifications Table

**Purpose:** Stores in-app notifications for users (replies, messages, friend requests, etc.)

**Schema:**
```
notifications (
    id              UUID PRIMARY KEY (auto-generated)
    from            UUID NOT NULL → references profile(id) ON DELETE CASCADE
    to              UUID NOT NULL → references profile(id) ON DELETE CASCADE
    type            TEXT NOT NULL (CHECK: 'reply', 'message', 'friend_request', 'like', 'mention', 'other')
    post_id         UUID → references community_posts(id) ON DELETE CASCADE (nullable)
    reply_id        UUID → references community_comments(id) ON DELETE CASCADE (nullable)
    date            TIMESTAMPTZ DEFAULT NOW()
    read            BOOLEAN DEFAULT FALSE
)
```

**Key Points:**
- `from` = user ID who triggered the notification
- `to` = user ID who receives the notification
- `type` = notification category (reply, message, friend_request, like, mention, other)
- `post_id` and `reply_id` are nullable depending on notification type
- `read` defaults to FALSE
- `date` automatically set to current timestamp

**RLS Policies:**
- Users can SELECT their own notifications (where `to` = their user_id)
- System can INSERT notifications (for triggers)
- Users can UPDATE their own notifications (mark as read)
- Users can DELETE their own notifications

**Indexes:**
- `idx_notifications_to_user_id` on `to`
- `idx_notifications_to_user_read` on `to, read`
- `idx_notifications_date` on `date DESC`
- `idx_notifications_type` on `type`


## push_tokens Table

**Purpose:** Stores APNs push notification tokens for users' devices (allows multiple devices per user)

**Schema:**
```
push_tokens (
    id              UUID PRIMARY KEY (auto-generated via gen_random_uuid())
    user_id         UUID NOT NULL → references auth.users(id) ON DELETE CASCADE
    token           TEXT NOT NULL (UNIQUE) - APNs device token
    platform        TEXT NOT NULL (CHECK: 'ios')
    device_id       TEXT NOT NULL - device identifier
    app_version     TEXT - app version (nullable)
    created_at      TIMESTAMPTZ DEFAULT NOW()
    last_seen_at    TIMESTAMPTZ DEFAULT NOW()
)
```

**Key Points:**
- `user_id` = references Supabase `auth.users` table (not profile table)
- `token` = APNs device token (UNIQUE constraint - one row per token)
- `platform` = currently only 'ios' supported
- `device_id` = device identifier string
- `app_version` = optional app version string
- `last_seen_at` = updated when token is refreshed/used
- Multiple tokens allowed per user (one per device)

**RLS Policies:**
- Users can SELECT their own tokens (where `user_id` = their auth.uid())
- Users can INSERT tokens for themselves
- Users can UPDATE their own tokens
- Users can DELETE their own tokens

**Helper Function:**
- `register_push_token(p_token, p_device_id, p_platform, p_app_version)` - SECURITY DEFINER function for safe upsert (insert or update on conflict)

