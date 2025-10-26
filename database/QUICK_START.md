# ⚡ Quick Start - 2 Steps to Launch

## Step 1: Run SQL in Supabase (2 minutes)

1. Go to: https://supabase.com/dashboard → Your Project → **SQL Editor**

2. Copy & Run each file in order:
   ```
   ✅ 01_community_schema.sql  ← This adds username constraints!
   ✅ 02_rls_policies.sql
   ✅ 03_sample_data.sql (optional - adds test posts)
   ```

## Step 2: Build & Run! (1 minute)

1. Build app in Xcode
2. Navigate: **Community**
3. You'll be prompted to create a username (if you don't have one)
4. Username must be:
   - Unique across all users
   - Lowercase only
   - 3-30 characters
   - Only letters, numbers, _ and -
5. After setting username, you can access the forum!

---

## That's It! 🎉

**Everything else is already wired up and ready to go!**

The app will automatically check for a username and prompt you if needed.

Need more details? See `COMMUNITY_SETUP_COMPLETE.md`

