//
//  JourneySyncService.swift
//  beatphobia
//
//  Handles bidirectional sync between local Realm storage and Supabase cloud for journeys
//

import Foundation
import RealmSwift
import Supabase
import Combine

// MARK: - Supabase Journey Model
struct JourneyDB: Codable {
    let id: UUID
    let userId: UUID
    let type: Int
    let startDate: Date
    let isCompleted: Bool
    let current: Bool
    let createdAt: Date?
    let updatedAt: Date?
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case type
        case startDate = "start_date"
        case isCompleted = "is_completed"
        case current
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

// MARK: - Path Point JSON Model (for JSON storage)
struct PathPointJSON: Codable {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

// MARK: - Checkpoint JSON Model (for JSON storage)
struct CheckpointJSON: Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    let feeling: String
    let timestamp: Date
}

// MARK: - Hesitation Point JSON Model (for JSON storage)
struct HesitationPointJSON: Codable {
    let id: String
    let latitude: Double
    let longitude: Double
    let startTime: Date
    let endTime: Date
    let duration: Double // in seconds
}

// MARK: - Supabase Journey Data Model
struct JourneyDataDB: Codable {
    let id: UUID
    let journeyId: UUID
    let userId: UUID
    let startTime: Date
    let endTime: Date?
    let distance: Double
    let duration: Int
    let pathPointsJson: [PathPointJSON]?
    let checkpointsJson: [CheckpointJSON]?
    let hesitationPointsJson: [HesitationPointJSON]?
    let createdAt: Date?
    let updatedAt: Date?
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case journeyId = "journey_id"
        case userId = "user_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case distance
        case duration
        case pathPointsJson = "path_points_json"
        case checkpointsJson = "checkpoints_json"
        case hesitationPointsJson = "hesitation_points_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

// MARK: - Supabase Path Point Model
struct PathPointDB: Codable {
    let id: UUID
    let journeyDataId: UUID
    let userId: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case journeyDataId = "journey_data_id"
        case userId = "user_id"
        case latitude
        case longitude
        case timestamp
        case createdAt = "created_at"
    }
}

// MARK: - Supabase Feeling Checkpoint Model
struct FeelingCheckpointDB: Codable {
    let id: UUID
    let journeyDataId: UUID
    let userId: UUID
    let latitude: Double
    let longitude: Double
    let feeling: String
    let timestamp: Date
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case journeyDataId = "journey_data_id"
        case userId = "user_id"
        case latitude
        case longitude
        case feeling
        case timestamp
        case createdAt = "created_at"
    }
}

