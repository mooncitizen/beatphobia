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
            schemaVersion: 3, // Was 2 for sync properties, now 3 for location tracking models
            
            // Migration block to handle schema changes
            migrationBlock: { migration, oldSchemaVersion in
                print("🔄 Migrating Realm from version \(oldSchemaVersion) to version 3")
                
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
            }
        )
        
        // Set as default configuration
        Realm.Configuration.defaultConfiguration = config
        
        print("✅ Realm configured with schema version \(config.schemaVersion)")
    }
}
