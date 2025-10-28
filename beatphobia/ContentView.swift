//
//  ContentView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var profileExists: Bool? = nil
    @State private var profileError: String?

    var body: some View {
        Group {
            if authManager.isLoading {
                FullScreenLoading(text: "Loading")
            } else {
                switch authManager.authState {
                case .signedIn:
                    Group {
                        if let profileError {
                            Text("Error: \(profileError)")
                        } else if profileExists == nil {
                            FullScreenLoading(text: "Loading")
                        } else if profileExists == true {
                            HomeView()
                        } else {
                            InitialProfileView()
                        }
                    }
                    .task {
                        await loadProfile()
                    }
                    
                case .signedOut:
                    SignInView()
                }
            }
        }
    }
    
    private func loadProfile() async {
        profileError = nil
        do {
            let profile = try await authManager.getProfile()
            profileExists = (profile != nil)
        } catch {
            profileError = error.localizedDescription
            print("Error loading profile: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
