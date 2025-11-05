import SwiftUI
import StoreKit
import Combine
import FirebaseAnalytics

// MARK: - Subscription Tiers
enum SubscriptionTier: String, CaseIterable {
    case free = "Free"
    case proMonthly = "Pro Monthly"
    case proYearly = "Pro Yearly"
    
    var productID: String {
        switch self {
        case .free:
            return ""
        case .proMonthly:
            return "pro_account_v1_monthly"
        case .proYearly:
            return "pro_account_v2_yearly"
        }
    }
    
    var displayName: String {
        self.rawValue
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "✅ All breathing exercises",
                "✅ 5-4-3-2-1 Grounding technique",
                "✅ Box breathing & 4-7-8 breathing",
                "✅ Progressive muscle relaxation",
                "✅ Safe space visualization",
                "✅ Body scan meditation",
                "✅ Positive affirmations",
                "✅ Color hunt game",
                "✅ Counting game",
                "✅ Focus techniques",
                "✅ Panic scale tracking",
                "✅ Local journal entries",
                "✅ Community access",
                "📍 Location tracking (last 3 journeys only)"
            ]
        case .proMonthly, .proYearly:
            return [
                "✨ Everything in Free",
                "📍 Unlimited location tracking history",
                "☁️ Cloud journal backup & sync",
                "🗺️ Cloud journey backup & sync",
                "📊 Detailed metrics & analytics",
                "📈 Journal entry insights over time",
                "📉 Panic scale trend analysis",
                "🗺️ Location pattern visualization",
                "🔐 Secure cloud storage"
            ]
        }
    }
    
    var isPro: Bool {
        switch self {
        case .free:
            return false
        case .proMonthly, .proYearly:
            return true
        }
    }
}

// MARK: - Subscription Status
struct SubscriptionStatus {
    var tier: SubscriptionTier
    var expirationDate: Date?
    var renewalDate: Date?
    var isInTrial: Bool
    var trialEndDate: Date?
    var isInGracePeriod: Bool
    var gracePeriodEndDate: Date?
    var willAutoRenew: Bool
    var transactionID: UInt64?
    
    var isActive: Bool {
        guard tier.isPro else { return false }
        
        if let expiration = expirationDate {
            return expiration > Date() || isInGracePeriod
        }
        return false
    }
    
    var daysUntilExpiration: Int? {
        guard let expiration = expirationDate else { return nil }
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: expiration)
        return days.day
    }
    
    var statusDescription: String {
        if !tier.isPro {
            return "Free Plan"
        }
        
        if isInTrial {
            if let trialEnd = trialEndDate {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: trialEnd).day ?? 0
                return "Free Trial (\(days) days remaining)"
            }
            return "Free Trial"
        }
        
        if isInGracePeriod {
            return "Grace Period (payment issue)"
        }
        
        if willAutoRenew {
            if let renewal = renewalDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Active (renews \(formatter.string(from: renewal)))"
            }
            return "Active (auto-renewing)"
        }
        
        if let expiration = expirationDate, expiration > Date() {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Active (expires \(formatter.string(from: expiration)))"
        }
        
        return "Expired"
    }
}

// MARK: - Purchase Error
enum PurchaseError: LocalizedError {
    case productNotFound
    case purchaseFailed(Error)
    case verificationFailed
    case userCancelled
    case pending
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The subscription product could not be found."
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .verificationFailed:
            return "Could not verify the purchase. Please contact support."
        case .userCancelled:
            return "Purchase was cancelled."
        case .pending:
            return "Purchase is pending approval."
        case .networkError:
            return "Network connection required to complete purchase."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}

