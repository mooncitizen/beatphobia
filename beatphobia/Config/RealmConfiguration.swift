//
//  RealmConfiguration.swift
//  beatphobia
//
//  Realm migration configuration for schema updates
//

import Foundation
import RealmSwift

class RealmConfigurationManager {
    static func configure() {
        let config = Realm.Configuration(
            // Increment schema version when making model changes
            schemaVersion: 7, // Version 7: Journey.linkedPlanId and ExposurePlan models
            
            // Migration block to handle schema changes
            migrationBlock: { migration, oldSchemaVersion in
                print("🔄 Migrating Realm from version \(oldSchemaVersion) to version 7")
                
                // Migration to version 2: Journal sync properties
                if oldSchemaVersion < 2 {
                    print("📝 Migrating JournalEntryModel: Adding sync properties")
                    migration.enumerateObjects(ofType: "JournalEntryModel") { oldObject, newObject in
                        // Set default values for new properties
                        newObject?["isSynced"] = false
                        newObject?["needsSync"] = true // Mark existing entries for sync
                        newObject?["isDeleted"] = false
                        newObject?["lastSyncedAt"] = nil
                        newObject?["updatedAt"] = oldObject?["date"] ?? Date() // Use entry date as initial updated date
                    }
                }
                
                // Migration to version 3: Location tracking models
                if oldSchemaVersion < 3 {
                    print("📍 Migrating Location Tracking models: JourneyRealm, PathPointRealm, FeelingCheckpointRealm")
                    
                    // JourneyRealm migration - ensure schema is correct
                    migration.enumerateObjects(ofType: "JourneyRealm") { oldObject, newObject in
                        // Ensure all fields are properly initialized
                        if oldObject != nil {
                            // If journey exists, preserve its data
                            newObject?["id"] = oldObject?["id"] ?? ""
                            newObject?["startTime"] = oldObject?["startTime"] ?? Date()
                            newObject?["endTime"] = oldObject?["endTime"] ?? Date()
                            newObject?["distance"] = oldObject?["distance"] as? Double ?? 0.0
                            newObject?["duration"] = oldObject?["duration"] as? Int ?? 0
                        } else {
                            // Initialize empty journey with defaults
                            newObject?["id"] = UUID().uuidString
                            newObject?["startTime"] = Date()
                            newObject?["endTime"] = Date()
                            newObject?["distance"] = 0.0
                            newObject?["duration"] = 0
                        }
                    }
                    
                    // PathPointRealm migration
                    migration.enumerateObjects(ofType: "PathPointRealm") { oldObject, newObject in
                        if oldObject != nil {
                            newObject?["latitude"] = oldObject?["latitude"] as? Double ?? 0.0
                            newObject?["longitude"] = oldObject?["longitude"] as? Double ?? 0.0
                            newObject?["timestamp"] = oldObject?["timestamp"] ?? Date()
                        } else {
                            newObject?["latitude"] = 0.0
                            newObject?["longitude"] = 0.0
                            newObject?["timestamp"] = Date()
                        }
                    }
                    
                    // FeelingCheckpointRealm migration
                    migration.enumerateObjects(ofType: "FeelingCheckpointRealm") { oldObject, newObject in
                        if oldObject != nil {
                            newObject?["id"] = oldObject?["id"] ?? ""
                            newObject?["latitude"] = oldObject?["latitude"] as? Double ?? 0.0
                            newObject?["longitude"] = oldObject?["longitude"] as? Double ?? 0.0
                            newObject?["feeling"] = oldObject?["feeling"] ?? ""
                            newObject?["timestamp"] = oldObject?["timestamp"] ?? Date()
                        } else {
                            newObject?["id"] = UUID().uuidString
                            newObject?["latitude"] = 0.0
                            newObject?["longitude"] = 0.0
                            newObject?["feeling"] = ""
                            newObject?["timestamp"] = Date()
                        }
                    }
                    
                    print("✅ Location tracking models migration complete")
                }
                
                // Migration to version 4: Journey sync properties
                if oldSchemaVersion < 4 {
                    print("🗺️ Migrating Journey: Adding sync properties")
                    migration.enumerateObjects(ofType: "Journey") { oldObject, newObject in
                        // Set default values for new sync properties
                        newObject?["isSynced"] = false
                        newObject?["needsSync"] = true // Mark existing journeys for sync
                        newObject?["isDeleted"] = false
                        newObject?["lastSyncedAt"] = nil
                        newObject?["updatedAt"] = oldObject?["startDate"] ?? Date() // Use start date as initial updated date
                    }
                    print("✅ Journey sync properties migration complete")
                }
                
                // Migration to version 5: JourneyRealm sync properties
                if oldSchemaVersion < 5 {
                    print("🗺️ Migrating JourneyRealm: Adding sync properties")
                    migration.enumerateObjects(ofType: "JourneyRealm") { oldObject, newObject in
                        // Set default values for new sync properties
                        newObject?["isSynced"] = false
                        newObject?["needsSync"] = true // Mark existing journey data for sync
                        newObject?["isDeleted"] = false
                        newObject?["lastSyncedAt"] = nil
                        newObject?["updatedAt"] = oldObject?["startTime"] ?? Date() // Use start time as initial updated date
                    }
                    print("✅ JourneyRealm sync properties migration complete")
                }
                
                // Migration to version 6: HesitationPointRealm and SafeAreaPointRealm models
                if oldSchemaVersion < 6 {
                    print("📍 Migrating Location Tracking: Adding HesitationPointRealm and SafeAreaPointRealm models")
                    
                    // JourneyRealm: Add hesitationPoints list
                    migration.enumerateObjects(ofType: "JourneyRealm") { oldObject, newObject in
                        // hesitationPoints list will be empty for existing journeys
                        // This is fine as hesitation detection starts after migration
                    }
                    
                    // HesitationPointRealm and SafeAreaPointRealm are new models
                    // Realm will create them automatically, no migration needed for empty tables
                    
                    print("✅ HesitationPointRealm and SafeAreaPointRealm models migration complete")
                }
                
                // Migration to version 7: Journey.linkedPlanId and ExposurePlan models
                if oldSchemaVersion < 7 {
                    print("📋 Migrating Journey: Adding linkedPlanId property")
                    migration.enumerateObjects(ofType: "Journey") { oldObject, newObject in
                        // Set default value for new linkedPlanId property (nil/optional)
                        newObject?["linkedPlanId"] = nil
                    }
                    
                    // ExposurePlan and ExposureTarget are new models
                    // Realm will create them automatically, no migration needed for empty tables
                    
                    print("✅ Journey.linkedPlanId and ExposurePlan models migration complete")
                }
            }
        )
        
        // Set as default configuration
        Realm.Configuration.defaultConfiguration = config
        
        print("✅ Realm configured with schema version \(config.schemaVersion)")
    }
}
