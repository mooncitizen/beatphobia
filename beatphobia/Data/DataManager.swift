import Foundation
import SwiftData
import Supabase
import Observation

@MainActor
@Observable
final class DataManager {
    
    @ObservationIgnored
    private let modelContext: ModelContext
    
    @ObservationIgnored
    private let supabaseClient: SupabaseClient
    
    var isSyncing: Bool = false
    
    init(modelContext: ModelContext, supabaseClient: SupabaseClient) {
        self.modelContext = modelContext
        self.supabaseClient = supabaseClient
    }
    
    private func setSyncing(_ value: Bool) {
        Task {
            self.isSyncing = value
        }
    }
    
    private func getSupabaseUserId() async -> UUID? {
        try? await supabaseClient.auth.session.user.id
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save model context: \(error)")
        }
    }
    
    // MARK: - Public API (Journal)
    
    func createJournalEntry(mood: String, moodStrength: Int, body: String, images: [String]) async {
        guard let userID = await getSupabaseUserId() else { return }
        
        let newEntry = JournalEntry(
            userID: userID.uuidString,
            mood: mood,
            moodStrength: moodStrength,
            body: body,
            images: images
        )
        
        modelContext.insert(newEntry)
        saveContext()
        
        Task(priority: .background) {
            await syncJournalEntries()
        }
    }
    
    func updateJournalEntry(_ entry: JournalEntry, mood: String, moodStrength: Int, body: String, images: [String]) async {
        entry.mood = mood
        entry.moodStrength = moodStrength
        entry.body = body
        entry.images = images
        entry.updatedAt = Date()
        entry.syncStatus = .localOnly
        saveContext()
        
        Task(priority: .background) {
            await syncJournalEntries()
        }
    }
    
    func deleteJournalEntry(_ entry: JournalEntry) async {
        let entryID = entry.id
        modelContext.delete(entry)
        saveContext()
        
        Task(priority: .background) {
            try? await deleteFromRemote(tableName: "journal_entries", id: entryID)
        }
    }
    
    func syncJournalEntries() async {
        await setSyncing(true)
        defer { setSyncing(false) }
        
        guard let userID = await getSupabaseUserId() else { return }
        
        do {
            try await pushChanges(
                modelType: JournalEntry.self,
                tableName: "journal_entries",
                dtoTransform: { SupabaseJournalEntry(from: $0, userID: userID) }
            )
            
//            try await fetchChanges(
//                modelType: JournalEntry.self,
//                tableName: "journal_entries",
//                dtoType: SupabaseJournalEntry.self,
//                conflictResolver: { local, remote in
//                    local.mood = remote.mood
//                    local.moodStrength = remote.moodStrength
//                    local.body = remote.body
//                    local.images = remote.images
//                    local.updatedAt = remote.updatedAt
//                    local.syncStatus = .synced
//                },
//                dtoToModel: { remote in
//                    JournalEntry(
//                        id: remote.id,
//                        createdAt: remote.createdAt,
//                        updatedAt: remote.updatedAt,
//                        syncStatus: .synced,
//                        userID: remote.user_id.uuidString,
//                        mood: remote.mood,
//                        moodStrength: remote.moodStrength,
//                        body: remote.body,
//                        images: remote.images
//                    )
//                }
//            )
        } catch {
            print("Sync failed: \(error)")
        }
    }

    // MARK: - Private Generic Sync Engine
    
    private func pushChanges<T, DTO>(
        modelType: T.Type,
        tableName: String,
        dtoTransform: (T) -> DTO?
    ) async throws where T: SyncableModel, DTO: Codable {
        
        let unsynced = try await fetchUnsyncedEntries(modelType: T.self)
        if unsynced.isEmpty { return }

        let dtosToUpsert = unsynced.compactMap(dtoTransform)
        if dtosToUpsert.isEmpty { return }

        try await supabaseClient
            .from(tableName)
            .upsert(dtosToUpsert)
            .execute()

        for entry in unsynced {
            entry.syncStatus = .synced
        }
        saveContext()
    }
    
    private func fetchChanges<T, DTO>(
        modelType: T.Type,
        tableName: String,
        dtoType: DTO.Type,
        conflictResolver: (T, DTO) -> Void,
        dtoToModel: (DTO) -> T
    ) async throws where T: SyncableModel, DTO: Codable & Identifiable & Hashable, DTO.ID == UUID, DTO: Sendable {
        
        guard let userID = await getSupabaseUserId() else { return }
        
        let remoteDTOs: [DTO] = try await supabaseClient
            .from(tableName)
            .select()
            .eq("user_id", value: userID)
            .execute()
            .value
        
        let localEntries = try await fetchAllEntries(modelType: T.self)
        let localEntryMap = Dictionary(uniqueKeysWithValues: localEntries.map { ($0.id, $0) })
        let remoteDTOMap = Dictionary(uniqueKeysWithValues: remoteDTOs.map { ($0.id, $0) })
        
        for remoteDTO in remoteDTOs {
            if let localEntry = localEntryMap[remoteDTO.id] {
                guard let remoteUpdatedAt = (remoteDTO as? any SupabaseDateTrackable)?.updatedAt else { continue }
                if remoteUpdatedAt > localEntry.updatedAt {
                    conflictResolver(localEntry, remoteDTO)
                }
            } else {
                modelContext.insert(dtoToModel(remoteDTO))
            }
        }
        
        for localEntry in localEntries {
            if remoteDTOMap[localEntry.id] == nil {
                modelContext.delete(localEntry)
            }
        }
        
        saveContext()
    }
    
    private func deleteFromRemote(tableName: String, id: UUID) async throws {
        try await supabaseClient
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    private func fetchUnsyncedEntries<T: SyncableModel>(modelType: T.Type) async throws -> [T] {
//        let unsyncedPredicate = #Predicate<T> { $0.syncStatus == SyncStatus.localOnly }
//        let fetchDescriptor = FetchDescriptor<T>(predicate: unsyncedPredicate)
//        return try modelContext.fetch(fetchDescriptor)
        return []
    }
    
    private func fetchAllEntries<T: SyncableModel>(modelType: T.Type) async throws -> [T] {
        let fetchDescriptor = FetchDescriptor<T>()
        return try modelContext.fetch(fetchDescriptor)
    }
}

fileprivate protocol SupabaseDateTrackable {
    var updatedAt: Date { get }
}

extension SupabaseJournalEntry: SupabaseDateTrackable {}
