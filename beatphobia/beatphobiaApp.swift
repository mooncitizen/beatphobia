//
//  beatphobiaApp.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI
import SwiftData

@main
struct beatphobiaApp: App {
    @StateObject private var authManager: AuthManager
    @StateObject private var journalSyncService: JournalSyncService
    @StateObject private var subscriptionManager: SubscriptionManager
    
    init() {
        // Configure Realm before any Realm operations
        RealmConfigurationManager.configure()
        
        checkSupabaseConfiguration()
        
        // Register defaults
        let defaults: [String: Any] = [
            "setting.notifications": true,
            "setting.vibrations": true,
            "setting.backup": true,
            "setting.miles": true,
            "shown_paywall": false, // Track if paywall has been shown once
        ]
        UserDefaults.standard.register(defaults: defaults)
        
        // Initialize StateObjects using underscore syntax
        _authManager = StateObject(wrappedValue: AuthManager())
        _journalSyncService = StateObject(wrappedValue: JournalSyncService())
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(journalSyncService)
                .environmentObject(subscriptionManager)
                .onAppear {
                    // Connect subscription manager to journal sync service
                    journalSyncService.setSubscriptionManager(subscriptionManager)
                    
                    // Start automatic journal syncing (will check Pro status)
                    journalSyncService.startAutoSync()
                }
        }
    }
}
