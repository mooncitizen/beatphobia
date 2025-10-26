# 🎯 Username System - Complete Documentation

## Overview

The community now requires all users to have a unique username before accessing community features. This ensures proper identity management and a better user experience.

---

## 🔐 Username Requirements

### Validation Rules
- **Length**: 3-30 characters
- **Case**: Lowercase only (automatically converted)
- **Uniqueness**: Must be unique across all users (case-insensitive)
- **Characters**: Only letters (a-z), numbers (0-9), underscores (_), and hyphens (-)

### Examples
✅ **Valid usernames:**
- `john_doe`
- `user123`
- `anxiety-warrior`
- `sarah2024`

❌ **Invalid usernames:**
- `AB` (too short)
- `John_Doe` (not lowercase)
- `user@name` (invalid characters)
- `a_very_long_username_that_exceeds_thirty_chars` (too long)

---

## 📱 User Experience Flow

### First Time Users

1. **Navigate to Community**
   - User taps on Community from home

2. **Loading Screen**
   - App checks if user has a username

3. **Username Setup Screen** (if no username)
   - Beautiful modal screen with guidelines
   - Real-time validation as user types
   - Automatic lowercase conversion
   - Live availability checking
   - Cannot be dismissed until username is set

4. **Community Access** (once username is set)
   - Full access to forum, posts, and features
   - Username displayed on all posts/comments

### Returning Users

- If username exists → Direct access to community
- If username deleted/missing → Prompted to create new one

---

## 🗄️ Database Schema

### Profile Table Updates

```sql
-- Username column (already exists in your profile table)
ALTER TABLE profile ADD COLUMN IF NOT EXISTS username TEXT;

-- Unique constraint (case-insensitive)
CREATE UNIQUE INDEX profile_username_unique_lower 
ON profile (LOWER(username));

-- Lowercase enforcement
ALTER TABLE profile ADD CONSTRAINT profile_username_lowercase_check 
CHECK (username = LOWER(username));

-- Length constraint
ALTER TABLE profile ADD CONSTRAINT profile_username_length_check 
CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 30);

-- Character validation (alphanumeric, underscore, hyphen only)
ALTER TABLE profile ADD CONSTRAINT profile_username_format_check 
CHECK (username ~ '^[a-z0-9_-]+$');
```

### These constraints ensure:
- ✅ Data integrity at database level
- ✅ No duplicate usernames (even with different casing)
- ✅ Consistent formatting
- ✅ Invalid usernames cannot be saved

---

## 💻 Implementation Details

### Files Created/Modified

#### 1. **UsernameSetupView.swift** (NEW)
- Reusable SwiftUI component for username setup
- Features:
  - Real-time validation
  - Availability checking
  - Auto-lowercase conversion
  - Visual feedback (colors, icons)
  - Guidelines display
  - Loading states
  - Error handling

#### 2. **CommunityOverview.swift** (UPDATED)
- Added username checking on load
- Shows loading state while checking
- Displays UsernameSetupView if no username
- Blocks community access until username is set

#### 3. **ProfileModel.swift** (UPDATED)
- Added `username: String?` field
- Proper Codable implementation

#### 4. **CommunityModels.swift** (UPDATED)
- Changed from `authorName` to `authorUsername`
- Updated display models
- Usernames shown in all community features

#### 5. **CommunityService.swift** (UPDATED)
- Fetches username from profiles
- All queries updated to use username

#### 6. **Database Schema** (UPDATED)
- `01_community_schema.sql` now includes username constraints

---

## 🎨 UI Features

### Username Setup Screen

```
┌─────────────────────────────────┐
│                                 │
│        [@] (icon)               │
│                                 │
│   Choose Your Username          │
│   Your username is how others   │
│   will see you in the community │
│                                 │
│   @[username______] [✓]         │
│                                 │
│   ✓ Available!                  │
│                                 │
│   Username Guidelines           │
│   ✓ 3-30 characters long        │
│   ✓ Lowercase letters (a-z)     │
│   ✓ Numbers (0-9)               │
│   ✓ Underscores (_) hyphens (-) │
│                                 │
│   [     Continue      ]         │
│                                 │
└─────────────────────────────────┘
```

### Features:
- 🎨 Clean, modern design matching app aesthetic
- ⚡ Real-time validation feedback
- 🔍 Live availability checking (debounced)
- ✅ Visual success indicators
- ❌ Clear error messages
- 🔒 Cannot be dismissed (modal with no close button)
- 📱 Haptic feedback on interactions

---

## 🔄 Availability Checking

### How It Works

1. **Debounced Checking**
   - Waits 0.5 seconds after user stops typing
   - Prevents excessive database queries

2. **Database Query**
   ```swift
   SELECT * FROM profiles 
   WHERE username = 'entered_username'
   ```

3. **Real-time Feedback**
   - ⏳ Checking... (loading spinner)
   - ✅ Available! (green checkmark)
   - ❌ Already taken (red X + message)

4. **Validation First**
   - Only checks availability if format is valid
   - Saves unnecessary database calls

