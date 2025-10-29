//
//  AppInfoView.swift
//  beatphobia
//
//  App information and open source attributions
//

import SwiftUI

struct LibraryInfo: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let license: String
    let url: String
    let icon: String
    let color: Color
}

struct AppInfoView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    private let libraries: [LibraryInfo] = [
        LibraryInfo(
            name: "Realm Swift",
            description: "Mobile database for local data storage and journal entries",
            license: "Apache 2.0",
            url: "https://github.com/realm/realm-swift",
            icon: "cylinder.fill",
            color: .purple
        ),
        LibraryInfo(
            name: "Supabase Swift",
            description: "Backend services for authentication, cloud sync, and community features",
            license: "MIT",
            url: "https://github.com/supabase/supabase-swift",
            icon: "cloud.fill",
            color: .green
        ),
        LibraryInfo(
            name: "Swift Crypto",
            description: "Apple's cryptographic operations library for secure data handling",
            license: "Apache 2.0",
            url: "https://github.com/apple/swift-crypto",
            icon: "lock.shield.fill",
            color: .blue
        ),
        LibraryInfo(
            name: "Swift Concurrency Extras",
            description: "Point-Free's utilities for async/await operations",
            license: "MIT",
            url: "https://github.com/pointfreeco/swift-concurrency-extras",
            icon: "arrow.triangle.branch",
            color: .orange
        )
    ]
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // App Icon and Info
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(AppConstants.appName)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Text("Mental wellness companion for managing anxiety and panic")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
                
                // Open Source Libraries
                VStack(alignment: .leading, spacing: 16) {
                    Text("Open Source Libraries")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .padding(.horizontal, 20)
                    
                    Text("This app is built with amazing open source software")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        ForEach(libraries) { library in
                            LibraryCard(library: library, colorScheme: colorScheme) {
                                if let url = URL(string: library.url) {
                                    openURL(url)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Additional Info
                VStack(spacing: 16) {
                    Divider()
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 12) {
                        InfoLinkButton(
                            icon: "globe",
                            title: "Visit Our Website",
                            url: "https://stillstep.com",
                            openURL: openURL,
                            colorScheme: colorScheme
                        )
                        
                        InfoLinkButton(
                            icon: "envelope.fill",
                            title: "Contact Support",
                            url: "mailto:support@stillstep.com",
                            openURL: openURL,
                            colorScheme: colorScheme
                        )
                        
                        InfoLinkButton(
                            icon: "doc.text.fill",
                            title: "Privacy Policy",
                            url: "https://stillstep.com/privacy",
                            openURL: openURL,
                            colorScheme: colorScheme
                        )
                        
                        InfoLinkButton(
                            icon: "doc.plaintext.fill",
                            title: "Terms of Service",
                            url: "https://stillstep.com/terms",
                            openURL: openURL,
                            colorScheme: colorScheme
                        )
                    }
                    .padding(.horizontal, 20)
                }
                
                // Copyright
                VStack(spacing: 8) {
                    Text("Made with ❤️ for mental wellness")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Text("© 2025 Still Step. All rights reserved.")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .padding(.bottom, 40)
            }
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("This App")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Library Card
struct LibraryCard: View {
    let library: LibraryInfo
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(library.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: library.icon)
                        .font(.system(size: 20))
                        .foregroundColor(library.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(library.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text(library.description)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(2)
                    
                    Text(library.license + " License")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(library.color)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Info Link Button
struct InfoLinkButton: View {
    let icon: String
    let title: String
    let url: String
    let openURL: OpenURLAction
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: {
            if let urlObject = URL(string: url) {
                openURL(urlObject)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .padding(14)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        AppInfoView()
    }
}

