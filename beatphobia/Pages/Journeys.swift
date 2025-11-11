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
    @EnvironmentObject var journalSyncService: JournalSyncService
    @EnvironmentObject var journeySyncService: JourneySyncService
    @Binding var isTabBarVisible: Bool
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            JourneyAgorahobiaView(isTabBarVisible: $isTabBarVisible)
                .environmentObject(journalSyncService)
                .environmentObject(journeySyncService)
        }
    }
}

#Preview {
    @Previewable @State var isTabBarVisible = true
    let mockAuthManager = AuthManager()
    let mockJournalSyncService = JournalSyncService()

    JourneysView(isTabBarVisible: $isTabBarVisible)
        .environmentObject(mockAuthManager)
        .environmentObject(mockJournalSyncService)
}