@MainActor
class JourneySyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private var syncTimer: Timer?
    private weak var subscriptionManager: SubscriptionManager?
    
    init() {
        // Load last sync date from UserDefaults
        if let lastSync = UserDefaults.standard.object(forKey: "lastJourneySyncDate") as? Date {
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
        if subscriptionManager?.canSyncJourneyToCloud() == true {
            startAutoSync()
        } else {
            stopAutoSync()
        }
    }
    
    // MARK: - Auto Sync
    
    /// Start automatic syncing every 5 minutes (Pro only)
    @MainActor
    func startAutoSync() {
        stopAutoSync()

        // Check subscription status using the proper feature check method
        let canSync = subscriptionManager?.canSyncJourneyToCloud() ?? false
        let isPro = subscriptionManager?.isPro ?? false
        print("🗺️ Journey sync starting - canSyncJourneyToCloud: \(canSync), isPro: \(isPro)")

        // Only sync if user can sync journeys (has Pro access)
        guard canSync else {
            print("📍 Journey sync disabled (Pro required)")
            return
        }

        print("🗺️ Starting initial journey sync...")
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
        print("🗺️ Journey auto-sync scheduled (every 5 minutes)")
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
        // Check if user can sync journeys (has Pro access)
        guard subscriptionManager?.canSyncJourneyToCloud() == true else {
            print("📍 Journey sync skipped (Pro required)")
            return
        }
        
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            print("🗺️ syncAll: Starting push local changes...")
            // 1. Push local changes to cloud
            try await pushLocalChanges()
            print("🗺️ syncAll: Push completed, starting pull...")
            
            // 2. Pull cloud changes to local
            try await pullCloudChanges()
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastJourneySyncDate")
            
            print("✅ Journey sync completed successfully")
        } catch {
            syncError = error.localizedDescription
            print("❌ Journey sync error: \(error)")
            print("❌ Journey sync error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
            }
        }
        
        isSyncing = false
    }
    
    // MARK: - Push Local Changes
    
    private func pushLocalChanges() async throws {
        print("🗺️ pushLocalChanges: Starting...")
        guard let realm = try? await Realm() else {
            print("❌ pushLocalChanges: Failed to initialize Realm")
            throw NSError(domain: "JourneySync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Realm"])
        }
        
        // Get all journeys that need syncing
        let allJourneys = realm.objects(Journey.self)
        print("🗺️ pushLocalChanges: Total Journey objects in Realm: \(allJourneys.count)")
        
        // Check for JourneyRealm objects without matching Journey objects
        let allJourneyRealm = realm.objects(JourneyRealm.self)
        print("🗺️ pushLocalChanges: Total JourneyRealm objects in Realm: \(allJourneyRealm.count)")
        
        // Create Journey objects for JourneyRealm objects that don't have a matching Journey
        var createdJourneyCount = 0
        for journeyRealm in allJourneyRealm {
            guard let journeyRealmId = UUID(uuidString: journeyRealm.id) else { continue }
            let existingJourney = realm.object(ofType: Journey.self, forPrimaryKey: journeyRealmId)
            
            if existingJourney == nil {
                // Create Journey object from JourneyRealm
                let newJourney = Journey()
                newJourney.id = journeyRealmId
                newJourney.type = .None // Default, can be updated
                newJourney.startDate = journeyRealm.startTime
                newJourney.current = false
                newJourney.isCompleted = true
                newJourney.needsSync = true
                newJourney.isSynced = false
                newJourney.updatedAt = journeyRealm.updatedAt
                
                try! realm.write {
                    realm.add(newJourney)
                }
                createdJourneyCount += 1
                print("🗺️ Created Journey object from JourneyRealm: \(journeyRealmId)")
            }
        }
        
        if createdJourneyCount > 0 {
            print("🗺️ Created \(createdJourneyCount) Journey objects from existing JourneyRealm objects")
            // Re-fetch journeys after creating new ones
            let updatedJourneys = realm.objects(Journey.self)
            print("🗺️ pushLocalChanges: Total Journey objects after creation: \(updatedJourneys.count)")
        }
        
        let journeysToSync = allJourneys.filter("needsSync == true")
        print("🗺️ pushLocalChanges: Journeys marked for sync: \(journeysToSync.count)")
        
        // Log all journeys for debugging
        for journey in allJourneys {
            print("🗺️ Journey \(journey.id): needsSync=\(journey.needsSync), isSynced=\(journey.isSynced), isDeleted=\(journey.isDeleted), type=\(journey.type.rawValue)")
        }
        
        guard !journeysToSync.isEmpty else {
            print("📤 pushLocalChanges: No local journey changes to push (all journeys are already synced or don't need sync)")
            return
        }
        
        print("📤 pushLocalChanges: Pushing \(journeysToSync.count) journey changes to cloud...")
        
        // Copy journey IDs to avoid thread issues
        let journeyIDs = Array(journeysToSync.map { $0.id })
        
        for journeyID in journeyIDs {
            do {
                // Re-fetch each journey in the async context to avoid thread issues
                guard let realm = try? await Realm(),
                      let journey = realm.object(ofType: Journey.self, forPrimaryKey: journeyID) else {
                    continue
                }
                
                // Prepare data for Supabase
                let dbJourney = JourneyDB(
                    id: journey.id,
                    userId: try await getCurrentUserId(),
                    type: journey.type.rawValue,
                    startDate: journey.startDate,
                    isCompleted: journey.isCompleted,
                    current: journey.current,
                    createdAt: nil,
                    updatedAt: journey.updatedAt,
                    isDeleted: journey.isDeleted
                )
                
                // Upsert to Supabase (insert or update)
                try await supabase
                    .from("journeys")
                    .upsert(dbJourney)
                    .execute()
                
                print("🗺️ Pushing journey \(journeyID) to cloud...")
                
                // Sync journey data (JourneyRealm) if it exists
                try await syncJourneyData(journeyId: journeyID)
                
                // Mark as synced in Realm (re-fetch to ensure thread safety)
                if let updateRealm = try? await Realm(),
                   let journeyToUpdate = updateRealm.object(ofType: Journey.self, forPrimaryKey: journeyID) {
                    try! updateRealm.write {
                        journeyToUpdate.isSynced = true
                        journeyToUpdate.needsSync = false
                        journeyToUpdate.lastSyncedAt = Date()
                    }
                    print("✅ Marked journey \(journeyID) as synced in Realm")
                }
                
                print("✅ Synced journey: \(journeyID)")
            } catch {
                print("❌ Failed to sync journey \(journeyID): \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ Error domain: \(nsError.domain), code: \(nsError.code)")
                    print("❌ Error userInfo: \(nsError.userInfo)")
                }
                // Continue with next journey
            }
        }
        
        // Also sync JourneyRealm objects that need syncing independently
        let journeyDataToSync = realm.objects(JourneyRealm.self)
            .filter("needsSync == true")
        
        guard !journeyDataToSync.isEmpty else {
            print("📤 No local journey data changes to push")
            return
        }
        
        print("📤 Pushing \(journeyDataToSync.count) journey data changes to cloud...")
        
        let journeyDataIDs = Array(journeyDataToSync.map { $0.id })
        
        for journeyDataIDString in journeyDataIDs {
            do {
                guard let realm = try? await Realm(),
                      let journeyData = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyDataIDString),
                      let journeyDataUUID = UUID(uuidString: journeyDataIDString) else {
                    continue
                }
                
                // Find the related Journey to get journey_id
                // JourneyRealm.id should match Journey.id (both as UUID string)
                guard let journeyUUID = UUID(uuidString: journeyDataIDString),
                      let journey = realm.object(ofType: Journey.self, forPrimaryKey: journeyUUID) else {
                    // If no Journey found, skip (journey data requires a journey)
                    continue
                }
                
                // Sync the journey data
                try await syncJourneyData(journeyId: journey.id)
            } catch {
                print("❌ Failed to sync journey data \(journeyDataIDString): \(error)")
                // Continue with next journey data
            }
        }
    }
    
    // MARK: - Pull Cloud Changes
    
    private func pullCloudChanges() async throws {
        
        let userId = try await getCurrentUserId()
        guard let realm = try? await Realm() else {
            print("❌ Failed to initialize Realm")
            return
        }
        
        // Fetch all cloud journeys for this user
        let response = try await supabase
            .from("journeys")
            .select()
            .eq("user_id", value: userId)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cloudJourneys = try decoder.decode([JourneyDB].self, from: response.data)
        
        // Process each cloud journey
        for cloudJourney in cloudJourneys {
            let localJourney = realm.object(ofType: Journey.self, forPrimaryKey: cloudJourney.id)
            
            if let localJourney = localJourney {
                // Journey exists locally - check if cloud is newer
                let cloudUpdatedAt = cloudJourney.updatedAt ?? cloudJourney.createdAt ?? Date.distantPast
                
                if cloudUpdatedAt > localJourney.updatedAt || !localJourney.isSynced {
                    // Cloud version is newer, update local
                    try! realm.write {
                        localJourney.type = JourneyType(rawValue: cloudJourney.type) ?? .None
                        localJourney.startDate = cloudJourney.startDate
                        localJourney.isCompleted = cloudJourney.isCompleted
                        localJourney.current = cloudJourney.current
                        localJourney.isDeleted = cloudJourney.isDeleted
                        localJourney.updatedAt = cloudUpdatedAt
                        localJourney.isSynced = true
                        localJourney.needsSync = false
                        localJourney.lastSyncedAt = Date()
                    }
                    print("🔄 Updated local journey: \(cloudJourney.id)")
                }
            } else {
                // New journey from cloud, create locally
                try! realm.write {
                    let newJourney = Journey()
                    newJourney.id = cloudJourney.id
                    newJourney.type = JourneyType(rawValue: cloudJourney.type) ?? .None
                    newJourney.startDate = cloudJourney.startDate
                    newJourney.isCompleted = cloudJourney.isCompleted
                    newJourney.current = cloudJourney.current
                    newJourney.isDeleted = cloudJourney.isDeleted
                    newJourney.updatedAt = cloudJourney.updatedAt ?? cloudJourney.createdAt ?? Date()
                    newJourney.isSynced = true
                    newJourney.needsSync = false
                    newJourney.lastSyncedAt = Date()
                    realm.add(newJourney)
                }
                    print("✨ Created new local journey from cloud: \(cloudJourney.id)")
            }
            
            // Pull journey data (JourneyRealm) from cloud
            try await pullJourneyDataFromCloud(journeyId: cloudJourney.id)
        }
    }
    
    // MARK: - Pull Journey Data from Cloud
    
    private func pullJourneyDataFromCloud(journeyId: UUID) async throws {
        let userId = try await getCurrentUserId()
        guard let realm = try? await Realm() else { return }
        
        // Fetch journey data for this journey (explicitly include JSON columns)
        let journeyDataResponse = try await supabase
            .from("journey_data")
            .select("id, journey_id, user_id, start_time, end_time, distance, duration, path_points_json, checkpoints_json, hesitation_points_json, created_at, updated_at, is_deleted")
            .eq("journey_id", value: journeyId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .eq("is_deleted", value: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let cloudJourneyDataList = try decoder.decode([JourneyDataDB].self, from: journeyDataResponse.data)
        
        guard let cloudJourneyData = cloudJourneyDataList.first else {
            // No journey data in cloud
            return
        }
        
        let journeyDataUUID = cloudJourneyData.id
        let journeyRealmId = journeyDataUUID.uuidString
        
        // Extract path points from JSON (new format) or fetch from separate table (legacy)
        var cloudPathPoints: [PathPointJSON] = []
        if let pathPointsJson = cloudJourneyData.pathPointsJson {
            // Use JSON array from journey_data (new format)
            cloudPathPoints = pathPointsJson
        } else {
            // Fallback: Fetch from path_points table (legacy format)
            let fetchBatchSize = 1000
            var offset = 0
            while true {
                let pathPointsResponse = try await supabase
                    .from("path_points")
                    .select()
                    .eq("journey_data_id", value: journeyDataUUID.uuidString)
                    .order("timestamp", ascending: true)
                    .range(from: offset, to: offset + fetchBatchSize - 1)
                    .execute()
                
                let batch = try decoder.decode([PathPointDB].self, from: pathPointsResponse.data)
                cloudPathPoints.append(contentsOf: batch.map { PathPointJSON(latitude: $0.latitude, longitude: $0.longitude, timestamp: $0.timestamp) })
                
                if batch.count < fetchBatchSize {
                    break
                }
                offset += fetchBatchSize
            }
        }
        
        // Extract checkpoints from JSON (new format) or fetch from separate table (legacy)
        var cloudCheckpoints: [CheckpointJSON] = []
        if let checkpointsJson = cloudJourneyData.checkpointsJson {
            // Use JSON array from journey_data (new format)
            cloudCheckpoints = checkpointsJson
        } else {
            // Fallback: Fetch from feeling_checkpoints table (legacy format)
            let checkpointsResponse = try await supabase
                .from("feeling_checkpoints")
                .select()
                .eq("journey_data_id", value: journeyDataUUID.uuidString)
                .order("timestamp", ascending: true)
                .execute()
            
            let legacyCheckpoints = try decoder.decode([FeelingCheckpointDB].self, from: checkpointsResponse.data)
            cloudCheckpoints = legacyCheckpoints.map { checkpoint in
                CheckpointJSON(id: checkpoint.id.uuidString, latitude: checkpoint.latitude, longitude: checkpoint.longitude, feeling: checkpoint.feeling, timestamp: checkpoint.timestamp)
            }
        }
        
        // Extract hesitation points from JSON
        var cloudHesitationPoints: [HesitationPointJSON] = []
        if let hesitationPointsJson = cloudJourneyData.hesitationPointsJson {
            cloudHesitationPoints = hesitationPointsJson
        }
        
        // Update or create JourneyRealm
        let localJourneyData = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyRealmId)
        let cloudUpdatedAt = cloudJourneyData.updatedAt ?? cloudJourneyData.createdAt ?? Date.distantPast
        
        if let localJourneyData = localJourneyData {
            // Update existing if cloud is newer
            if cloudUpdatedAt > localJourneyData.updatedAt || !localJourneyData.isSynced {
                try! realm.write {
                    localJourneyData.startTime = cloudJourneyData.startTime
                    localJourneyData.endTime = cloudJourneyData.endTime ?? Date()
                    localJourneyData.distance = cloudJourneyData.distance
                    localJourneyData.duration = cloudJourneyData.duration
                    localJourneyData.isDeleted = cloudJourneyData.isDeleted
                    localJourneyData.updatedAt = cloudUpdatedAt
                    localJourneyData.isSynced = true
                    localJourneyData.needsSync = false
                    localJourneyData.lastSyncedAt = Date()
                    
                    // Update path points from JSON
                    localJourneyData.pathPoints.removeAll()
                    for cloudPoint in cloudPathPoints {
                        let pathPoint = PathPointRealm()
                        pathPoint.latitude = cloudPoint.latitude
                        pathPoint.longitude = cloudPoint.longitude
                        pathPoint.timestamp = cloudPoint.timestamp
                        localJourneyData.pathPoints.append(pathPoint)
                    }
                    
                    // Update checkpoints from JSON
                    localJourneyData.checkpoints.removeAll()
                    for cloudCheckpoint in cloudCheckpoints {
                        let checkpoint = FeelingCheckpointRealm()
                        checkpoint.id = cloudCheckpoint.id
                        checkpoint.latitude = cloudCheckpoint.latitude
                        checkpoint.longitude = cloudCheckpoint.longitude
                        checkpoint.feeling = cloudCheckpoint.feeling
                        checkpoint.timestamp = cloudCheckpoint.timestamp
                        localJourneyData.checkpoints.append(checkpoint)
                    }
                    
                    // Update hesitation points from JSON
                    localJourneyData.hesitationPoints.removeAll()
                    for cloudHesitation in cloudHesitationPoints {
                        let hesitation = HesitationPointRealm()
                        hesitation.id = cloudHesitation.id
                        hesitation.latitude = cloudHesitation.latitude
                        hesitation.longitude = cloudHesitation.longitude
                        hesitation.startTime = cloudHesitation.startTime
                        hesitation.endTime = cloudHesitation.endTime
                        hesitation.duration = cloudHesitation.duration
                        localJourneyData.hesitationPoints.append(hesitation)
                    }
                }
                print("🔄 Updated local journey data from cloud: \(journeyRealmId)")
            }
        } else {
            // Create new JourneyRealm from cloud
            try! realm.write {
                let newJourneyData = JourneyRealm()
                newJourneyData.id = journeyRealmId
                newJourneyData.startTime = cloudJourneyData.startTime
                newJourneyData.endTime = cloudJourneyData.endTime ?? Date()
                    newJourneyData.distance = cloudJourneyData.distance
                    newJourneyData.duration = cloudJourneyData.duration
                    newJourneyData.isDeleted = cloudJourneyData.isDeleted
                    newJourneyData.updatedAt = cloudUpdatedAt
                    newJourneyData.isSynced = true
                    newJourneyData.needsSync = false
                    newJourneyData.lastSyncedAt = Date()
                    
                    // Add path points from JSON
                    for cloudPoint in cloudPathPoints {
                        let pathPoint = PathPointRealm()
                        pathPoint.latitude = cloudPoint.latitude
                        pathPoint.longitude = cloudPoint.longitude
                        pathPoint.timestamp = cloudPoint.timestamp
                        newJourneyData.pathPoints.append(pathPoint)
                    }
                    
                    // Add checkpoints from JSON
                    for cloudCheckpoint in cloudCheckpoints {
                        let checkpoint = FeelingCheckpointRealm()
                        checkpoint.id = cloudCheckpoint.id
                        checkpoint.latitude = cloudCheckpoint.latitude
                        checkpoint.longitude = cloudCheckpoint.longitude
                        checkpoint.feeling = cloudCheckpoint.feeling
                        checkpoint.timestamp = cloudCheckpoint.timestamp
                        newJourneyData.checkpoints.append(checkpoint)
                    }
                    
                    // Add hesitation points from JSON
                    for cloudHesitation in cloudHesitationPoints {
                        let hesitation = HesitationPointRealm()
                        hesitation.id = cloudHesitation.id
                        hesitation.latitude = cloudHesitation.latitude
                        hesitation.longitude = cloudHesitation.longitude
                        hesitation.startTime = cloudHesitation.startTime
                        hesitation.endTime = cloudHesitation.endTime
                        hesitation.duration = cloudHesitation.duration
                        newJourneyData.hesitationPoints.append(hesitation)
                    }
                
                realm.add(newJourneyData)
            }
            print("✨ Created new local journey data from cloud: \(journeyRealmId)")
        }
    }
    
    // MARK: - Sync Journey Data (Location Points, Checkpoints)
    
    private func syncJourneyData(journeyId: UUID) async throws {
        guard let realm = try? await Realm() else { return }
        
        // Find JourneyRealm by matching ID (JourneyRealm.id is String, Journey.id is UUID)
        let journeyRealmId = journeyId.uuidString
        guard let journeyRealm = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyRealmId),
              journeyRealm.needsSync else {
            // No journey data or already synced
            return
        }
        
        let userId = try await getCurrentUserId()
        
        // Convert JourneyRealm.id (String) to UUID for journey_data table
        guard let journeyDataUUID = UUID(uuidString: journeyRealmId) else {
            print("❌ Invalid journey data ID: \(journeyRealmId)")
            return
        }
        
        // Convert path points to JSON format
        let pathPointsJson: [PathPointJSON] = Array(journeyRealm.pathPoints.map { pathPoint in
            PathPointJSON(
                latitude: pathPoint.latitude,
                longitude: pathPoint.longitude,
                timestamp: pathPoint.timestamp
            )
        })
        
        // Convert checkpoints to JSON format
        let checkpointsJson: [CheckpointJSON] = Array(journeyRealm.checkpoints.map { checkpoint in
            CheckpointJSON(
                id: checkpoint.id,
                latitude: checkpoint.latitude,
                longitude: checkpoint.longitude,
                feeling: checkpoint.feeling,
                timestamp: checkpoint.timestamp
            )
        })
        
        // Convert hesitation points to JSON format
        let hesitationPointsJson: [HesitationPointJSON] = Array(journeyRealm.hesitationPoints.map { hesitation in
            HesitationPointJSON(
                id: hesitation.id,
                latitude: hesitation.latitude,
                longitude: hesitation.longitude,
                startTime: hesitation.startTime,
                endTime: hesitation.endTime,
                duration: hesitation.duration
            )
        })
        
        // Sync journey_data with path points, checkpoints, and hesitation points as JSON
        let dbJourneyData = JourneyDataDB(
            id: journeyDataUUID,
            journeyId: journeyId,
            userId: userId,
            startTime: journeyRealm.startTime,
            endTime: journeyRealm.endTime,
            distance: journeyRealm.distance,
            duration: journeyRealm.duration,
            pathPointsJson: pathPointsJson.isEmpty ? nil : pathPointsJson,
            checkpointsJson: checkpointsJson.isEmpty ? nil : checkpointsJson,
            hesitationPointsJson: hesitationPointsJson.isEmpty ? nil : hesitationPointsJson,
            createdAt: nil,
            updatedAt: journeyRealm.updatedAt,
            isDeleted: journeyRealm.isDeleted
        )
        
        try await supabase
            .from("journey_data")
            .upsert(dbJourneyData)
            .execute()
        
        // Mark JourneyRealm as synced
        if let updateRealm = try? await Realm(),
           let journeyDataToUpdate = updateRealm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyRealmId) {
            try! updateRealm.write {
                journeyDataToUpdate.isSynced = true
                journeyDataToUpdate.needsSync = false
                journeyDataToUpdate.lastSyncedAt = Date()
            }
        }
        
        print("✅ Synced journey data with \(journeyRealm.pathPoints.count) path points, \(journeyRealm.checkpoints.count) checkpoints, and \(journeyRealm.hesitationPoints.count) hesitation points (stored as JSON)")
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        let uuidString = session.user.id.uuidString
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "JourneySync", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        return uuid
    }
}

