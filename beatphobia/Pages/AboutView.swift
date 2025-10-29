//
//  AboutView.swift
//  beatphobia
//
//  Created by Assistant
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with App Icon
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
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Mental wellness companion")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // Navigation Cards
                VStack(spacing: 16) {
                    NavigationLink(destination: FAQView()) {
                        AboutCard(
                            icon: "questionmark.circle.fill",
                            title: "FAQ",
                            description: "Frequently asked questions",
                            gradient: [.blue, .cyan],
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    NavigationLink(destination: AppInfoView()) {
                        AboutCard(
                            icon: "info.circle.fill",
                            title: "This App",
                            description: "Version info & open source credits",
                            gradient: [.purple, .pink],
                            colorScheme: colorScheme
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About Card
struct AboutCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}

