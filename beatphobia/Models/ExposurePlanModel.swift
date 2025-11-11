//
//  ExposurePlanModel.swift
//  beatphobia
//
//  Created for Guided Exposure Plans feature
//

import Foundation
import RealmSwift

final class ExposurePlan: Object, ObjectKeyIdentifiable, Identifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var name: String = ""
    @Persisted var targets = RealmSwift.List<ExposureTarget>()
    
    // Sync metadata
    @Persisted var isSynced: Bool = false // Has been synced to cloud
    @Persisted var needsSync: Bool = false // Needs to be synced (create/update)
    @Persisted var isDeleted: Bool = false // Soft delete flag
    @Persisted var lastSyncedAt: Date? = nil // Last successful sync timestamp
    @Persisted var updatedAt: Date = Date() // Last local update
    @Persisted var createdAt: Date = Date() // Creation timestamp
}

final class ExposureTarget: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var id: UUID = UUID()
    @Persisted var planId: UUID = UUID() // Reference to parent plan
    @Persisted var name: String = ""
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var waitTimeInSeconds: Int = 0
    @Persisted var orderIndex: Int = 0
    
    // Sync metadata
    @Persisted var isSynced: Bool = false // Has been synced to cloud
    @Persisted var needsSync: Bool = false // Needs to be synced (create/update)
    @Persisted var isDeleted: Bool = false // Soft delete flag
    @Persisted var lastSyncedAt: Date? = nil // Last successful sync timestamp
    @Persisted var updatedAt: Date = Date() // Last local update
    @Persisted var createdAt: Date = Date() // Creation timestamp
}

