//
//  Journeys.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import SwiftUI
import RealmSwift

struct JourneysView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var isTabBarVisible: Bool
    
    var body: some View {
        NavigationView {
            JourneyAgorahobiaView(isTabBarVisible: $isTabBarVisible)
        }
    }
}

#Preview {
    @Previewable @State var isTabBarVisible = true
    let mockAuthManager = AuthManager()
    
    JourneysView(isTabBarVisible: $isTabBarVisible)
        .environmentObject(mockAuthManager)
}
