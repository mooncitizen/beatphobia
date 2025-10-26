//
//  HomeView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI

struct HomeView: View {
    // Injecting the AuthManager for potential Sign Out functionality in the Profile tab
    @EnvironmentObject var authManager: AuthManager
    
    // Optional: State to manage the currently selected tab
    @State private var selectedTab: Tab = .journeys
    
    // State to control tab bar visibility
    @State private var isTabBarVisible: Bool = true
    
    // Defines the tabs and their associated system images/titles
    enum Tab: String {
        case journeys = "Journeys"
        case community = "Community"
        case journal = "Journal"
        case profile = "Profile"
        
        var systemImage: String {
            switch self {
            case .journeys: return "brain.head.profile"
            case .community: return "bubble.left.and.bubble.right"
            case .journal: return "book.pages"
            case .profile: return "person.crop.circle"
            }
        }
    }
    
    var body: some View {
        // MARK: - Main TabView Container (iOS 26 Best Practice)
        TabView(selection: $selectedTab) {
            
            // 1. Phobia Journeys Tab
            JourneysView(isTabBarVisible: $isTabBarVisible)
                .tabItem {
                    Image(systemName: Tab.journeys.systemImage)
                }
                .tag(Tab.journeys)
            
            CommunityOverview()
                .tabItem {
                    Image(systemName: Tab.community.systemImage)
                }
                .tag(Tab.community)

            // 2. Journal Tab
            JournalHome()
                .tabItem {
                    Image(systemName: Tab.journal.systemImage)
                }
                .tag(Tab.journal)
            
            // 3. Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: Tab.profile.systemImage)
                }
                .tag(Tab.profile)
        }
        // Apply custom font globally to all tab items for consistency
        .font(.custom(AppConstants.defaultFontName, size: 12))
        // Hide/show tab bar based on state
        .toolbar(isTabBarVisible ? .visible : .hidden, for: .tabBar)
    }
}

struct ForumView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Forum")
            }
            .navigationTitle("Forum")
        }
    }
}


#Preview {
    let mockAuthManager = AuthManager()
        
    HomeView()
        .environmentObject(mockAuthManager)
}
