//
//  SubscriptionInfoView.swift
//  beatphobia
//
//  Subscription management view for current Pro subscribers
//

import SwiftUI
import StoreKit

struct SubscriptionInfoView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var isRestoring = false
    @State private var showCancelConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.3), Color.mint.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text("Pro Member")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("You have access to all premium features")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Current Plan Details
                VStack(spacing: 20) {
                    Text("Current Plan")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    VStack(spacing: 0) {
                        // Plan Name
                        InfoRow(
                            title: "Plan",
                            value: subscriptionManager.currentTier.displayName,
                            colorScheme: colorScheme
                        )
                        
                        Divider()
                            .padding(.leading, 16)
                        
                        // Status
                        InfoRow(
                            title: "Status",
                            value: subscriptionManager.subscriptionStatus.statusDescription,
                            colorScheme: colorScheme
                        )
                        
                        // Expiration/Renewal Date
                        if let expirationDate = subscriptionManager.subscriptionStatus.expirationDate {
                            Divider()
                                .padding(.leading, 16)
                            
                            InfoRow(
                                title: subscriptionManager.subscriptionStatus.willAutoRenew ? "Renews On" : "Expires On",
                                value: formatDate(expirationDate),
                                colorScheme: colorScheme
                            )
                        }
                        
                        // Trial Info
                        if subscriptionManager.subscriptionStatus.isInTrial,
                           let trialEnd = subscriptionManager.subscriptionStatus.trialEndDate {
                            Divider()
                                .padding(.leading, 16)
                            
                            InfoRow(
                                title: "Trial Ends",
                                value: formatDate(trialEnd),
                                colorScheme: colorScheme
                            )
                        }
                    }
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(16)
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                
                // Premium Features
                VStack(spacing: 16) {
                    Text("Your Premium Features")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    VStack(spacing: 12) {
                        FeatureRow(
                            icon: "location.fill",
                            title: "Unlimited Location Tracking",
                            description: "Access your complete journey history",
                            gradient: [.blue, .cyan],
                            colorScheme: colorScheme
                        )
                        
                        FeatureRow(
                            icon: "icloud.fill",
                            title: "Cloud Journal Backup",
                            description: "Secure sync across all devices",
                            gradient: [.purple, .pink],
                            colorScheme: colorScheme
                        )
                        
                        FeatureRow(
                            icon: "chart.xyaxis.line",
                            title: "Detailed Metrics",
                            description: "Track patterns and insights over time",
                            gradient: [.orange, .red],
                            colorScheme: colorScheme
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Manage Subscription (opens App Store)
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Manage Subscription")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    // Restore Purchases
                    Button(action: handleRestore) {
                        HStack {
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: "arrow.clockwise")
                                Text("Restore Purchases")
                                    .font(.system(size: 15, weight: .medium, design: .rounded))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .disabled(isRestoring)
                }
                .padding(.horizontal, 20)
                
                // Footer Info
                VStack(spacing: 12) {
                    Text("Manage your subscription through the App Store. You can cancel or change your plan at any time.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    HStack(spacing: 20) {
                        Button("Support") {
                            if let url = URL(string: "https://stillstep.com/support") {
                                openURL(url)
                            }
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        Button("Terms") {
                            if let url = URL(string: "https://stillstep.com/terms") {
                                openURL(url)
                            }
                        }
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func handleRestore() {
        isRestoring = true
        
        Task {
            await subscriptionManager.restorePurchases()
            
            await MainActor.run {
                isRestoring = false
            }
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let title: String
    let value: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Feature Row (Small)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: gradient.map { $0.opacity(0.15) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(12)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        SubscriptionInfoView()
            .environmentObject(SubscriptionManager())
    }
}

