//
//  JournalSyncService.swift
//  beatphobia
//
//  Handles bidirectional sync between local Realm storage and Supabase cloud
//

import Foundation
import RealmSwift
import Supabase
import Combine

// MARK: - Supabase Journal Model
struct JournalEntryDB: Codable {
    let id: UUID
    let userId: UUID
    let mood: String
    let text: String
    let entryDate: Date
    let createdAt: Date?
    let updatedAt: Date?
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mood
        case text
        case entryDate = "entry_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

@MainActor
class JournalSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private var syncTimer: Timer?
    private weak var subscriptionManager: SubscriptionManager?
    
    init() {
        // Load last sync date from UserDefaults
        if let lastSync = UserDefaults.standard.object(forKey: "lastJournalSyncDate") as? Date {
            self.lastSyncDate = lastSync
        }
        
        // Listen for subscription changes
        NotificationCenter.default.addObserver(
            forName: .subscriptionStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { [weak self] in
                await self?.handleSubscriptionChange()
            }
        }
    }
    
    /// Set the subscription manager to check Pro status
    func setSubscriptionManager(_ manager: SubscriptionManager) {
        self.subscriptionManager = manager
    }
    
    /// Handle subscription status changes (e.g., user upgraded to Pro)
    @MainActor
    private func handleSubscriptionChange() async {
        if subscriptionManager?.isPro == true {
            print("🎉 Pro subscription activated - starting journal sync")
            startAutoSync()
        } else {
            print("📝 Pro subscription inactive - stopping journal sync")
            stopAutoSync()
        }
    }
    
    // MARK: - Auto Sync
    