// MARK: - Realm Extensions for Journey Operations

extension Realm {
    /// Save or update a journey with sync tracking
    func saveJourney(_ journey: Journey, needsSync: Bool = true) {
        try! write {
            journey.updatedAt = Date()
            journey.needsSync = needsSync
            journey.isSynced = false
            add(journey, update: .modified)
        }
        print("🗺️ saveJourney: Saved journey \(journey.id) with needsSync=\(needsSync)")
    }
    
    /// Soft delete a journey
    func deleteJourney(_ journey: Journey) {
        try! write {
            journey.isDeleted = true
            journey.updatedAt = Date()
            journey.needsSync = true
            journey.isSynced = false
        }
    }
    
    /// Save or update journey data (JourneyRealm) with sync tracking
    func saveJourneyData(_ journeyData: JourneyRealm, needsSync: Bool = true) {
        try! write {
            journeyData.updatedAt = Date()
            journeyData.needsSync = needsSync
            journeyData.isSynced = false
            add(journeyData, update: .modified)
        }
    }
    
    /// Soft delete journey data
    func deleteJourneyData(_ journeyData: JourneyRealm) {
        try! write {
            journeyData.isDeleted = true
            journeyData.updatedAt = Date()
            journeyData.needsSync = true
            journeyData.isSynced = false
        }
    }
}

