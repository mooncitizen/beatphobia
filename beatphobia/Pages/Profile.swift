//
//  ProfileView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import SwiftUI
import Supabase
import CoreLocation

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isSigningOut = false
    @State private var signOutError: String?
    @State private var showUsernameChange = false
    @State private var showPaywall = false
    @State private var showAbout = false
    @State private var showCrisisHotlines = false
    
    @State private var locationStatus: CLAuthorizationStatus = .notDetermined
    
    @AppStorage("setting.notifications") private var enableNotifications = false
    @AppStorage("setting.vibrations") private var enableVibrations = false
    @AppStorage("setting.backup") private var enableBackup = false
    @AppStorage("setting.miles") private var enableMiles = false
    
    
    private var name: String {
        return authManager.currentUserProfile?.name ?? "N/A"
    }
    
    private var username: String {
        return authManager.currentUserProfile?.username ?? ""
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
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            Text(emailAddress)
                                .font(.subheadline)
                                .foregroundStyle(AppConstants.secondaryTextColor(for: colorScheme))
                                .fontDesign(.serif)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .padding(.horizontal, 20)
                    .background(AppConstants.cardBackgroundColor(for: colorScheme).opacity(0.5))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Crisis Hotlines Button
                    Button(action: {
                        showCrisisHotlines = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // Text
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Crisis Hotlines")
                                    .font(.system(size: 17, weight: .semibold))
                                    .fontDesign(.serif)
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                
                                Text("24/7 support lines")
                                    .font(.system(size: 12))
                                    .fontDesign(.serif)
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // About Button
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack(alignment: .center, spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            
                            // Text
                            Text("About")
                                .font(.system(size: 17, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    // Subscription Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Subscription")
                            .font(.title3.bold())
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        
                        Button(action: {
                            showPaywall = true
                        }) {
                            HStack(alignment: .center, spacing: 12) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: subscriptionManager.isPro ? [.green, .mint] : [.blue, .purple],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: subscriptionManager.isPro ? "checkmark.shield.fill" : "crown.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                                
                                // Text
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(subscriptionManager.isPro ? "Pro Member" : "Upgrade to Pro")
                                        .font(.system(size: 17, weight: .semibold))
                                        .fontDesign(.serif)
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    
                                    Text(subscriptionManager.isPro ? subscriptionManager.subscriptionStatus.statusDescription : "Unlock all premium features")
                                        .font(.system(size: 13))
                                        .fontDesign(.serif)
                                        .foregroundStyle(AppConstants.secondaryTextColor(for: colorScheme))
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Appearance Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Appearance")
                            .font(.title3.bold())
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            ForEach(ThemeOption.allCases, id: \.self) { theme in
                                Button(action: {
                                    withAnimation {
                                        themeManager.selectedTheme = theme
                                    }
                                }) {
                                    HStack(alignment: .center, spacing: 12) {
                                        // Theme icon
                                        Image(systemName: themeIcon(for: theme))
                                            .font(.system(size: 20))
                                            .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                                            .frame(width: 30)
                                        
                                        // Theme name
                                        Text(theme.rawValue)
                                            .font(.system(size: 17))
                                            .fontDesign(.serif)
                                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                        
                                        Spacer()
                                        
                                        // Checkmark if selected
                                        if themeManager.selectedTheme == theme {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 16)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if theme != ThemeOption.allCases.last {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Settings")
                            .font(.title3.bold())
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            // Username Setting (Navigation)
                            Button(action: {
                                showUsernameChange = true
                            }) {
                                HStack(alignment: .center, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Username")
                                            .font(.system(size: 17))
                                            .fontDesign(.serif)
                                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                        Text("@\(username.isEmpty ? "not_set" : username)")
                                            .font(.system(size: 13))
                                            .fontDesign(.serif)
                                            .foregroundStyle(AppConstants.secondaryTextColor(for: colorScheme))
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 16)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // Notifications Toggle
                            // SettingToggleRow(
                            //     isOn: $enableNotifications,
                            //     title: "Notifications",
                            //     description: "Allows us to send you notifications and reminders.",
                            //     showDivider: true
                            // )
                            
                            // Vibrations Toggle
                            // SettingToggleRow(
                            //     isOn: $enableVibrations,
                            //     title: "Vibrations",
                            //     description: "This enables vibrations inside tools such as Focus",
                            //     showDivider: true
                            // )
                            
                            // Miles Toggle
                            SettingToggleRow(
                                isOn: $enableMiles,
                                title: enableMiles ? "Miles" : "Kilometers",
                                description: enableMiles ? "Will display in miles/meters when displaying distances." : "Will display in kilometers/meters when displaying distances.",
                                showDivider: false,
                                colorScheme: colorScheme
                            )
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    
                    // Permissions Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Permissions")
                            .font(.title3.bold())
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                            .padding(.bottom, 12)
                        
                        VStack(spacing: 0) {
                            // Location Permission
                            PermissionRow(
                                icon: "location.fill",
                                iconColor: .blue,
                                title: "Location",
                                description: "Required for journey tracking",
                                status: locationAuthorizationStatusText,
                                statusColor: locationAuthorizationStatusColor,
                                action: openSettings,
                                colorScheme: colorScheme
                            )
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
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
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                checkPermissions()
            }
            .sheet(isPresented: $showUsernameChange) {
                UsernameSetupView(
                    existingUsername: username,
                    onComplete: {
                        // Refresh profile data
                        Task {
                            try? await authManager.getProfile()
                        }
                    }
                )
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    if subscriptionManager.isPro {
                        SubscriptionInfoView()
                            .environmentObject(subscriptionManager)
                    } else {
                        PaywallView()
                            .environmentObject(subscriptionManager)
                    }
                }
            }
            .sheet(isPresented: $showAbout) {
                NavigationStack {
                    AboutView()
                }
            }
            .sheet(isPresented: $showCrisisHotlines) {
                CrisisHotlinesView()
            }
        }
    }
    
    // MARK: - Permission Helpers
    
    private func checkPermissions() {
        // Check location permission
        locationStatus = CLLocationManager().authorizationStatus
    }
    
    private var locationAuthorizationStatusText: String {
        switch locationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Allowed"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var locationAuthorizationStatusColor: Color {
        switch locationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    private func themeIcon(for theme: ThemeOption) -> String {
        switch theme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "iphone"
        }
    }
}

// Custom Setting Toggle Row Component
struct SettingToggleRow: View {
    @Binding var isOn: Bool
    let title: String
    let description: String
    let showDivider: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    Text(description)
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                        .foregroundStyle(AppConstants.secondaryTextColor(for: colorScheme))
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

// Custom Permission Row Component
struct PermissionRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let status: String
    let statusColor: Color
    let action: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    Text(description)
                        .font(.system(size: 13))
                        .fontDesign(.serif)
                        .foregroundStyle(AppConstants.secondaryTextColor(for: colorScheme))
                }
                
                Spacer()
                
                // Status Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(status)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(statusColor)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let mockAuthManager = AuthManager()
    ProfileView()
        .environmentObject(mockAuthManager)
        .environmentObject(SubscriptionManager())
        .environmentObject(ThemeManager())
}
