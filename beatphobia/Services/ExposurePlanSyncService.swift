//
//  ExposurePlanSyncService.swift
//  beatphobia
//
//  Handles bidirectional sync between local Realm storage and Supabase cloud for exposure plans
//

import Foundation
import RealmSwift
import Supabase
import Combine

// MARK: - Supabase Exposure Plan Model
struct ExposurePlanDB: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let createdAt: Date?
    let updatedAt: Date?
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

// MARK: - Supabase Exposure Target Model
struct ExposureTargetDB: Codable {
    let id: UUID
    let planId: UUID
    let userId: UUID
    let name: String
    let latitude: Double
    let longitude: Double
    let waitTimeSeconds: Int
    let orderIndex: Int
    let createdAt: Date?
    let updatedAt: Date?
    let isDeleted: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case planId = "plan_id"
        case userId = "user_id"
        case name
        case latitude
        case longitude
        case waitTimeSeconds = "wait_time_seconds"
        case orderIndex = "order_index"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isDeleted = "is_deleted"
    }
}

// MARK: - Update Payload Models
struct ExposurePlanDeleteUpdate: Codable {
    let isDeleted: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case isDeleted = "is_deleted"
        case updatedAt = "updated_at"
    }
}

struct ExposureTargetDeleteUpdate: Codable {
    let isDeleted: Bool
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case isDeleted = "is_deleted"
        case updatedAt = "updated_at"
    }
}