// MARK: - Subscription Manager
final class SubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var products: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var lastError: PurchaseError?
    @Published var showPaywall: Bool = false
    
    // Convenience computed properties
    var isSubscribed: Bool { subscriptionStatus.isActive }
    var currentTier: SubscriptionTier { subscriptionStatus.tier }
    var isPro: Bool { subscriptionStatus.tier.isPro && subscriptionStatus.isActive }
    
    // MARK: - Private Properties
    private var productIDs: [String] {
        SubscriptionTier.allCases
            .filter { $0 != .free }
            .map { $0.productID }
    }
    
    private var transactionUpdates: Task<Void, Never>?
    private var updateTask: Task<Void, Never>?
    
    // Feature limits for free tier
    private let freeLocationTrackingLimit = 3 // Last 3 journeys only
    
    // MARK: - Initialization
    init() {
        // Initialize with free tier
        self.subscriptionStatus = SubscriptionStatus(
            tier: .free,
            expirationDate: nil,
            renewalDate: nil,
            isInTrial: false,
            trialEndDate: nil,
            isInGracePeriod: false,
            gracePeriodEndDate: nil,
            willAutoRenew: false,
            transactionID: nil
        )
        
        self.transactionUpdates = nil
        self.updateTask = nil
        
        // Start listening for transaction updates after initialization
        Task {
            await MainActor.run {
                self.transactionUpdates = self.listenForTransactionUpdates()
            }
        }
        
        // Initialize products and subscription status
        Task { @MainActor [weak self] in
            await self?.initialize()
        }
    }
    
    deinit {
        transactionUpdates?.cancel()
        updateTask?.cancel()
    }
    
    // MARK: - Initialization Methods
    @MainActor
    private func initialize() async {
        await fetchProducts()
        await checkActiveSubscription()
    }
    
    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await verificationResult in StoreKit.Transaction.updates {
                await self?.handleTransactionUpdate(verificationResult)
            }
        }
    }
    
    // MARK: - Product Management
    @MainActor
    func fetchProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            
            self.products = storeProducts.sorted { product1, product2 in
                // Sort yearly before monthly
                if product1.id.contains("yearly") { return true }
                if product2.id.contains("yearly") { return false }
                return product1.price < product2.price
            }
            lastError = nil
            
            #if DEBUG
            print("✅ Loaded \(storeProducts.count) subscription products")
            #endif
        } catch {
            print("❌ Failed to fetch products: \(error.localizedDescription)")
            lastError = .purchaseFailed(error)
            self.products = []
        }
    }
    
    func getProduct(for tier: SubscriptionTier) -> Product? {
        products.first { $0.id == tier.productID }
    }
    
    // MARK: - Purchase Management
    @MainActor
    func purchase(_ product: Product) async throws {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                await handleSuccessfulPurchase(verification)
                lastError = nil
                
                // Track purchase completed with Firebase Analytics
                Analytics.logEvent("purchase_completed", parameters: [
                    "product_id": product.id as NSObject,
                    "product_name": product.displayName as NSObject,
                    "price": NSDecimalNumber(decimal: product.price).doubleValue as NSObject,
                    "currency": (product.priceFormatStyle.locale.currencyCode ?? "USD") as NSObject
                ])
                
                // Set subscription tier as user property
                let tier: SubscriptionTier
                if product.id == SubscriptionTier.proYearly.productID {
                    tier = .proYearly
                } else if product.id == SubscriptionTier.proMonthly.productID {
                    tier = .proMonthly
                } else {
                    tier = .free
                }
                Analytics.setUserProperty(tier.rawValue, forName: "subscription_tier")
                
                // Post notification for analytics/tracking
                NotificationCenter.default.post(
                    name: .subscriptionPurchased,
                    object: nil,
                    userInfo: ["productID": product.id]
                )
                
                // Notify that sync should restart (for journal sync service)
                NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
                
            case .pending:
                lastError = .pending
                throw PurchaseError.pending
                
            case .userCancelled:
                lastError = .userCancelled
                throw PurchaseError.userCancelled
                
            @unknown default:
                lastError = .unknown
                throw PurchaseError.unknown
            }
        } catch {
            if let purchaseError = error as? PurchaseError {
                lastError = purchaseError
                throw purchaseError
            } else {
                let wrappedError = PurchaseError.purchaseFailed(error)
                lastError = wrappedError
                throw wrappedError
            }
        }
    }
    
    @MainActor
    func purchaseTier(_ tier: SubscriptionTier) async throws {
        guard let product = getProduct(for: tier) else {
            throw PurchaseError.productNotFound
        }
        try await purchase(product)
    }
    
    // MARK: - Restore & Sync
    @MainActor
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await AppStore.sync()
            await checkActiveSubscription()
            lastError = nil
            
            NotificationCenter.default.post(name: .subscriptionRestored, object: nil)
        } catch {
            print("Failed to restore purchases: \(error)")
            lastError = .purchaseFailed(error)
        }
    }
    
    // MARK: - Subscription Status Management
    @MainActor
    func checkActiveSubscription() async {
        var activeStatus = SubscriptionStatus(
            tier: .free,
            expirationDate: nil,
            renewalDate: nil,
            isInTrial: false,
            trialEndDate: nil,
            isInGracePeriod: false,
            gracePeriodEndDate: nil,
            willAutoRenew: false,
            transactionID: nil
        )
        
        var latestTransaction: StoreKit.Transaction?
        var latestExpirationDate: Date?
        
        for await verificationResult in StoreKit.Transaction.currentEntitlements {
            guard let transaction = verifyTransaction(verificationResult) else { continue }
            
            if productIDs.contains(transaction.productID) {
                // Check if this is the most recent transaction
                if let expiration = transaction.expirationDate {
                    if latestExpirationDate == nil || expiration > latestExpirationDate! {
                        latestTransaction = transaction
                        latestExpirationDate = expiration
                    }
                }
            }
        }
        
        // Update status based on latest transaction
        if let transaction = latestTransaction {
            activeStatus = buildSubscriptionStatus(from: transaction)
        }
        
        // Only notify if status actually changed
        let previousTier = self.subscriptionStatus.tier
        let previousIsActive = self.subscriptionStatus.isActive
        
        self.subscriptionStatus = activeStatus
        
        // Post notification if subscription status changed (e.g., loaded from StoreKit)
        if previousTier != activeStatus.tier || previousIsActive != activeStatus.isActive {
            NotificationCenter.default.post(name: .subscriptionStatusChanged, object: nil)
        }
    }
    
    private func buildSubscriptionStatus(from transaction: StoreKit.Transaction) -> SubscriptionStatus {
        let tier: SubscriptionTier
        if transaction.productID == SubscriptionTier.proYearly.productID {
            tier = .proYearly
        } else if transaction.productID == SubscriptionTier.proMonthly.productID {
            tier = .proMonthly
        } else {
            tier = .free
        }
        
        // Check if this is a trial by examining the offer type
        let isInTrial: Bool
        if #available(iOS 15.4, macOS 12.3, *) {
            isInTrial = transaction.offer?.type == .introductory
        } else {
            isInTrial = false
        }
        let willAutoRenew = transaction.revocationDate == nil
        
        // Check for grace period
        let isInGracePeriod: Bool
        let gracePeriodEndDate: Date?
        if let expiration = transaction.expirationDate, expiration < Date() {
            // Subscription expired, check if in grace period (typically 16 days)
            let gracePeriodDays = 16
            let potentialGraceEnd = Calendar.current.date(byAdding: .day, value: gracePeriodDays, to: expiration)!
            isInGracePeriod = Date() < potentialGraceEnd
            gracePeriodEndDate = isInGracePeriod ? potentialGraceEnd : nil
        } else {
            isInGracePeriod = false
            gracePeriodEndDate = nil
        }
        
        return SubscriptionStatus(
            tier: tier,
            expirationDate: transaction.expirationDate,
            renewalDate: willAutoRenew ? transaction.expirationDate : nil,
            isInTrial: isInTrial,
            trialEndDate: isInTrial ? transaction.expirationDate : nil,
            isInGracePeriod: isInGracePeriod,
            gracePeriodEndDate: gracePeriodEndDate,
            willAutoRenew: willAutoRenew,
            transactionID: transaction.id
        )
    }
    
    // MARK: - Transaction Handling
    @MainActor
    private func handleTransactionUpdate(_ verificationResult: VerificationResult<StoreKit.Transaction>) async {
        await handleSuccessfulPurchase(verificationResult)
        await checkActiveSubscription()
    }
    
    @MainActor
    private func handleSuccessfulPurchase<T>(_ verificationResult: VerificationResult<T>) async {
        guard let transaction = verifyTransaction(verificationResult) as? StoreKit.Transaction else { return }
        
        if productIDs.contains(transaction.productID) {
            // Update subscription status
            await checkActiveSubscription()
            
            // Finish the transaction
            await transaction.finish()
        }
    }
    
    private func verifyTransaction<T>(_ verificationResult: VerificationResult<T>) -> T? {
        switch verificationResult {
        case .verified(let safePayload):
            return safePayload
        case .unverified:
            print("⚠️ Transaction verification failed - possible jailbreak or tampered receipt")
            lastError = .verificationFailed
            return nil
        }
    }
    
    // MARK: - Feature Access Control
    func hasAccess(to feature: ProFeature) -> Bool {
        if isPro {
            return true
        }
        
        // Check if feature is available in free tier
        return feature.availableInFree
    }
    
    func requiresPro(for feature: ProFeature, showPaywallOnFailure: Bool = true) -> Bool {
        let needsPro = !hasAccess(to: feature)
        if needsPro && showPaywallOnFailure {
            showPaywall = true
        }
        return needsPro
    }
    
    // Location tracking limits
    func canAccessLocationHistory(journeyCount: Int) -> Bool {
        if isPro {
            return true
        }
        // Free users can only access last 3 journeys
        return journeyCount <= freeLocationTrackingLimit
    }
    
    func getAccessibleLocationHistoryCount() -> Int? {
        if isPro {
            return nil // nil means unlimited
        }
        return freeLocationTrackingLimit
    }
    
    // Cloud journal sync
    func canSyncJournalToCloud() -> Bool {
        return hasAccess(to: .cloudJournalSync)
    }
    
    // Cloud journey sync
    func canSyncJourneyToCloud() -> Bool {
        return hasAccess(to: .cloudJourneySync)
    }
    
    // Metrics access
    func canViewMetrics() -> Bool {
        return hasAccess(to: .metrics)
    }
    
    // MARK: - Pricing Helpers
    func getSavingsPercentage() -> Int? {
        guard let monthlyProduct = getProduct(for: .proMonthly),
              let yearlyProduct = getProduct(for: .proYearly) else {
            return nil
        }
        
        // Convert to Double for accurate calculation
        let monthlyYearlyCost = NSDecimalNumber(decimal: monthlyProduct.price * 12).doubleValue
        let yearlyCost = NSDecimalNumber(decimal: yearlyProduct.price).doubleValue
        
        guard monthlyYearlyCost > 0 else { return nil }
        
        let savings = monthlyYearlyCost - yearlyCost
        let percentage = (savings / monthlyYearlyCost) * 100
        
        return max(0, Int(percentage.rounded()))
    }
    
    func getFormattedPrice(for tier: SubscriptionTier) -> String? {
        guard let product = getProduct(for: tier) else { return nil }
        return product.displayPrice
    }
    
    func getPricePerMonth(for tier: SubscriptionTier) -> String? {
        guard let product = getProduct(for: tier) else { return nil }
        
        switch tier {
        case .free:
            return "Free"
        case .proMonthly:
            return product.displayPrice
        case .proYearly:
            let monthlyPrice = product.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceFormatStyle.locale
            return formatter.string(from: NSNumber(value: Double(truncating: monthlyPrice as NSNumber)))
        }
    }
    
    // MARK: - Analytics & Debugging
    func printDebugInfo() {
        print("=== Subscription Debug Info ===")
        print("Current Tier: \(subscriptionStatus.tier.displayName)")
        print("Is Subscribed: \(isSubscribed)")
        print("Is Pro: \(isPro)")
        print("Status: \(subscriptionStatus.statusDescription)")
        
        if let expiration = subscriptionStatus.expirationDate {
            print("Expires: \(expiration)")
        }
        
        if let days = subscriptionStatus.daysUntilExpiration {
            print("Days until expiration: \(days)")
        }
        
        print("Products loaded: \(products.count)")
        for product in products {
            print("  - \(product.displayName): \(product.displayPrice)")
        }
        
        if let error = lastError {
            if let description = error.errorDescription {
                print("Last Error: \(description)")
            } else {
                print("Last Error: Unknown")
            }
        }
        print("==============================")
    }
}