    /// Start automatic syncing every 5 minutes (Pro only)
    @MainActor
    func startAutoSync() {
        stopAutoSync()

        // Only sync if user is Pro
        guard subscriptionManager?.isPro == true else {
            print("📝 Journal sync disabled (Free tier)")
            return
        }

        // Initial sync
        Task {
            await syncAll()
        }

        // Schedule periodic syncs
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.syncAll()
            }
        }
    }

    @MainActor
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Manual Sync
    
    /// Sync all local changes to cloud and pull cloud changes (Pro only)
    @MainActor
    func syncAll() async {
        // Check if user is Pro
        guard subscriptionManager?.isPro == true else {
            print("📝 Journal sync skipped (Pro required)")
            return
        }
        
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            // 1. Push local changes to cloud
            try await pushLocalChanges()
            
            // 2. Pull cloud changes to local
            try await pullCloudChanges()
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastJournalSyncDate")
            
            print("✅ Journal sync completed successfully")
        } catch {
            syncError = error.localizedDescription
            print("❌ Journal sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Push Local Changes
    
    private func pushLocalChanges() async throws {
        guard let realm = try? await Realm() else {
            print("❌ Failed to initialize Realm")
            return
        }
        
        // Get all entries that need syncing
        let entriesToSync = realm.objects(JournalEntryModel.self)
            .filter("needsSync == true")
        
        guard !entriesToSync.isEmpty else {
            print("📤 No local changes to push")
            return
        }
        
        print("📤 Pushing \(entriesToSync.count) local changes to cloud...")
        
        // Copy entry IDs to avoid thread issues
        let entryIDs = Array(entriesToSync.map { $0.id })
        
        for entryID in entryIDs {
            do {
                // Re-fetch each entry in the async context to avoid thread issues
                guard let realm = try? await Realm(),
                      let entry = realm.object(ofType: JournalEntryModel.self, forPrimaryKey: entryID) else {
                    continue
                }
                
                // Prepare data for Supabase
                let dbEntry = JournalEntryDB(
                    id: entry.id,
                    userId: try await getCurrentUserId(),
                    mood: entry.mood.rawValue,
                    text: entry.text,
                    entryDate: entry.date,
                    createdAt: nil,
                    updatedAt: entry.updatedAt,
                    isDeleted: entry.isDeleted
                )
                
                // Upsert to Supabase (insert or update)
                try await supabase
                    .from("journal_entries")
                    .upsert(dbEntry)
                    .execute()
                
                // Mark as synced in Realm (re-fetch to ensure thread safety)
                if let updateRealm = try? await Realm(),
                   let entryToUpdate = updateRealm.object(ofType: JournalEntryModel.self, forPrimaryKey: entryID) {
                    try! updateRealm.write {
                        entryToUpdate.isSynced = true
                        entryToUpdate.needsSync = false
                        entryToUpdate.lastSyncedAt = Date()
                    }
                }
                
                print("✅ Synced entry: \(entryID)")
            } catch {
                print("❌ Failed to sync entry \(entryID): \(error)")
                // Continue with next entry
            }
        }
    }
    
    // MARK: - Pull Cloud Changes
    
    private func pullCloudChanges() async throws {
        print("📥 Pulling changes from cloud...")
        
        let userId = try await getCurrentUserId()
        guard let realm = try? await Realm() else {
            print("❌ Failed to initialize Realm")
            return
        }
        
        // Fetch all cloud entries for this user
        let response = try await supabase
            .from("journal_entries")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cloudEntries = try decoder.decode([JournalEntryDB].self, from: response.data)
        
        print("📥 Found \(cloudEntries.count) entries in cloud")
        
        // Process each cloud entry
        for cloudEntry in cloudEntries {
            let localEntry = realm.object(ofType: JournalEntryModel.self, forPrimaryKey: cloudEntry.id)
            
            if let localEntry = localEntry {
                // Entry exists locally - check if cloud is newer
                let cloudUpdatedAt = cloudEntry.updatedAt ?? cloudEntry.createdAt ?? Date.distantPast
                
                if cloudUpdatedAt > localEntry.updatedAt || !localEntry.isSynced {
                    // Cloud version is newer, update local
                    try! realm.write {
                        localEntry.mood = Mood(rawValue: cloudEntry.mood) ?? .none
                        localEntry.text = cloudEntry.text
                        localEntry.date = cloudEntry.entryDate
                        localEntry.isDeleted = cloudEntry.isDeleted
                        localEntry.updatedAt = cloudUpdatedAt
                        localEntry.isSynced = true
                        localEntry.needsSync = false
                        localEntry.lastSyncedAt = Date()
                    }
                    print("🔄 Updated local entry: \(cloudEntry.id)")
                }
            } else {
                // New entry from cloud, create locally
                try! realm.write {
                    let newEntry = JournalEntryModel()
                    newEntry.id = cloudEntry.id
                    newEntry.mood = Mood(rawValue: cloudEntry.mood) ?? .none
                    newEntry.text = cloudEntry.text
                    newEntry.date = cloudEntry.entryDate
                    newEntry.isDeleted = cloudEntry.isDeleted
                    newEntry.updatedAt = cloudEntry.updatedAt ?? cloudEntry.createdAt ?? Date()
                    newEntry.isSynced = true
                    newEntry.needsSync = false
                    newEntry.lastSyncedAt = Date()
                    realm.add(newEntry)
                }
                print("✨ Created new local entry from cloud: \(cloudEntry.id)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        let uuidString = session.user.id.uuidString
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "JournalSync", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        return uuid
    }
}

// MARK: - Realm Extensions for Journal Operations

extension Realm {
    /// Save or update a journal entry with sync tracking
    func saveJournalEntry(_ entry: JournalEntryModel, needsSync: Bool = true) {
        try! write {
            entry.updatedAt = Date()
            entry.needsSync = needsSync
            entry.isSynced = false
            add(entry, update: .modified)
        }
    }
    
    /// Soft delete a journal entry
    func deleteJournalEntry(_ entry: JournalEntryModel) {
        try! write {
            entry.isDeleted = true
            entry.updatedAt = Date()
            entry.needsSync = true
            entry.isSynced = false
        }
    }
}