@MainActor
class ExposurePlanSyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    init() {
        // Load last sync date from UserDefaults
        if let lastSync = UserDefaults.standard.object(forKey: "lastExposurePlanSyncDate") as? Date {
            self.lastSyncDate = lastSync
        }
    }
    
    // MARK: - Manual Sync
    
    /// Sync all local changes to cloud and pull cloud changes
    @MainActor
    func syncAll() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            print("📋 ExposurePlan syncAll: Starting push local changes...")
            // 1. Push local changes to cloud
            try await pushLocalChanges()
            print("📋 ExposurePlan syncAll: Push completed, starting pull...")
            
            // 2. Pull cloud changes to local
            try await pullCloudChanges()
            
            // Update last sync date
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastExposurePlanSyncDate")
            
            print("✅ ExposurePlan sync completed successfully")
        } catch {
            syncError = error.localizedDescription
            print("❌ ExposurePlan sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    /// Sync a single plan and its targets
    @MainActor
    func syncPlan(_ plan: ExposurePlan) async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            try await pushPlan(plan)
            print("✅ ExposurePlan \(plan.id) synced successfully")
        } catch {
            syncError = error.localizedDescription
            print("❌ ExposurePlan sync error: \(error)")
        }
        
        isSyncing = false
    }
    
    // MARK: - Push Local Changes
    
    private func pushLocalChanges() async throws {
        guard let realm = try? await Realm() else {
            throw NSError(domain: "ExposurePlanSync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Realm"])
        }
        
        // Get all plans that need syncing
        let plansToSync = realm.objects(ExposurePlan.self).filter("needsSync == true")
        
        guard !plansToSync.isEmpty else {
            print("📤 pushLocalChanges: No local plan changes to push")
            return
        }
        
        print("📤 pushLocalChanges: Pushing \(plansToSync.count) plan changes to cloud...")
        
        // Copy plan IDs to avoid thread issues
        let planIDs = Array(plansToSync.map { $0.id })
        
        for planID in planIDs {
            guard let realm = try? await Realm(),
                  let plan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: planID) else {
                continue
            }
            
            try await pushPlan(plan)
        }
    }
    
    private func pushPlan(_ plan: ExposurePlan) async throws {
        let userId = try await getCurrentUserId()
        
        // Prepare plan data for Supabase
        let dbPlan = ExposurePlanDB(
            id: plan.id,
            userId: userId,
            name: plan.name,
            createdAt: plan.createdAt,
            updatedAt: plan.updatedAt,
            isDeleted: plan.isDeleted
        )
        
        // For deletions, use UPDATE directly
        if plan.isDeleted {
            let dateFormatter = ISO8601DateFormatter()
            let updatedAtString = dateFormatter.string(from: plan.updatedAt)
            let deleteUpdate = ExposurePlanDeleteUpdate(isDeleted: true, updatedAt: updatedAtString)
            
            do {
                try await supabase
                    .from("exposure_plans")
                    .update(deleteUpdate)
                    .eq("id", value: plan.id)
                    .execute()
                print("🗑️ Deleted plan \(plan.id) from cloud...")
            } catch {
                print("⚠️ Could not update plan deletion in cloud: \(error.localizedDescription)")
            }
        } else {
            // Upsert to Supabase
            try await supabase
                .from("exposure_plans")
                .upsert(dbPlan)
                .execute()
            print("📋 Pushing plan \(plan.id) to cloud...")
        }
        
        // Sync targets
        try await pushTargets(for: plan)
        
        // Mark plan as synced
        if let realm = try? await Realm(),
           let planToUpdate = realm.object(ofType: ExposurePlan.self, forPrimaryKey: plan.id) {
            try! realm.write {
                planToUpdate.isSynced = true
                planToUpdate.needsSync = false
                planToUpdate.lastSyncedAt = Date()
            }
        }
    }
    
    private func pushTargets(for plan: ExposurePlan) async throws {
        let userId = try await getCurrentUserId()
        let targets = plan.targets.filter { !$0.isDeleted || $0.needsSync }
        
        for target in targets {
            let dbTarget = ExposureTargetDB(
                id: target.id,
                planId: plan.id,
                userId: userId,
                name: target.name,
                latitude: target.latitude,
                longitude: target.longitude,
                waitTimeSeconds: target.waitTimeInSeconds,
                orderIndex: target.orderIndex,
                createdAt: target.createdAt,
                updatedAt: target.updatedAt,
                isDeleted: target.isDeleted
            )
            
            // For deletions, use UPDATE directly
            if target.isDeleted {
                let dateFormatter = ISO8601DateFormatter()
                let updatedAtString = dateFormatter.string(from: target.updatedAt)
                let deleteUpdate = ExposureTargetDeleteUpdate(isDeleted: true, updatedAt: updatedAtString)
                
                do {
                    try await supabase
                        .from("exposure_targets")
                        .update(deleteUpdate)
                        .eq("id", value: target.id)
                        .execute()
                } catch {
                    print("⚠️ Could not update target deletion in cloud: \(error.localizedDescription)")
                }
            } else {
                // Upsert to Supabase
                try await supabase
                    .from("exposure_targets")
                    .upsert(dbTarget)
                    .execute()
            }
            
            // Mark target as synced
            if let realm = try? await Realm(),
               let targetToUpdate = realm.object(ofType: ExposureTarget.self, forPrimaryKey: target.id) {
                try! realm.write {
                    targetToUpdate.isSynced = true
                    targetToUpdate.needsSync = false
                    targetToUpdate.lastSyncedAt = Date()
                }
            }
        }
    }
    
    // MARK: - Pull Cloud Changes
    
    private func pullCloudChanges() async throws {
        let userId = try await getCurrentUserId()
        
        // Pull plans
        let remotePlans: [ExposurePlanDB] = try await supabase
            .from("exposure_plans")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value
        
        guard let realm = try? await Realm() else {
            throw NSError(domain: "ExposurePlanSync", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize Realm"])
        }
        
        for remotePlan in remotePlans {
            // Check if plan exists locally
            if let localPlan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: remotePlan.id) {
                // Update if remote is newer
                if let remoteUpdatedAt = remotePlan.updatedAt,
                   remoteUpdatedAt > localPlan.updatedAt {
                    try! realm.write {
                        localPlan.name = remotePlan.name
                        localPlan.updatedAt = remoteUpdatedAt
                        localPlan.isDeleted = remotePlan.isDeleted
                        localPlan.isSynced = true
                        localPlan.needsSync = false
                        localPlan.lastSyncedAt = Date()
                    }
                }
            } else if !remotePlan.isDeleted {
                // Create new plan from remote
                let newPlan = ExposurePlan()
                newPlan.id = remotePlan.id
                newPlan.name = remotePlan.name
                newPlan.createdAt = remotePlan.createdAt ?? Date()
                newPlan.updatedAt = remotePlan.updatedAt ?? Date()
                newPlan.isDeleted = remotePlan.isDeleted
                newPlan.isSynced = true
                newPlan.needsSync = false
                newPlan.lastSyncedAt = Date()
                
                try! realm.write {
                    realm.add(newPlan)
                }
            }
            
            // Pull targets for this plan
            try await pullTargets(for: remotePlan.id, userId: userId)
        }
    }
    
    private func pullTargets(for planId: UUID, userId: UUID) async throws {
        let remoteTargets: [ExposureTargetDB] = try await supabase
            .from("exposure_targets")
            .select()
            .eq("plan_id", value: planId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        guard let realm = try? await Realm(),
              let plan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: planId) else {
            return
        }
        
        for remoteTarget in remoteTargets {
            // Check if target exists locally
            if let localTarget = realm.object(ofType: ExposureTarget.self, forPrimaryKey: remoteTarget.id) {
                // Update if remote is newer
                if let remoteUpdatedAt = remoteTarget.updatedAt,
                   remoteUpdatedAt > localTarget.updatedAt {
                    try! realm.write {
                        localTarget.name = remoteTarget.name
                        localTarget.latitude = remoteTarget.latitude
                        localTarget.longitude = remoteTarget.longitude
                        localTarget.waitTimeInSeconds = remoteTarget.waitTimeSeconds
                        localTarget.orderIndex = remoteTarget.orderIndex
                        localTarget.updatedAt = remoteUpdatedAt
                        localTarget.isDeleted = remoteTarget.isDeleted
                        localTarget.isSynced = true
                        localTarget.needsSync = false
                        localTarget.lastSyncedAt = Date()
                    }
                }
            } else if !remoteTarget.isDeleted {
                // Create new target from remote
                let newTarget = ExposureTarget()
                newTarget.id = remoteTarget.id
                newTarget.planId = planId
                newTarget.name = remoteTarget.name
                newTarget.latitude = remoteTarget.latitude
                newTarget.longitude = remoteTarget.longitude
                newTarget.waitTimeInSeconds = remoteTarget.waitTimeSeconds
                newTarget.orderIndex = remoteTarget.orderIndex
                newTarget.createdAt = remoteTarget.createdAt ?? Date()
                newTarget.updatedAt = remoteTarget.updatedAt ?? Date()
                newTarget.isDeleted = remoteTarget.isDeleted
                newTarget.isSynced = true
                newTarget.needsSync = false
                newTarget.lastSyncedAt = Date()
                
                try! realm.write {
                    plan.targets.append(newTarget)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getCurrentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        let uuidString = session.user.id.uuidString
        guard let uuid = UUID(uuidString: uuidString) else {
            throw NSError(domain: "ExposurePlanSync", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        return uuid
    }
}

// MARK: - Realm Extensions for Exposure Plan Operations

extension Realm {
    /// Save or update an exposure plan with sync tracking
    func saveExposurePlan(_ plan: ExposurePlan, needsSync: Bool = true) {
        try! write {
            plan.updatedAt = Date()
            plan.needsSync = needsSync
            plan.isSynced = false
            add(plan, update: .modified)
        }
    }
    
    /// Soft delete an exposure plan
    func deleteExposurePlan(_ plan: ExposurePlan) {
        try! write {
            plan.isDeleted = true
            plan.updatedAt = Date()
            plan.needsSync = true
            plan.isSynced = false
        }
    }
    
    /// Save or update an exposure target with sync tracking
    func saveExposureTarget(_ target: ExposureTarget, needsSync: Bool = true) {
        try! write {
            target.updatedAt = Date()
            target.needsSync = needsSync
            target.isSynced = false
            add(target, update: .modified)
        }
    }
    
    /// Soft delete an exposure target
    func deleteExposureTarget(_ target: ExposureTarget) {
        try! write {
            target.isDeleted = true
            target.updatedAt = Date()
            target.needsSync = true
            target.isSynced = false
        }
    }
}

