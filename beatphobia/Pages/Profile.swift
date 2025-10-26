//
//  ProfileView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import SwiftUI
import Supabase

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var isSigningOut = false
    @State private var signOutError: String?
    
    @AppStorage("setting.notifications") private var enableNotifications = false
    @AppStorage("setting.vibrations") private var enableVibrations = false
    @AppStorage("setting.backup") private var enableBackup = false
    @AppStorage("setting.miles") private var enableMiles = false
    
    
    private var name: String {
        return authManager.currentUserProfile?.name ?? "N/A"
    }
    
    private var emailAddress: String {
        return authManager.currentUser?.email ?? "Loading..."
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Card at the top
                    VStack(spacing: 16) {
                        // Profile Avatar Circle
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.system(size: 36, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundColor(.blue)
                            )
                        
                        // Name and Email
                        VStack(spacing: 4) {
                            Text(name)
                                .font(.title2.bold())
                                .fontDesign(.serif)
                                .foregroundColor(.black)
                            Text(emailAddress)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                                .fontDesign(.serif)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Settings")
                            .font(.title3.bold())
                            .fontDesign(.serif)
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            // Notifications Toggle
                            SettingToggleRow(
                                isOn: $enableNotifications,
                                title: "Notifications",
                                description: "Allows us to send you notifications and reminders.",
                                showDivider: true
                            )
                            
                            // Vibrations Toggle
                            SettingToggleRow(
                                isOn: $enableVibrations,
                                title: "Vibrations",
                                description: "This enables vibrations inside tools such as Focus",
                                showDivider: true
                            )
                            
                            // Miles Toggle
                            SettingToggleRow(
                                isOn: $enableMiles,
                                title: enableMiles ? "Miles" : "Kilometers",
                                description: enableMiles ? "Will display in miles/meters when displaying distances." : "Will display in kilometers/meters when displaying distances.",
                                showDivider: false
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Logout Button
                    Button(action: {
                        Task {
                            await self.authManager.signOut()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .font(.body.bold())
                                .fontDesign(.serif)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .background(AppConstants.defaultBackgroundColor)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Custom Setting Toggle Row Component
struct SettingToggleRow: View {
    @Binding var isOn: Bool
    let title: String
    let description: String
    let showDivider: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    Text(description)
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Toggle("", isOn: $isOn)
                    .labelsHidden()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            if showDivider {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

#Preview {
    let mockAuthManager = AuthManager()
    ProfileView()
        .environmentObject(mockAuthManager)
}
