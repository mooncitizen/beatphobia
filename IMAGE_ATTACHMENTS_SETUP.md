# Image Attachments System - Setup Guide

## ✅ What's Been Implemented

### 1. **ImageManager Service** (`Services/ImageManager.swift`)
- Uploads images to Supabase Storage
- Local disk caching (100 MB max)
- Automatic compression (max 1200px, < 2MB)
- Cache cleanup when size limit exceeded
- `CachedAsyncImage` view for automatic loading and caching

### 2. **Attachments Table** (Database)
- Flexible schema supporting posts AND comments
- Max 3 attachments per post/comment
- NSFW flagging support (for future implementation)
- File metadata: type, size, dimensions, mime type

### 3. **Multi-Image Upload** (Posts)
- Select up to 3 images when creating a post
- Grid preview with remove buttons
- Progress tracking during upload
- All images cached locally after upload

### 4. **Image Display**
- **PostCard**: Horizontal scrolling thumbnails (100x100px)
- **PostDetailView**: Full-size images with proper aspect ratio
- Automatic caching on first load
- Placeholder with progress indicator while loading

## 📋 Required Supabase Setup

### Step 1: Run Database Migration

In **Supabase Dashboard → SQL Editor**, run:
```
/Users/paul/ios-projects/beatphobia/database/16_add_attachments_table.sql
```

This creates:
- `community_attachments` table
- RLS policies
- Max 3 attachments constraint
- Indexes for performance

### Step 2: Create Storage Bucket

1. Go to **Supabase Dashboard → Storage**
2. Click **"New bucket"**
3. Name: `community-attachments`
4. **Public bucket**: ✅ Enabled
5. **File size limit**: 5 MB (recommended)
6. **Allowed MIME types**: `image/jpeg, image/png, image/webp`
7. Click **"Create bucket"**

### Step 3: Apply Storage Policies

After creating the bucket, run this in **SQL Editor**:

```sql
-- Allow authenticated users to upload attachments
CREATE POLICY "Authenticated users can upload attachments"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'community-attachments');

-- Allow everyone to view attachments
CREATE POLICY "Anyone can view attachments"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'community-attachments');

-- Allow users to delete their own attachments
CREATE POLICY "Users can delete own attachments"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'community-attachments' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
```

## 🎨 Features

### Creating Posts with Images
1. User clicks "Add Photos (up to 3)"
2. Selects image from photo library
3. Can add up to 3 total
4. Each image can be removed individually
5. On submit, all images upload first
6. Then post is created with attachment records

### Viewing Posts with Images
- **In List View**: Horizontal scrolling thumbnails
- **In Detail View**: Full-size images stacked vertically
- **All Images**: Automatically cached to disk
- **Offline**: Cached images display without internet

## 💰 Cost Optimization

**Local Caching Benefits**:
- Images cached on first load
- Subsequent views: instant, no bandwidth cost
- Max 100 MB cache (auto-cleanup of oldest)
- Only downloads once per device

**Storage Costs** (Supabase):
- Free tier: 1 GB storage
- Pro tier: 100 GB storage  
- Pay-as-you-go: $0.021/GB/month

With local caching, you only pay for storage, not repeated downloads!

## 🔮 Future Enhancements (Ready to Implement)

1. **Comment Attachments**: Already supported in database, just need UI
2. **NSFW Flagging**: Column exists, need toggle UI
3. **Video Support**: Change `fileType` enum
4. **Image Compression Settings**: User-controlled quality
5. **Multiple Image Preview**: Swipe gallery view

## 🧪 Testing

After setup:
1. Create a new post
2. Add 1-3 images
3. Submit post
4. Check Supabase Storage → community-attachments bucket
5. Verify images appear in post list
6. Navigate to post detail to see full-size images
7. Close app and reopen → images load instantly from cache

## 🐛 Troubleshooting

**Images not uploading:**
- Check bucket name is `community-attachments`
- Verify storage policies are applied
- Check console for upload errors

**Images not displaying:**
- Check `community_attachments` table has records
- Verify `file_url` is public URL
- Check cache directory permissions

**Cache too large:**
- Automatic cleanup happens at 100 MB
- Manual clear: `ImageManager().clearCache()`

## Architecture Benefits

✅ **Reusable**: ImageManager works for any feature  
✅ **Efficient**: Local caching reduces costs  
✅ **Scalable**: Attachments table supports posts, comments, and future features  
✅ **Flexible**: Easy to add videos, documents later  
✅ **User-friendly**: Fast loading, offline support  

