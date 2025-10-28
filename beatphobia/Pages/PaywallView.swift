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
                VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Upgrade to Pro")
                                .font(.system(size: 32, weight: .bold, design: .serif))
                                .multilineTextAlignment(.center)
                            
                            Text("Unlock advanced features for your journey. We only charge based on usage that requires storage or computation in the cloud.")
                                .font(.system(size: 17, design: .serif))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 8)
                        
                        // Pro Features - Full Width
                        VStack(spacing: 0) {
                            ProFeatureCard(
                                icon: "location.fill",
                                title: "Unlimited Location Tracking",
                                description: "Access your complete journey history. Free users limited to last 3 journeys.",
                                gradient: [.blue, .cyan]
                            )
                            
                            ProFeatureCard(
                                icon: "icloud.fill",
                                title: "Cloud Journal Backup",
                                description: "Securely sync your journal entries across all your devices.",
                                gradient: [.purple, .pink]
                            )
                            
                            ProFeatureCard(
                                icon: "chart.xyaxis.line",
                                title: "Detailed Metrics",
                                description: "Get insights into your panic scale trends, journal patterns, and location analytics.",
                                gradient: [.orange, .red]
                            )
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 20)
                        
                        // Pricing Cards
                        VStack(spacing: 12) {
                            Text("Choose Your Plan")
                                .font(.system(size: 20, weight: .semibold, design: .serif))
                                .padding(.top, 24)
                            
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
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Subscribe Button
                        Button(action: handlePurchase) {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Start Your Pro Journey")
                                        .font(.system(size: 18, weight: .semibold, design: .serif))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                        .disabled(isPurchasing || subscriptionManager.isLoading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Restore Purchases Button
                        Button(action: handleRestore) {
                            Text("Restore Purchases")
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(.blue)
                        }
                        .disabled(isPurchasing)
                        
                        // Terms and Privacy
                        VStack(spacing: 8) {
                            Text("Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period.")
                                .font(.system(size: 11, design: .serif))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 16) {
                                Button("Terms of Service") {
                                    if let url = URL(string: "https://stillstep.com/terms") {
                                        openURL(url)
                                    }
                                }
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(.blue)
                                
                                Button("Privacy Policy") {
                                    if let url = URL(string: "https://stillstep.com/privacy") {
                                        openURL(url)
                                    }
                                }
                                .font(.system(size: 12, design: .serif))
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 20)
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
                if tier == .proYearly {
                    HStack {
                        Spacer()
                        Text("BEST VALUE")
                            .font(.system(size: 11, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(tier.displayName)
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(.primary)
                            
                            if let savings = savingsPercentage {
                                Text("Save \(savings)%")
                                    .font(.system(size: 12, weight: .semibold, design: .serif))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.15))
                                    .cornerRadius(6)
                            }
                        }
                        
                        if let pricePerMonth = pricePerMonth {
                            Text("\(pricePerMonth)/month")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        
                        if tier == .proYearly {
                            Text("Billed annually at \(product.displayPrice)")
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        } else {
                            Text("Billed monthly")
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                }
                .padding(20)
            }
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.borderColor(for: colorScheme).opacity(0.4),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(16)
            .shadow(
                color: isSelected ? AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.2) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView()
        .environmentObject(SubscriptionManager())
}