// MARK: - Pro Features
enum ProFeature {
    case unlimitedLocationTracking
    case cloudJournalSync
    case cloudJourneySync
    case metrics
    
    var availableInFree: Bool {
        return false // All pro features require subscription
    }
    
    var displayName: String {
        switch self {
        case .unlimitedLocationTracking:
            return "Unlimited Location Tracking"
        case .cloudJournalSync:
            return "Cloud Journal Backup & Sync"
        case .cloudJourneySync:
            return "Cloud Journey Backup & Sync"
        case .metrics:
            return "Detailed Metrics & Analytics"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedLocationTracking:
            return "Access unlimited location tracking history for all your journeys. Free users are limited to the last 3 journeys."
        case .cloudJournalSync:
            return "Securely save and sync your journal entries to the cloud. Access your journals from any device."
        case .cloudJourneySync:
            return "Securely save and sync your journeys to the cloud. Access your journey data from any device."
        case .metrics:
            return "Get detailed insights and analytics for your journal entries, panic scale tracking, and location patterns over time."
        }
    }
    
    var icon: String {
        switch self {
        case .unlimitedLocationTracking:
            return "location.fill"
        case .cloudJournalSync:
            return "icloud.fill"
        case .cloudJourneySync:
            return "map.fill"
        case .metrics:
            return "chart.xyaxis.line"
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let subscriptionPurchased = Notification.Name("subscriptionPurchased")
    static let subscriptionRestored = Notification.Name("subscriptionRestored")
    static let subscriptionExpired = Notification.Name("subscriptionExpired")
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
}