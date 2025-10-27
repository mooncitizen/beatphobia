# Journal Sync Integration Guide

## Overview
The journal now supports **hybrid local + cloud sync**:
- ✅ **Offline-first**: Works without internet, stores in Realm
- ✅ **Auto-sync**: Syncs to Supabase when connection is available
- ✅ **Bidirectional**: Pulls cloud changes and pushes local changes
- ✅ **Conflict resolution**: Cloud timestamp wins in conflicts

## Setup Steps

### 1. Database Setup (Required First!)

Run the SQL script in Supabase:
```bash
# In Supabase SQL Editor, run:
database/13_journal_schema.sql
```

This creates the `journal_entries` table and RLS policies.

### 2. Integration into Your App

#### A. Initialize Sync Service in App Lifecycle

Add to your main app file or root view:

```swift
import SwiftUI

@main
struct BeatphobiaApp: App {
    @StateObject private var journalSyncService = JournalSyncService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(journalSyncService)
                .onAppear {
                    // Start auto-sync when app launches
                    journalSyncService.startAutoSync()
                }
                .onDisappear {
                    // Stop auto-sync when app closes
                    journalSyncService.stopAutoSync()
                }
        }
    }
}
```

#### B. Update Journal Save Logic

**OLD CODE (in JournalHome.swift or wherever you save entries):**
```swift
func saveJournalEntry(mood: Mood, text: String) {
    let realm = try! Realm()
    let entry = JournalEntryModel()
    entry.mood = mood
    entry.text = text
    entry.date = Date()
    
    try! realm.write {
        realm.add(entry)
    }
}
```

**NEW CODE (with sync support):**
```swift
func saveJournalEntry(mood: Mood, text: String) {
    let realm = try! Realm()
    let entry = JournalEntryModel()
    entry.mood = mood
    entry.text = text
    entry.date = Date()
    
    try! realm.saveJournalEntry(entry) // Uses the new extension method
    
    // Trigger sync in background
    Task {
        await journalSyncService.syncAll()
    }
}
```

#### C. Update Journal Edit Logic

**NEW CODE:**
```swift
func updateJournalEntry(_ entry: JournalEntryModel, mood: Mood, text: String) {
    let realm = try! Realm()
    
    try! realm.write {
        entry.mood = mood
        entry.text = text
        entry.updatedAt = Date()
        entry.needsSync = true
        entry.isSynced = false
    }
    
    // Trigger sync
    Task {
        await journalSyncService.syncAll()
    }
}
```

#### D. Update Journal Delete Logic

**OLD CODE:**
```swift
func deleteJournalEntry(_ entry: JournalEntryModel) {
    let realm = try! Realm()
    try! realm.write {
        realm.delete(entry)
    }
}
```

**NEW CODE (soft delete with sync):**
```swift
func deleteJournalEntry(_ entry: JournalEntryModel) {
    let realm = try! Realm()
    try! realm.deleteJournalEntry(entry) // Uses the new extension method
    
    // Trigger sync to propagate delete
    Task {
        await journalSyncService.syncAll()
    }
}
```

### 3. Add Sync Status UI (Optional but Recommended)

Add a sync indicator to your journal view:

```swift
struct JournalHomeView: View {
    @EnvironmentObject var journalSyncService: JournalSyncService
    
    var body: some View {
        VStack {
            // Your existing journal UI
            
            // Sync status indicator
            HStack {
                if journalSyncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if let lastSync = journalSyncService.lastSyncDate {
                    Image(systemName: "checkmark.icloud")
                        .foregroundColor(.green)
                    Text("Last synced: \(timeAgo(lastSync))")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else {
                    Image(systemName: "icloud.slash")
                        .foregroundColor(.orange)
                    Text("Not synced")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Manual sync button
                Button(action: {
                    Task {
                        await journalSyncService.syncAll()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
```

### 4. Handle Network Connectivity (Advanced)

For production, you might want to only sync when online:

