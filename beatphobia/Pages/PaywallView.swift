//
//  PaywallView.swift
//  beatphobia
//
//  Created by Assistant
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    @State private var selectedTier: SubscriptionTier = .proYearly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                        VStack(spacing: 16) {
                            // Icon with animated gradient
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.yellow, .orange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            
                            Text("Upgrade to Pro")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock advanced features for your journey. We only charge for cloud storage and sync.")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                        
                        // Pro Features - Compact Grid
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                CompactFeatureCard(
                                    icon: "location.fill",
                                    title: "Unlimited\nTracking",
                                    gradient: [.blue, .cyan]
                                )
                                
                                CompactFeatureCard(
                                    icon: "icloud.fill",
                                    title: "Cloud\nBackup",
                                    gradient: [.purple, .pink]
                                )
                            }
                            
                            HStack(spacing: 16) {
                                CompactFeatureCard(
                                    icon: "chart.xyaxis.line",
                                    title: "Detailed\nMetrics",
                                    gradient: [.orange, .red]
                                )
                                
                                CompactFeatureCard(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Multi-Device\nSync",
                                    gradient: [.green, .mint]
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Pricing Cards
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding(.top, 8)
                            
                            if let yearlyProduct = subscriptionManager.getProduct(for: .proYearly),
                               let monthlyProduct = subscriptionManager.getProduct(for: .proMonthly) {
                                
                                // Yearly Plan (Recommended)
                                PricingCard(
                                    tier: .proYearly,
                                    product: yearlyProduct,
                                    isSelected: selectedTier == .proYearly,
                                    savingsPercentage: subscriptionManager.getSavingsPercentage(),
                                    pricePerMonth: subscriptionManager.getPricePerMonth(for: .proYearly)
                                ) {
                                    selectedTier = .proYearly
                                }
                                
                                // Monthly Plan
                                PricingCard(
                                    tier: .proMonthly,
                                    product: monthlyProduct,
                                    isSelected: selectedTier == .proMonthly,
                                    savingsPercentage: nil,
                                    pricePerMonth: subscriptionManager.getPricePerMonth(for: .proMonthly)
                                ) {
                                    selectedTier = .proMonthly
                                }
                            } else {
                                VStack(spacing: 16) {
                                    ProgressView()
                                    Text("Loading products...")
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                    
                                    Button(action: {
                                        Task {
                                            await subscriptionManager.fetchProducts()
                                        }
                                    }) {
                                        Label("Retry", systemImage: "arrow.clockwise")
                                            .font(.system(size: 14, weight: .medium, design: .serif))
                                            .foregroundColor(.blue)
                                    }
                                    
                                    if let error = subscriptionManager.lastError {
                                        Text(error.errorDescription ?? "Unknown error")
                                            .font(.system(size: 12, design: .serif))
                                            .foregroundColor(.red)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Subscribe Button
                        Button(action: handlePurchase) {
                            HStack(spacing: 12) {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Continue with \(selectedTier.displayName)")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        }
                        .disabled(isPurchasing || subscriptionManager.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Restore Purchases Button
                        Button(action: handleRestore) {
                            Text("Restore Purchases")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        .disabled(isPurchasing)
                        .padding(.top, 8)
                        
                        // Terms and Privacy
                        VStack(spacing: 12) {
                            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            
                            HStack(spacing: 20) {
                                Button("Terms") {
                                    if let url = URL(string: "https://stillstep.com/terms") {
                                        openURL(url)
                                    }
                                }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.blue)
                                
                                Text("•")
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                
                                Button("Privacy") {
                                    if let url = URL(string: "https://stillstep.com/privacy") {
                                        openURL(url)
                                    }
                                }
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handlePurchase() {
        guard !isPurchasing else { return }
        
        isPurchasing = true
        
        Task {
            do {
                try await subscriptionManager.purchaseTier(selectedTier)
                
                // Mark paywall as shown after successful purchase
                UserDefaults.standard.set(true, forKey: "shown_paywall")
                
                // Dismiss the paywall
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    if let purchaseError = error as? PurchaseError {
                        // Don't show error for user cancellation
                        if case .userCancelled = purchaseError {
                            isPurchasing = false
                            return
                        }
                    }
                    
                    errorMessage = error.localizedDescription
                    showError = true
                    isPurchasing = false
                }
            }
        }
    }
    
    private func handleRestore() {
        isPurchasing = true
        
        Task {
            await subscriptionManager.restorePurchases()
            
            await MainActor.run {
                isPurchasing = false
                
                if subscriptionManager.isPro {
                    dismiss()
                } else {
                    errorMessage = "No active subscriptions found to restore."
                    showError = true
                }
            }
        }
    }
}

// MARK: - Pro Feature Card (Full Width)
struct ProFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .overlay(
            Rectangle()
                .fill(AppConstants.dividerColor(for: colorScheme))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let tier: SubscriptionTier
    let product: Product
    let isSelected: Bool
    let savingsPercentage: Int?
    let pricePerMonth: String?
    let onSelect: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Recommended Badge
                if tier == .proYearly, let savings = savingsPercentage, savings > 0 {
                    HStack {
                        Spacer()
                        Text("BEST VALUE • SAVE \(savings)%")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12, corners: [.topLeft, .topRight])
                        Spacer()
                    }
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tier.displayName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        if let pricePerMonth = pricePerMonth {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(pricePerMonth)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("/month")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                        }
                        
                        if tier == .proYearly {
                            Text("Billed \(product.displayPrice) annually")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        } else {
                            Text("Billed monthly")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.blue : AppConstants.borderColor(for: colorScheme),
                                lineWidth: 2
                            )
                            .frame(width: 28, height: 28)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .padding(.top, tier == .proYearly ? 8 : 20)
            }
            .background(
                ZStack {
                    AppConstants.cardBackgroundColor(for: colorScheme)
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    }
                }
            )
            .cornerRadius(20)
            .shadow(
                color: isSelected ? Color.blue.opacity(0.3) : AppConstants.shadowColor(for: colorScheme),
                radius: isSelected ? 12 : 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Feature Card
struct CompactFeatureCard: View {
    let icon: String
    let title: String
    let gradient: [Color]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
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
            
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}

