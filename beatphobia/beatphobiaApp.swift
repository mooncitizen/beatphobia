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
    @StateObject var authManager = AuthManager()
    
    
    init() {
        checkSupabaseConfiguration()
        registerUserDefaults()
    }
    
    private func registerUserDefaults() {
        let defaults: [String: Any] = [
            "setting.notifications": true,
            "setting.vibrations": true,
            "setting.backup": true,
            "setting.miles": true,
        ]
        
        UserDefaults.standard.register(defaults: defaults)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(authManager)
        }
    }
}