```swift
import Network

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}

// In your sync trigger:
if networkMonitor.isConnected {
    Task {
        await journalSyncService.syncAll()
    }
} else {
    print("⚠️ Offline - will sync when connection restored")
}
```

## How It Works

### Local-First Approach
1. **Save**: Entry saved to Realm immediately (instant)
2. **Mark**: Entry flagged with `needsSync = true`
3. **Sync**: Background task uploads to Supabase when connected
4. **Update**: Entry marked as `isSynced = true` after successful upload

### Sync Behavior
- **Auto-sync**: Every 5 minutes (configurable)
- **Manual sync**: User can trigger via button
- **On app launch**: Syncs immediately when app opens
- **Bidirectional**: Pulls cloud changes and merges with local

### Conflict Resolution
- **Timestamp-based**: Newest `updatedAt` wins
- **Cloud authoritative**: If conflict, cloud version takes precedence
- **No data loss**: Local changes pushed before pulling

## Testing the Sync

### 1. Test Offline Creation
```swift
// 1. Turn off internet
// 2. Create a journal entry
// 3. Check: Entry appears in app (from Realm)
// 4. Turn on internet
// 5. Wait 5 seconds or trigger manual sync
// 6. Check: Entry now in Supabase database
```

### 2. Test Cloud Pull
```swift
// 1. On Device A: Create entry and sync
// 2. On Device B: Open app or trigger sync
// 3. Check: Entry from Device A appears on Device B
```

### 3. Test Edit Sync
```swift
// 1. Edit existing entry
// 2. Sync
// 3. Check: Supabase shows updated text/mood
```

### 4. Test Delete Sync
```swift
// 1. Delete entry (soft delete)
// 2. Sync
// 3. Check: Entry marked as is_deleted=true in Supabase
// 4. Check: Entry no longer visible in app
```

## Database Schema

```sql
journal_entries
├── id (UUID, PK)
├── user_id (UUID, FK -> profile)
├── mood (TEXT: 'happy', 'angry', 'excited', 'stressed', 'sad', 'none')
├── text (TEXT)
├── entry_date (TIMESTAMPTZ) -- The actual journal date
├── created_at (TIMESTAMPTZ)
├── updated_at (TIMESTAMPTZ)
└── is_deleted (BOOLEAN)
```

## Troubleshooting

### "User not authenticated" error
**Solution**: Ensure user is logged in before syncing:
```swift
guard supabase.auth.currentSession != nil else {
    print("User not logged in, skipping sync")
    return
}
```

### Entries not syncing
**Check**:
1. Is `needsSync = true` on the entry?
2. Is internet connected?
3. Check console for sync errors
4. Verify Supabase RLS policies are correct

### Duplicate entries
**Solution**: The sync uses `upsert` which should prevent duplicates.
If you see duplicates, ensure UUIDs are consistent between devices.

### Sync taking too long
**Solution**: Reduce sync frequency or add pagination:
```swift
// In JournalSyncService.swift, change timer interval:
syncTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) // 10 minutes
```

## Performance Considerations

- **Batch size**: Syncs all pending entries at once (consider pagination for 100+ entries)
- **Network**: Only syncs when changes exist (`needsSync = true`)
- **Background**: Sync runs on background thread, won't block UI
- **Realm**: Uses Realm's efficient change tracking

## Security

- ✅ **RLS enabled**: Users can only access their own entries
- ✅ **Soft deletes**: Deleted entries remain in DB (can be purged later)
- ✅ **UUID-based**: No predictable IDs
- ✅ **Authenticated**: Requires valid Supabase session

## Future Enhancements

Potential improvements:
- ⏱️ **Conflict resolution UI**: Show user when conflicts occur
- 📊 **Sync statistics**: Track sync success rate
- 🔄 **Delta sync**: Only sync changed fields, not entire entry
- 🗑️ **Hard delete**: Permanent delete after X days
- 📱 **Push notifications**: Notify on sync completion


