//
//  RealmConfiguration.swift
//  beatphobia
//
//  Realm migration configuration for schema updates
//

import Foundation
import RealmSwift
import Realm

class RealmConfigurationManager {
    static func configure() {
        let config = Realm.Configuration(
            // Increment schema version when making model changes
            schemaVersion: 2, // Was 1 (or 0), now 2 for sync properties
            
            // Migration block to handle schema changes
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 2 {
                    // Migration from version 1 (or 0) to version 2
                    // Adding sync properties to JournalEntryModel
                    migration.enumerateObjects(ofType: "JournalEntryModel") { oldObject, newObject in
                        // Set default values for new properties
                        newObject?["isSynced"] = false
                        newObject?["needsSync"] = true // Mark existing entries for sync
                        newObject?["isDeleted"] = false
                        newObject?["lastSyncedAt"] = nil
                        newObject?["updatedAt"] = oldObject?["date"] ?? Date() // Use entry date as initial updated date
                    }
                }
            }
        )
        
        // Set as default configuration
        Realm.Configuration.defaultConfiguration = config
        
        print("✅ Realm configured with schema version \(config.schemaVersion)")
    }
}


