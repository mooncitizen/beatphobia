//
//  beatphobiaApp.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct beatphobiaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager: AuthManager
    @StateObject private var journalSyncService: JournalSyncService
    @StateObject private var journeySyncService: JourneySyncService
    @StateObject private var subscriptionManager: SubscriptionManager
    @StateObject private var themeManager: ThemeManager
    @StateObject private var notificationManager: NotificationManager
    
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
            "app_theme": ThemeOption.system.rawValue, // Default theme preference
        ]
        UserDefaults.standard.register(defaults: defaults)
        
        // Initialize StateObjects using underscore syntax
        _authManager = StateObject(wrappedValue: AuthManager())
        _journalSyncService = StateObject(wrappedValue: JournalSyncService())
        _journeySyncService = StateObject(wrappedValue: JourneySyncService())
        _subscriptionManager = StateObject(wrappedValue: SubscriptionManager())
        _themeManager = StateObject(wrappedValue: ThemeManager())
        _notificationManager = StateObject(wrappedValue: NotificationManager.shared)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(journalSyncService)
                .environmentObject(journeySyncService)
                .environmentObject(subscriptionManager)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.selectedTheme.colorScheme)
                .onAppear {
                    // Connect subscription manager to sync services
                    journalSyncService.setSubscriptionManager(subscriptionManager)
                    journeySyncService.setSubscriptionManager(subscriptionManager)
                    
                    // Start automatic syncing (will check Pro status)
                    journalSyncService.startAutoSync()
                    journeySyncService.startAutoSync()
                }
        }
    }
}