---

## 🚦 States & Flow

```
┌─────────────────┐
│  User Opens     │
│  Community      │
└────────┬────────┘
         │
         ▼
   ┌──────────┐
   │ Checking │ ← Loading state
   │ Username │
   └────┬─────┘
        │
    ┌───┴───┐
    │       │
    ▼       ▼
┌────────┐  ┌──────────────┐
│  Has   │  │  No Username │
│Username│  └──────┬───────┘
└───┬────┘         │
    │              ▼
    │     ┌────────────────┐
    │     │  Username      │
    │     │  Setup Screen  │
    │     │  (Cannot Close)│
    │     └────────┬───────┘
    │              │
    │              ▼
    │     ┌────────────────┐
    │     │  User Creates  │
    │     │  Username      │
    │     └────────┬───────┘
    │              │
    └──────────┬───┘
               │
               ▼
    ┌──────────────────┐
    │  Community       │
    │  Full Access     │
    └──────────────────┘
```

---

## 🧪 Testing Checklist

### Username Creation
- [ ] Can create valid username
- [ ] Username auto-converts to lowercase
- [ ] Shows "available" for unique usernames
- [ ] Shows "taken" for existing usernames
- [ ] Rejects usernames <3 characters
- [ ] Rejects usernames >30 characters
- [ ] Rejects invalid characters (@, #, !, etc.)
- [ ] Shows appropriate validation messages
- [ ] Continue button disabled until valid
- [ ] Loading indicators work correctly

### Community Access
- [ ] Users without username see setup screen
- [ ] Users with username access community directly
- [ ] Loading state shown while checking
- [ ] Cannot dismiss setup screen without creating username
- [ ] After creating username, community loads
- [ ] Username displayed correctly on posts
- [ ] Username displayed correctly on comments

### Edge Cases
- [ ] Network error during availability check
- [ ] Network error during username creation
- [ ] User logs out and back in (username persists)
- [ ] Special characters are rejected
- [ ] Spaces are rejected
- [ ] Empty username rejected

---

## 🛠️ Troubleshooting

### "Username is already taken" but I just created it
- **Cause**: Database constraint working correctly
- **Solution**: Choose a different username

### Setup screen keeps appearing even though I set a username
- **Cause**: Profile might not have updated
- **Check**: Run in Supabase:
  ```sql
  SELECT id, username FROM profile WHERE id = auth.uid();
  ```
- **Fix**: Manually set username:
  ```sql
  UPDATE profile SET username = 'yourusername' WHERE id = auth.uid();
  ```

### "Could not check availability" error
- **Cause**: Network issue or Supabase connection problem
- **Solution**: Check internet connection and try again

### Database constraint error when creating username
- **Cause**: Username doesn't meet database requirements
- **Solution**: Ensure SQL constraints were run (`01_community_schema.sql`)

---

## 📊 Analytics & Monitoring

### Useful Queries

```sql
-- Count users with usernames
SELECT COUNT(*) FROM profile WHERE username IS NOT NULL;

-- Find users without usernames
SELECT id, email FROM auth.users au
LEFT JOIN profile p ON au.id = p.id
WHERE p.username IS NULL;

-- Most common username patterns
SELECT 
  LENGTH(username) as length,
  COUNT(*) as count
FROM profile
WHERE username IS NOT NULL
GROUP BY LENGTH(username)
ORDER BY count DESC;

-- Check for duplicate usernames (should be 0)
SELECT LOWER(username), COUNT(*) 
FROM profile 
WHERE username IS NOT NULL
GROUP BY LOWER(username)
HAVING COUNT(*) > 1;
```

---

## 🎓 For Developers

### Reusing Username Setup View

The `UsernameSetupView` is designed to be reusable:

```swift
import SwiftUI

// Use anywhere in your app
UsernameSetupView {
    // Called when username is successfully created
    print("Username created!")
    // Handle navigation or state updates
}
```

### Checking if User Has Username

```swift
func checkUsername() async -> Bool {
    do {
        let userId = try await supabase.auth.session.user.id
        let profile: Profile = try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
        
        return profile.username != nil && !profile.username!.isEmpty
    } catch {
        return false
    }
}
```

---

## ✨ Benefits

### For Users
- 🎭 **Identity**: Unique identity in the community
- 🔒 **Privacy**: No real names required
- 🎨 **Personalization**: Choose how you appear
- 👥 **Recognition**: Easy to identify and remember users

### For Developers
- 📊 **Clean Data**: Enforced at database level
- 🔍 **Easy Queries**: Simple username lookups
- 🚀 **Scalable**: Indexed for performance
- 🛡️ **Secure**: Multiple validation layers

---

## 📝 Summary

✅ **Username system fully implemented**
✅ **Database constraints in place**
✅ **Beautiful, reusable UI component**
✅ **Real-time validation & checking**
✅ **Blocks community access without username**
✅ **All community features use username**

Users will be prompted to create a username the first time they access the community, and cannot proceed without one. This ensures a clean, consistent identity system across your entire community platform!

