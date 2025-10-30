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
    
    var isFirstRun: Bool = false
    
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
                            
                            // First-run specific messaging
                            if isFirstRun {
                                VStack(spacing: 16) {
                                    Text("Welcome to Still Step")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                    
                                    VStack(spacing: 8) {
                                        Text("The majority of features are free and will continue to be free.")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .fixedSize(horizontal: false, vertical: true)
                                        
                                        Text("If you want to support this app and access features that incur real-world costs (like cloud storage and sync), you can upgrade to Pro.")
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 32)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    
                                    // Continue as Free button
                                    Button(action: {
                                        dismiss()
                                    }) {
                                        HStack(spacing: 8) {
                                            Text("Continue as Free")
                                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1.5)
                                        )
                                    }
                                    .padding(.horizontal, 32)
                                    .padding(.top, 8)
                                }
                            } else {
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
                        
                        // Free Trial Banner
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("7-Day Free Trial Included")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green.opacity(0.1), Color.mint.opacity(0.1)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.3), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        
                        // Pricing Cards
                        VStack(spacing: 16) {
                            Text("Choose Your Plan")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .padding(.top, 8)
                            
                            if let yearlyProduct = subscriptionManager.getProduct(for: .proYearly),
                               let monthlyProduct = subscriptionManager.getProduct(for: .proMonthly) {
                                
                                let _ = {
                                    print("💰 StoreKit Prices:")
                                    print("   - Yearly: \(yearlyProduct.displayPrice) (ID: \(yearlyProduct.id))")
                                    print("   - Monthly: \(monthlyProduct.displayPrice) (ID: \(monthlyProduct.id))")
                                    print("   - Price per month: \(subscriptionManager.getPricePerMonth(for: .proYearly) ?? "N/A")")
                                    print("   - Savings: \(subscriptionManager.getSavingsPercentage() ?? 0)%")
                                }()
                                
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
                            VStack(spacing: 4) {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    HStack(spacing: 8) {
                                        Text("Start 7-Day Free Trial")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.system(size: 16, weight: .bold))
                                    }
                                    
                                    Text("Then \(selectedTier.displayName)")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
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
                            Text("Start with a 7-day free trial. Cancel anytime during the trial at no charge. After the trial, subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
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
                // Recommended Badge (redesigned)
                if tier == .proYearly, let savings = savingsPercentage, savings > 0 {
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.yellow)
                            
                            Text("SAVE \(savings)%")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Color.green.opacity(0.4), radius: 6, y: 3)
                        
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                }
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(tier.displayName)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Show actual billed amount MOST prominently (Apple requirement)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(product.displayPrice)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            if tier == .proYearly {
                                Text("/year")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            } else {
                                Text("/month")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                        }
                        
                        // Show monthly equivalent SMALLER and subordinate
                        if tier == .proYearly, let pricePerMonth = pricePerMonth {
                            Text("Just \(pricePerMonth)/month")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
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

