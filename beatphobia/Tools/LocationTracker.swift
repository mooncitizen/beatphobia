//
//  LocationTracker.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import MapKit
import CoreLocation
import Combine
import RealmSwift
import AVFoundation
import ActivityKit
import FirebaseAnalytics

// MARK: - Location Tracker Landing Page
struct LocationTrackerView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @EnvironmentObject var journeySyncService: JourneySyncService
    @ObservedResults(JourneyRealm.self) var allJourneys
    @ObservedResults(ExposurePlan.self) var allPlans
    @Binding var isTabBarVisible: Bool
    
    @State private var showTracking = false
    @State private var selectedJourneyId: String?
    @State private var showPaywall = false
    @State private var journeyToDelete: JourneyRealm?
    @State private var showDeleteConfirmation = false
    @State private var isEditMode = false
    @State private var selectedPlan: ExposurePlan?
    @State private var planToStart: ExposurePlan? // Separate state for plan to start tracking with
    @State private var newPlanToEdit: ExposurePlan? // New plan to edit in the plan editor
    @AppStorage("setting.miles") private var enableMiles = false
    
    var userJourneys: [JourneyRealm] {
        allJourneys.filter { !$0.isDeleted }.sorted(by: { $0.startTime > $1.startTime })
    }
    
    var userPlans: [ExposurePlan] {
        allPlans.filter { !$0.isDeleted }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()

            // Scrollable content (full screen)
            ScrollView {
                VStack(spacing: 24) {
                    // Stats section (flush left, no padding)
                    if !userJourneys.isEmpty {
                        statsSection
                            .padding(.top, 8)
                            .padding(.leading, -20) // Negative padding to counteract parent padding
                    }
                    
                    // Journey history
                    if !userJourneys.isEmpty {
                        journeyHistorySection
                    }
                    
                    // Bottom padding to account for floating button + tab bar
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
            .overlay(alignment: .bottom) {
                // Start Journey button (floating above content, above tab bar)
                VStack(spacing: 0) {
                    Button(action: {
                        showTracking = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 20))
                            
                            Text("Start Journey")
                                .font(.system(size: 18, weight: .bold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 100) // Padding to account for tab bar
                }
            }
            .id(allJourneys.count) // Force refresh when journeys count changes
        }
        .navigationTitle("Location Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !userJourneys.isEmpty {
                    Button(action: {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }) {
                        Text(isEditMode ? "Done" : "Edit")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: ExposurePlansListView(isTabBarVisible: $isTabBarVisible)) {
                    Text("Plans")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                }
            }
        }
        .fullScreenCover(isPresented: $showTracking) {
            LocationTrackingView(isTabBarVisible: $isTabBarVisible, onJourneyCompleted: { journeyId in
                selectedJourneyId = journeyId
                // Clear all to prevent plan editor from showing
                selectedPlan = nil
                newPlanToEdit = nil
                planToStart = nil
            }, initialPlan: planToStart ?? selectedPlan)
            .environmentObject(journeySyncService)
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedJourneyId != nil },
            set: { if !$0 { selectedJourneyId = nil } }
        )) {
            if let journeyId = selectedJourneyId,
               let realm = try? Realm(),
               let journey = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyId) {
                NavigationStack {
                    JourneyDetailView(journey: journey)
                        .environmentObject(journeySyncService)
                }
            }
        }
        .sheet(item: Binding(
            get: { showTracking ? nil : (newPlanToEdit ?? selectedPlan) },
            set: { 
                if newPlanToEdit != nil {
                    newPlanToEdit = $0
                } else {
                    selectedPlan = $0
                }
            }
        )) { plan in
            NavigationStack {
                PlanDetailView(plan: plan, isTabBarVisible: $isTabBarVisible, shouldAutoGenerate: false)
            }
        }
        .onAppear {
            // Refresh when view appears to ensure new journeys are shown
            // @ObservedResults should auto-update, but this helps ensure it happens
            let _ = allJourneys.count
        }
        .onChange(of: showTracking) { oldValue, newValue in
            // When tracking view is dismissed, ensure we refresh
            if oldValue == true && newValue == false {
                // Clear selectedPlan, newPlanToEdit, and planToStart when tracking view is dismissed to prevent plan editor from showing
                selectedPlan = nil
                newPlanToEdit = nil
                planToStart = nil
                // Small delay to allow Realm notifications to propagate
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Access allJourneys to trigger @ObservedResults update
                    let _ = allJourneys.count
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
                    .environmentObject(subscriptionManager)
            }
        }
        .alert("Delete Journey?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let journey = journeyToDelete {
                    deleteJourney(journey)
                }
            }
        } message: {
            Text("This journey will be permanently deleted from all your devices.")
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Stats")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    .padding(.leading, 20) // Add padding to title
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Cumulative Map Card (far left)
                    CumulativeMapCard(journeys: userJourneys)
                        .frame(width: 140, height: 140)
                    
                    LocationTrackerStatCard(
                        title: "Total Time",
                        value: formatTotalTime(),
                        subtitle: "All journeys",
                        icon: "clock.fill",
                        color: AppConstants.primaryColor
                    )
                    
                    LocationTrackerStatCard(
                        title: "Avg Pace",
                        value: calculateAveragePace(),
                        subtitle: enableMiles ? "min/mi" : "min/km",
                        icon: "gauge.high",
                        color: .orange
                    )
                    
                    LocationTrackerStatCard(
                        title: "Journeys",
                        value: "\(userJourneys.count)",
                        subtitle: "Total tracked",
                        icon: "map.fill",
                        color: .blue
                    )
                }
                .padding(.leading, 20) // Only left padding to align with content
                .padding(.trailing, 20) // Right padding for scroll
            }
        }
    }
    
    // MARK: - Plans List Section
    private var plansListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Plans")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
            }
            
            ForEach(userPlans) { plan in
                HStack(spacing: 12) {
                    Button(action: {
                        selectedPlan = plan
                    }) {
                        PlanRowView(plan: plan)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Quick start button
                    if !plan.targets.filter({ !$0.isDeleted }).isEmpty {
                        Button(action: {
                            // Start tracking directly with this plan
                            // Use separate state to avoid triggering the sheet
                            planToStart = plan
                            selectedPlan = nil // Clear to prevent sheet from showing
                            showTracking = true
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Plans View
    private var emptyPlansView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "map.fill")
                .font(.system(size: 64))
                .foregroundColor(AppConstants.primaryColor.opacity(0.6))
            
            Text("No plans yet")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            Text("Create your first exposure plan to get started")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            NavigationLink(destination: ExposurePlansListView(isTabBarVisible: $isTabBarVisible)) {
                Text("Create Plan")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
    }
    
    // MARK: - Journey History
    private var journeyHistorySection: some View {
        let realm = try! Realm()
        
        return VStack(spacing: 12) {
            HStack {
                Text("Journey History")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if !subscriptionManager.isPro && userJourneys.count > 5 {
                    Spacer()
                    
                    Text("Showing 5 of \(userJourneys.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(groupedJourneys.keys.sorted(by: >), id: \.self) { date in
                VStack(spacing: 8) {
                    // Date separator
                    HStack {
                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .textCase(.uppercase)
                        
                        Rectangle()
                            .fill(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.top, date == groupedJourneys.keys.sorted(by: >).first ? 0 : 12)
                    
                    // Journeys for this date
                    if let journeys = groupedJourneys[date] {
                        ForEach(journeys, id: \.id) { journey in
                            HStack(spacing: 12) {
                                NavigationLink(destination: JourneyDetailView(journey: journey)) {
                                    LocationJourneyCard(journey: journey, enableMiles: enableMiles, realm: realm)
                                }
                                .disabled(isEditMode)
                                
                                // Delete button (only shown in edit mode)
                                if isEditMode {
                                    Button(action: {
                                        journeyToDelete = journey
                                        showDeleteConfirmation = true
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.red)
                                            .frame(width: 44, height: 44)
                                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                                            .cornerRadius(12)
                                            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
                                    }
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
            }
            
            // Upgrade prompt for free users
            if !subscriptionManager.isPro && userJourneys.count > 5 {
                upgradePrompt
                    .padding(.top, 8)
            }
        }
    }
    
    // Upgrade prompt view
    private var upgradePrompt: some View {
        Button(action: {
            // Track free tier limit reached
            Analytics.logEvent("free_tier_limit_reached", parameters: [
                "feature": "journey_history" as NSObject,
                "limit": 5 as NSObject
            ])
            showPaywall = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                
                Text("Upgrade to Pro to view all journeys")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }
    
    // Group journeys by date
    private var groupedJourneys: [Date: [JourneyRealm]] {
        let calendar = Calendar.current
        let limit = subscriptionManager.isPro ? userJourneys.count : min(5, userJourneys.count)
        let grouped = Dictionary(grouping: userJourneys.prefix(limit)) { journey in
            // Extract year, month, day components from the date in local timezone
            let components = calendar.dateComponents([.year, .month, .day], from: journey.startTime)
            // Create a date at midnight of that day in the local timezone
            // This ensures consistent grouping regardless of how the date was stored
            if let startOfDay = calendar.date(from: components) {
                return startOfDay
            } else {
                // Fallback to startOfDay method
                return calendar.startOfDay(for: journey.startTime)
            }
        }
        return grouped
    }
    
    // Date formatter for section headers
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundColor(AppConstants.primaryColor.opacity(0.5))

            Text("Start Tracking")
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

            Text("Track your movements and emotions as you explore outside your safe space.")
                .font(.system(size: 15))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    private func formatTotalDistance() -> String {
        let total = userJourneys.reduce(0.0) { $0 + $1.distance }
        if enableMiles {
            let miles = total / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let km = total / 1000.0
            return String(format: "%.1f km", km)
        }
    }
    
    private func calculateAveragePace() -> String {
        guard !userJourneys.isEmpty else { return "--:--" }
        
        let validJourneys = userJourneys.filter { $0.duration > 0 && $0.distance > 0 }
        guard !validJourneys.isEmpty else { return "--:--" }
        
        let totalTime = validJourneys.reduce(0) { $0 + $1.duration }
        let totalDist = validJourneys.reduce(0.0) { $0 + $1.distance }
        
        let distance = enableMiles ? (totalDist / 1609.34) : (totalDist / 1000.0)
        let paceMinPerUnit = Double(totalTime) / 60.0 / distance
        let paceMin = Int(paceMinPerUnit)
        let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
        
        return String(format: "%d:%02d", paceMin, paceSec)
    }
    
    private func formatTotalTime() -> String {
        let total = userJourneys.reduce(0) { $0 + $1.duration }
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
    
    // MARK: - Create New Plan
    private func createNewPlan() {
        Task {
            await createNewPlanAsync()
        }
    }
    
    private func createNewPlanAsync() async {
        let realm = await MainActor.run {
            try? Realm()
        }
        guard let realm = realm else { return }
        
        // Create new plan in Realm
        let newPlan = ExposurePlan()
        newPlan.name = ""
        newPlan.createdAt = Date()
        newPlan.updatedAt = Date()
        newPlan.needsSync = true
        newPlan.isSynced = false
        
        let planToShow = await MainActor.run {
            var result: ExposurePlan?
            try! realm.write {
                realm.add(newPlan)
                // Get the managed version from Realm
                result = realm.object(ofType: ExposurePlan.self, forPrimaryKey: newPlan.id)
            }
            return result
        }
        
        // Now we can observe it (use the managed version from Realm)
        if let plan = planToShow {
            await MainActor.run {
                newPlanToEdit = plan
                selectedPlan = nil // Clear selectedPlan to ensure newPlanToEdit is used
            }
        }
    }
    
    // MARK: - Delete Journey
    private func deleteJourney(_ journey: JourneyRealm) {
        let realm = try! Realm()
        
        // Thaw the frozen object before modifying
        guard let liveJourney = journey.thaw() else {
            journeyToDelete = nil
            return
        }
        
        // Mark JourneyRealm as deleted
        realm.deleteJourneyData(liveJourney)
        
        // Also mark the corresponding Journey metadata object as deleted
        if let journeyId = UUID(uuidString: liveJourney.id),
           let journeyMetadata = realm.object(ofType: Journey.self, forPrimaryKey: journeyId) {
            try! realm.write {
                journeyMetadata.isDeleted = true
                journeyMetadata.updatedAt = Date()
                journeyMetadata.needsSync = true
                journeyMetadata.isSynced = false
            }
        }
        
        // Trigger immediate sync to push deletion to Supabase
        Task {
            try? await journeySyncService.syncAll()
        }
        
        journeyToDelete = nil
        
        // Exit edit mode if no journeys left
        if userJourneys.count <= 1 {
            withAnimation {
                isEditMode = false
            }
        }
    }
}

// MARK: - Location Journey Card
struct LocationJourneyCard: View {
    @Environment(\.colorScheme) var colorScheme
    let journey: JourneyRealm
    let enableMiles: Bool
    let realm: Realm
    
    // Get the linked plan if this journey is part of a plan
    private var linkedPlan: ExposurePlan? {
        guard let journeyId = UUID(uuidString: journey.id),
              let journeyMeta = realm.object(ofType: Journey.self, forPrimaryKey: journeyId),
              let planId = journeyMeta.linkedPlanId else {
            return nil
        }
        return realm.object(ofType: ExposurePlan.self, forPrimaryKey: planId)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(journey.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(journey.startTime.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    // Show plan name if this journey is part of a plan - make it more prominent
                    if let plan = linkedPlan {
                        HStack(spacing: 6) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.primaryColor)
                            Text(plan.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppConstants.primaryColor.opacity(0.15))
                        .cornerRadius(8)
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Distance badge
                HStack(spacing: 4) {
                    Text(formatDistance(journey.distance))
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.monospaced)

                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(8)
            }
            
            // Key details
            HStack(spacing: 16) {
                if journey.duration > 0 {
                    DetailPill(icon: "clock.fill", text: formatDuration(journey.duration))
                }
                
                if journey.checkpoints.count > 0 {
                    DetailPill(icon: "heart.fill", text: "\(journey.checkpoints.count)")
                }
                
                if journey.duration > 0 && journey.distance > 0 {
                    DetailPill(icon: "gauge.high", text: calculatePace())
                }
                
                // Show plan target count if this journey is part of a plan
                if let plan = linkedPlan {
                    let targetCount = plan.targets.filter { !$0.isDeleted }.count
                    if targetCount > 0 {
                        DetailPill(icon: "mappin.circle.fill", text: "\(targetCount) targets")
                    }
                }
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if enableMiles {
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        } else {
            let km = meters / 1000.0
            return String(format: "%.2f km", km)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes > 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return String(format: "%dh %dm", hours, mins)
        }
        return String(format: "%dm", minutes)
    }
    
    private func calculatePace() -> String {
        guard journey.duration > 0 && journey.distance > 0 else { return "--:--" }
        
        let distance = enableMiles ? (journey.distance / 1609.34) : (journey.distance / 1000.0)
        let paceMinPerUnit = Double(journey.duration) / 60.0 / distance
        let paceMin = Int(paceMinPerUnit)
        let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
        return String(format: "%d:%02d", paceMin, paceSec)
    }
}

// MARK: - Location Tracker Stat Card Component
struct LocationTrackerStatCard: View {
    @Environment(\.colorScheme) var colorScheme
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Spacer()
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
        }
        .padding(16)
        .frame(width: 140)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
    }
}

// MARK: - Active Tracking View (renamed from LocationTrackerView)
struct LocationTrackingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var journeySyncService: JourneySyncService
    @StateObject private var locationManager = LocationTrackingManager()
    @ObservedResults(ExposurePlan.self) var allPlans
    @State private var showMap = false // Hide map by default
    @Binding var isTabBarVisible: Bool
    var onJourneyCompleted: ((String) -> Void)?
    var initialPlan: ExposurePlan? = nil
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var showEndJourneyAlert = false
    @State private var showJourneyResults = false
    @State private var completedJourneyId: String?
    @State private var showCountdown = false
    @State private var countdown = 3
    @State private var isPaused = false
    @State private var countdownTimer: Timer?
    @State private var recenterToken = UUID()
    @State private var selectedPlan: ExposurePlan?
    
    private let countdownHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var userPlans: [ExposurePlan] {
        allPlans.filter { !$0.isDeleted }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    var body: some View {
        ZStack {
            // Background color
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            // Map view (only when enabled)
            if showMap {
                MapView(locationManager: locationManager, recenterToken: recenterToken)
                    .ignoresSafeArea()
            }
            
            // Overlay UI
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Plan Overlay (when plan is active)
                if let plan = locationManager.activePlan, locationManager.isTracking {
                    planOverlayView(plan: plan)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                }
                
                // Info and plans list (when not tracking)
                if !locationManager.isTracking {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Tracking info
                            trackingInfoView
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            // Plans list
                            if !userPlans.isEmpty {
                                plansListSection
                                    .padding(.horizontal, 20)
                            } else {
                                emptyPlansView
                                    .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
                
                // Stats view (when not showing map)
                if !showMap && locationManager.isTracking {
                    Spacer()
                    statsView
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                // Spacer when in map view to push controls down
                if showMap && locationManager.isTracking {
                    Spacer()
                }
                
                // Feeling selector (when tracking)
                if locationManager.isTracking {
                    feelingSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                }
                
                // Bottom controls
                controlsView
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .alert("End Journey?", isPresented: $showEndJourneyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("End Journey", role: .destructive) {
                // Save first, THEN set completedJourneyId to trigger dismissal
                locationManager.stopTracking()
                // stopTracking() will set completedJourneyId internally
                if let journeyId = locationManager.currentJourneyId {
                    completedJourneyId = journeyId.uuidString
                }
            }
        } message: {
            Text("Are you sure you want to end this tracking session?")
        }
        .onChange(of: completedJourneyId) { oldValue, newValue in
            if let journeyId = newValue {
                // Verify the journey exists in Realm before dismissing
                if let realm = try? Realm() {
                    let savedJourney = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyId)
                    if savedJourney != nil {
                        // Call the completion handler if provided
                        onJourneyCompleted?(journeyId)
                        
                        // Clear selectedPlan to prevent plan editor from showing
                        selectedPlan = nil
                        
                        // Delay to ensure Realm notification propagates and view updates
                        // Increased delay to allow updateSafeAreaPoints to complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.dismiss()
                        }
                        
                        // Sync from local version in background
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                            await journeySyncService.syncAll()
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedPlan) { plan in
            NavigationStack {
                PlanDetailView(plan: plan, isTabBarVisible: $isTabBarVisible, shouldAutoGenerate: false)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            locationManager.useMiles = enableMiles
            // If initialPlan is provided, set it as the active plan and start countdown immediately
            // Thaw the plan if it's frozen (from Realm)
            if let plan = initialPlan {
                let thawedPlan: ExposurePlan
                if plan.isFrozen {
                    if let realm = try? Realm() {
                        thawedPlan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: plan.id) ?? plan
                    } else {
                        thawedPlan = plan
                    }
                } else {
                    thawedPlan = plan
                }
                locationManager.activePlan = thawedPlan
                print("📍 Set active plan: \(thawedPlan.name) with \(thawedPlan.targets.filter { !$0.isDeleted }.count) targets")
                
                // If plan is set, start countdown immediately to begin tracking
                if !thawedPlan.targets.filter({ !$0.isDeleted }).isEmpty {
                    countdown = 3
                    showCountdown = true
                    startCountdown()
                }
            }
            // Hide tab bar when view appears
            withAnimation(.easeInOut(duration: 0.2)) {
                isTabBarVisible = false
            }
        }
        .onChange(of: enableMiles) { oldValue, newValue in
            locationManager.useMiles = newValue
            locationManager.updateDistanceDisplay()
        }
        .onDisappear {
            // Only stop tracking if not actively tracking
            // This ensures tracking continues even when phone sleeps
            if !locationManager.isTracking {
                // Show tab bar when view disappears
                withAnimation(.easeInOut(duration: 0.2)) {
                    isTabBarVisible = true
                }
            }
        }
        .interactiveDismissDisabled(locationManager.isTracking) // Prevent swipe-to-dismiss while tracking
        .overlay {
            if showCountdown {
                countdownOverlay
            }
        }
    }
    
    // MARK: - Countdown Overlay
    private var countdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Countdown number
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Progress circle
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 3.0)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)
                }
                
                // Button controls
                HStack(spacing: 24) {
                    // Cancel button
                    Button(action: {
                        cancelCountdown()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.9))
                        .cornerRadius(12)
                    }
                    
                    // Pause/Resume button
                    Button(action: {
                        togglePause()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text(isPaused ? "Resume" : "Pause")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    // MARK: - Countdown Functions
    private func startCountdown() {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if !isPaused {
                if countdown > 1 {
                    // Play beep for numbers 3, 2, 1
                    playCountdownBeep()
                    countdown -= 1
                } else if countdown == 1 {
                    // Play beep for 1, then stop
                    playCountdownBeep()
                    countdown -= 1
                } else {
                    // countdown reached 0, start tracking
                    timer.invalidate()
                    countdownTimer = nil
                    showCountdown = false
                    locationManager.startTracking(with: initialPlan)
                }
            }
        }
    }
    
    private func playCountdownBeep() {
        // Prepare haptic for immediate response
        countdownHaptic.prepare()
        
        // Trigger haptic feedback (sound removed)
        countdownHaptic.impactOccurred(intensity: 0.9)
    }
    
    private func cancelCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        showCountdown = false
        countdown = 3
        isPaused = false
    }
    
    private func togglePause() {
        isPaused.toggle()
    }
    
    // MARK: - Plan Overlay View
    
    @State private var showSkipWaitAlert = false
    
    private func planOverlayView(plan: ExposurePlan) -> some View {
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        let currentTarget = locationManager.currentTargetIndex < targets.count ? targets[locationManager.currentTargetIndex] : nil
        let nextTarget = locationManager.currentTargetIndex + 1 < targets.count ? targets[locationManager.currentTargetIndex + 1] : nil
        
        return VStack(spacing: 12) {
            // Current Target Status
            if let target = currentTarget {
                if locationManager.isWaitingAtTarget {
                    // Waiting at target
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            Text("Reached: \(target.name)! Great job.")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Spacer()
                        }
                        
                        Text("Now, let's wait.")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        // Wait Timer
                        HStack(spacing: 12) {
                            Text("Wait Timer:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Text(formatWaitTimeShort(Int(locationManager.waitTimerRemaining)))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(AppConstants.primaryColor)
                            
                            Spacer()
                            
                            Button(action: {
                                showSkipWaitAlert = true
                            }) {
                                Text("Skip")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Prompt for tools
                        HStack(spacing: 8) {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(AppConstants.primaryColor)
                            
                            Text("Feeling anxious? Use a calming tool now.")
                                .font(.system(size: 13))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        .padding(8)
                        .background(AppConstants.primaryColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    // Heading to target
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current Target:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            
                            Spacer()
                        }
                        
                        HStack {
                            Text(target.name)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Spacer()
                            
                            // Calculate distance to target
                            if let lastLocation = locationManager.trackingPoints.last {
                                let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
                                let distance = lastLocation.distance(from: targetLocation)
                                let distanceString = enableMiles
                                    ? String(format: "%.2f mi", distance / 1609.34)
                                    : String(format: "%.2f km", distance / 1000.0)
                                
                                Text("(\(distanceString) ahead)")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                        }
                        
                    }
                    
                    // Next Target (smaller, underneath current target)
                    if let next = nextTarget, !locationManager.isWaitingAtTarget {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.primaryColor)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Next Target")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                
                                Text(next.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Calculate distance to next target
                            if let lastLocation = locationManager.trackingPoints.last {
                                let nextTargetLocation = CLLocation(latitude: next.latitude, longitude: next.longitude)
                                let distance = lastLocation.distance(from: nextTargetLocation)
                                let distanceString = enableMiles
                                    ? String(format: "%.2f mi", distance / 1609.34)
                                    : String(format: "%.2f km", distance / 1000.0)
                                
                                Text(distanceString)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppConstants.primaryColor)
                            }
                        }
                        .padding(10)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme).opacity(0.7))
                        .cornerRadius(10)
                    }
                }
            }
            
            // Plan Completed
            if locationManager.planCompleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Plan Complete!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Congratulations! You've completed all targets.")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
        .alert("Skip Wait Timer?", isPresented: $showSkipWaitAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                locationManager.skipWaitTimer()
            }
        } message: {
            Text("Are you sure you want to skip the wait timer? This will advance to the next target.")
        }
    }
    
    // MARK: - Info View
    private var infoView: some View {
        VStack(spacing: 20) {
            // Main title and description
            VStack(spacing: 12) {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 50, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
                
                Text("Tracker")
                    .font(.system(size: 26, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text("Track your movements and emotions")
                    .font(.system(size: 15))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 4)
            
            // Features cards
            VStack(spacing: 10) {
                featureCard(
                    icon: "location.fill",
                    title: "Real-time Tracking",
                    description: "See your path on an interactive map as you move"
                )
                
                featureCard(
                    icon: "heart.text.square.fill",
                    title: "Emotion Checkpoints",
                    description: "Log how you're feeling at different points"
                )
                
                featureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Track Your Progress",
                    description: "View distance, time, and pace statistics"
                )
                
                featureCard(
                    icon: "map.fill",
                    title: "Toggle View",
                    description: "Switch between map and stats using the button in the top right"
                )
            }
            
            // Privacy note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.green)
                
                Text("Your location data is stored securely on your device")
                    .font(.system(size: 12))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            .padding(.bottom, 8)
        }
    }
    
    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(description)
                    .font(.system(size: 12))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Only show close button when NOT tracking
            if !locationManager.isTracking {
                Button(action: {
                    if locationManager.hapticsEnabled {
                        locationManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                    // Track journey cancelled
                    Analytics.logEvent("journey_cancelled", parameters: nil)
                    dismiss()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
            
            Spacer()
            
            // Right-side controls - only show when tracking
            if locationManager.isTracking {
                HStack(spacing: 10) {
                    // Recenter button (only visible in map mode)
                    if showMap {
                        Button(action: {
                            if locationManager.hapticsEnabled {
                                locationManager.lightHaptic.impactOccurred(intensity: 0.5)
                            }
                            recenterToken = UUID()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                                
                                Image(systemName: "location.viewfinder")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppConstants.primaryColor)
                            }
                        }
                    }
                    
                    // View toggle button
                    Button(action: {
                        if locationManager.hapticsEnabled {
                            locationManager.lightHaptic.impactOccurred(intensity: 0.5)
                        }
                        withAnimation(.spring(response: 0.3)) {
                            showMap.toggle()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, y: 3)
                            
                            Image(systemName: showMap ? "chart.bar.fill" : "map.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        VStack(spacing: 16) {
            // Next Target (if plan is active)
            if let plan = locationManager.activePlan {
                nextTargetView(plan: plan)
            }
            
            // Time and Distance Row
            HStack(spacing: 12) {
                statCard(
                    title: "Time",
                    value: locationManager.trackingDuration,
                    icon: "clock.fill",
                    color: AppConstants.primaryColor
                )
                
                statCard(
                    title: "Distance",
                    value: locationManager.totalDistance,
                    icon: "figure.walk",
                    color: .green
                )
            }
            
            // Pace and Emotions Row
            HStack(spacing: 12) {
                statCard(
                    title: enableMiles ? "Pace (min/mi)" : "Pace (min/km)",
                    value: locationManager.averagePace,
                    icon: "gauge.high",
                    color: .orange
                )
                
                statCard(
                    title: "Checkpoints",
                    value: "\(locationManager.feelingCheckpoints.count)",
                    icon: "heart.fill",
                    color: .pink
                )
            }
            
            // Recent emotions
            if !locationManager.feelingCheckpoints.isEmpty {
                recentEmotionsView
            }
        }
    }
    
    // MARK: - Next Target View
    private func nextTargetView(plan: ExposurePlan) -> some View {
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        let currentTarget = locationManager.currentTargetIndex < targets.count ? targets[locationManager.currentTargetIndex] : nil
        let nextTarget = locationManager.currentTargetIndex + 1 < targets.count ? targets[locationManager.currentTargetIndex + 1] : nil
        
        // Show current target if waiting, otherwise show next target
        let targetToShow = locationManager.isWaitingAtTarget ? currentTarget : (nextTarget ?? currentTarget)
        
        guard let target = targetToShow else { return AnyView(EmptyView()) }
        
        // Calculate distance to target
        var distanceString = ""
        if let lastLocation = locationManager.trackingPoints.last {
            let targetLocation = CLLocation(latitude: target.latitude, longitude: target.longitude)
            let distance = lastLocation.distance(from: targetLocation)
            
            if enableMiles {
                if distance < 160.934 { // Less than 0.1 miles
                    let feet = distance * 3.28084
                    distanceString = String(format: "%.0f ft", feet)
                } else {
                    let miles = distance / 1609.34
                    distanceString = String(format: "%.2f mi", miles)
                }
            } else {
                if distance < 100 {
                    distanceString = String(format: "%.0f m", distance)
                } else {
                    let km = distance / 1000.0
                    distanceString = String(format: "%.2f km", km)
                }
            }
        }
        
        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: locationManager.isWaitingAtTarget ? "checkmark.circle.fill" : "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(locationManager.isWaitingAtTarget ? .green : AppConstants.primaryColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(locationManager.isWaitingAtTarget ? "Current Target" : "Next Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        Text(target.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    if !distanceString.isEmpty && !locationManager.isWaitingAtTarget {
                        Text(distanceString)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
            .padding(16)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
        )
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
    }
    
    private var recentEmotionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Emotions")
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            
            HStack(spacing: 8) {
                ForEach(locationManager.feelingCheckpoints.suffix(5).reversed(), id: \.id) { checkpoint in
                    emotionBadge(checkpoint: checkpoint)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
    }
    
    private func emotionBadge(checkpoint: FeelingCheckpoint) -> some View {
        VStack(spacing: 4) {
            Image(systemName: checkpoint.feeling.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(checkpoint.feeling.color)
                .frame(width: 44, height: 44)
                .background(checkpoint.feeling.color.opacity(0.15))
                .cornerRadius(12)

            Text(checkpoint.timestamp.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
        }
    }
    
    // MARK: - Feeling Selector
    private var feelingSelector: some View {
        VStack(spacing: showMap ? 8 : 12) {
            Text("How are you feeling?")
                .font(.system(size: showMap ? 12 : 14, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.3), radius: 8, y: 3)
            
            HStack(spacing: showMap ? 8 : 12) {
                ForEach(FeelingLevel.allCases, id: \.self) { feeling in
                    feelingButton(feeling: feeling)
                }
            }
        }
    }
    
    private func feelingButton(feeling: FeelingLevel) -> some View {
        Button(action: {
            locationManager.recordFeeling(feeling)
        }) {
            if showMap {
                // Compact version for map view
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(feeling.color.opacity(0.9))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: feeling.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: locationManager.currentFeeling == feeling ? 3 : 0)
                    )
                }
            } else {
                // Full version for stats view
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(feeling.color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: feeling.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(feeling.color)
                    }
                    
                    Text(feeling.title)
                        .font(.system(size: 11, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    locationManager.currentFeeling == feeling ?
                    feeling.color.opacity(0.25) : AppConstants.cardBackgroundColor(for: colorScheme)
                )
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(feeling.color, lineWidth: locationManager.currentFeeling == feeling ? 3 : 0)
                )
            }
        }
    }
    
    // MARK: - Tracking Info View
    private var trackingInfoView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("Track Your Journey")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
            }
            
            Text("Track your movements and emotions as you explore outside your safe space. Select a plan below to follow a guided exposure journey, or start a free journey to track your path.")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
    }
    
    // MARK: - Plans List Section (for tracking view)
    private var plansListSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("My Plans")
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
            }
            
            ForEach(userPlans) { plan in
                HStack(spacing: 12) {
                    Button(action: {
                        selectedPlan = plan
                    }) {
                        PlanRowView(plan: plan)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Quick start button
                    if !plan.targets.filter({ !$0.isDeleted }).isEmpty {
                        Button(action: {
                            locationManager.activePlan = plan
                            countdown = 3
                            showCountdown = true
                            startCountdown()
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppConstants.primaryColor)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty Plans View (for tracking view)
    private var emptyPlansView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundColor(AppConstants.primaryColor.opacity(0.6))
            
            Text("No plans yet")
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            Text("Create your first exposure plan to get started")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ExposurePlansListView(isTabBarVisible: $isTabBarVisible)) {
                Text("Create Plan")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 12) {
            if !locationManager.isTracking {
                // Start tracking button - if plan is set, start immediately, otherwise show button
                if let plan = locationManager.activePlan, !plan.targets.filter({ !$0.isDeleted }).isEmpty {
                    // Plan is set, start countdown immediately
                    EmptyView()
                        .onAppear {
                            countdown = 3
                            showCountdown = true
                            startCountdown()
                        }
                } else {
                    // No plan, show start button
                    Button(action: {
                        countdown = 3
                        showCountdown = true
                        startCountdown()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text("Start Journey")
                                .font(.system(size: 18, weight: .semibold))
                                .fontDesign(.serif)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: Color.green.opacity(0.3), radius: 10, y: 5)
                    }
                }
            } else {
                // Stop tracking button
                Button(action: {
                    showEndJourneyAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: showMap ? 16 : 20, weight: .semibold))
                        
                        Text("End Journey")
                            .font(.system(size: showMap ? 15 : 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: showMap ? 44 : 56)
                    .background(
                        LinearGradient(
                            colors: [Color.red.opacity(showMap ? 0.85 : 1.0), Color.red.opacity(showMap ? 0.7 : 0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(showMap ? 22 : 28)
                    .shadow(color: Color.red.opacity(showMap ? 0.4 : 0.3), radius: showMap ? 6 : 10, y: showMap ? 3 : 5)
                }
            }
        }
    }
}

// MARK: - Map View
struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationTrackingManager
    var recenterToken: UUID
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update polyline only if tracking
        if locationManager.isTracking {
            // Only update if we have new points
            if locationManager.trackingPoints.count > 1 {
                let coordinates = locationManager.trackingPoints.map { $0.coordinate }
                
                // Check if we need to update the polyline
                let existingPolylines = mapView.overlays.compactMap { $0 as? MKPolyline }
                let needsUpdate = existingPolylines.isEmpty || existingPolylines.first?.pointCount != coordinates.count
                
                if needsUpdate {
                    // Remove only tracking polylines, keep route polylines
                    let trackingPolylines = existingPolylines.filter { polyline in
                        // Check if this is a tracking polyline (not a route polyline)
                        // Route polylines will have a different identifier or we can track them separately
                        return true // For now, remove all and re-add
                    }
                    mapView.removeOverlays(trackingPolylines)
                    
                    // Add new polyline for tracking path
                    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
                    mapView.addOverlay(polyline)
                }
            }
            
            // Update plan target annotations and route (only when plan or target index changes)
            if let plan = locationManager.activePlan {
                let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
                let currentTargetIndex = locationManager.currentTargetIndex
                let planId = plan.id
                
                // Check if plan or target index has changed
                let planChanged = context.coordinator.lastPlanId != planId
                let targetIndexChanged = context.coordinator.lastTargetIndex != currentTargetIndex
                
                // Only update annotations if plan changed or target index changed
                if planChanged || !context.coordinator.planAnnotationsAdded {
                    print("🗺️ Updating map with plan: \(plan.name), \(targets.count) targets, current index: \(currentTargetIndex)")
                    
                    // Remove old target annotations
                    let existingTargetAnnotations = mapView.annotations.compactMap { $0 as? PlanTargetAnnotation }
                    mapView.removeAnnotations(existingTargetAnnotations)
                    
                    // Add target annotations
                    for (index, target) in targets.enumerated() {
                        let annotation = PlanTargetAnnotation(
                            target: target,
                            index: index,
                            isCurrent: index == currentTargetIndex,
                            isCompleted: index < currentTargetIndex
                        )
                        mapView.addAnnotation(annotation)
                        print("📍 Added target annotation: \(target.name) at \(target.latitude), \(target.longitude)")
                    }
                    
                    context.coordinator.planAnnotationsAdded = true
                    context.coordinator.lastPlanId = planId
                } else if targetIndexChanged {
                    // Only update annotation states if target index changed
                    let existingTargetAnnotations = mapView.annotations.compactMap { $0 as? PlanTargetAnnotation }
                    for annotation in existingTargetAnnotations {
                        annotation.isCurrent = (annotation.index == currentTargetIndex)
                        annotation.isCompleted = (annotation.index < currentTargetIndex)
                    }
                    // Force annotation view refresh by removing and re-adding
                    mapView.removeAnnotations(existingTargetAnnotations)
                    mapView.addAnnotations(existingTargetAnnotations)
                }
                
                // Update route to current target (only if target index changed or route doesn't exist)
                if currentTargetIndex < targets.count,
                   let lastLocation = locationManager.trackingPoints.last {
                    let currentTarget = targets[currentTargetIndex]
                    let targetCoordinate = CLLocationCoordinate2D(latitude: currentTarget.latitude, longitude: currentTarget.longitude)
                    
                    // Only update route if target changed or route doesn't exist
                    let routeNeedsUpdate = targetIndexChanged ||
                        context.coordinator.lastRouteTo == nil ||
                        (context.coordinator.lastRouteTo?.latitude != targetCoordinate.latitude ||
                         context.coordinator.lastRouteTo?.longitude != targetCoordinate.longitude)
                    
                    if routeNeedsUpdate && !locationManager.isWaitingAtTarget {
                        print("🗺️ Updating route to target \(currentTargetIndex): \(currentTarget.name)")
                        
                        // Update route using coordinator
                        context.coordinator.updateRoute(
                            from: lastLocation.coordinate,
                            to: targetCoordinate,
                            mapView: mapView
                        )
                        
                        context.coordinator.lastRouteFrom = lastLocation.coordinate
                        context.coordinator.lastRouteTo = targetCoordinate
                    }
                } else {
                    // Remove route if waiting at target or no current target
                    if let routePoly = context.coordinator.routePolyline {
                        mapView.removeOverlay(routePoly)
                        context.coordinator.routePolyline = nil
                        context.coordinator.lastRouteTo = nil
                    }
                }
                
                // Update last target index
                context.coordinator.lastTargetIndex = currentTargetIndex
            } else {
                // Plan removed - clean up
                if context.coordinator.planAnnotationsAdded {
                    let existingTargetAnnotations = mapView.annotations.compactMap { $0 as? PlanTargetAnnotation }
                    mapView.removeAnnotations(existingTargetAnnotations)
                    context.coordinator.planAnnotationsAdded = false
                    context.coordinator.lastPlanId = nil
                    context.coordinator.lastTargetIndex = -1
                }
                
                // Remove route if no plan
                if let routePoly = context.coordinator.routePolyline {
                    mapView.removeOverlay(routePoly)
                    context.coordinator.routePolyline = nil
                    context.coordinator.lastRouteTo = nil
                }
            }
            
            // Update feeling checkpoint annotations (only if count changed)
            let existingFeelingAnnotations = mapView.annotations.compactMap { $0 as? FeelingAnnotation }
            if existingFeelingAnnotations.count != locationManager.feelingCheckpoints.count {
                // Remove old feeling annotations
                mapView.removeAnnotations(existingFeelingAnnotations)
                
                // Add new feeling annotations
                for checkpoint in locationManager.feelingCheckpoints {
                    let annotation = FeelingAnnotation(checkpoint: checkpoint)
                    mapView.addAnnotation(annotation)
                }
            }
            
            // Update hesitation annotations (only if count changed)
            let existingHesitationAnnotations = mapView.annotations.compactMap { $0 as? HesitationAnnotation }
            if existingHesitationAnnotations.count != locationManager.hesitationPoints.count {
                // Remove old hesitation annotations
                mapView.removeAnnotations(existingHesitationAnnotations)
                
                // Add new hesitation annotations
                for hesitation in locationManager.hesitationPoints {
                    let annotation = HesitationAnnotation(hesitationPoint: hesitation)
                    mapView.addAnnotation(annotation)
                }
            }
        }

        // Recenter ONLY when token changes
        if context.coordinator.lastRecenterToken != recenterToken, let _ = locationManager.trackingPoints.last {
            context.coordinator.lastRecenterToken = recenterToken
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var lastRecenterToken: UUID?
        var routePolyline: MKPolyline?
        
        // Track plan state to avoid unnecessary updates
        var lastPlanId: UUID?
        var lastTargetIndex: Int = -1
        var lastRouteFrom: CLLocationCoordinate2D?
        var lastRouteTo: CLLocationCoordinate2D?
        var planAnnotationsAdded: Bool = false
        
        func updateRoute(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, mapView: MKMapView) {
            // Remove old route polyline
            if let oldRoute = routePolyline {
                mapView.removeOverlay(oldRoute)
            }
            
            // Request directions
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
            request.transportType = .walking
            
            let directions = MKDirections(request: request)
            directions.calculate { [weak self] response, error in
                guard let self = self, let route = response?.routes.first else { return }
                
                DispatchQueue.main.async {
                    self.routePolyline = route.polyline
                    mapView.addOverlay(route.polyline)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                // Check if this is the route polyline (to target) or tracking path
                if let routePoly = routePolyline, routePoly === polyline {
                    // Route to target - mustard yellow
                    renderer.strokeColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Mustard yellow
                    renderer.lineWidth = 5
                    renderer.lineDashPattern = [5, 5] // Dashed line for route
                } else {
                    // Tracking path - regular yellow
                    renderer.strokeColor = UIColor.systemYellow
                    renderer.lineWidth = 4
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            // Handle hesitation annotations
            if let hesitationAnnotation = annotation as? HesitationAnnotation {
                let identifier = "HesitationAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create red box image (30x30 point square)
                let boxSize: CGFloat = 30
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: boxSize, height: boxSize))
                let boxImage = renderer.image { context in
                    let rect = CGRect(x: 0, y: 0, width: boxSize, height: boxSize)
                    
                    // Red fill
                    UIColor.systemRed.withAlphaComponent(0.3).setFill()
                    UIBezierPath(rect: rect).fill()
                    
                    // Red dashed border
                    UIColor.systemRed.setStroke()
                    let border = UIBezierPath(rect: rect)
                    border.lineWidth = 2
                    border.setLineDash([4, 4], count: 2, phase: 0)
                    border.stroke()
                }
                
                annotationView?.image = boxImage
                annotationView?.centerOffset = CGPoint(x: 0, y: 0)
                return annotationView
            }
            
            // Handle plan target annotations
            if let targetAnnotation = annotation as? PlanTargetAnnotation {
                let identifier = "PlanTargetAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create custom pin based on state
                let pinSize: CGFloat = 40
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: pinSize, height: pinSize))
                let pinImage = renderer.image { context in
                    if targetAnnotation.isCompleted {
                        // Green checkmark for completed
                        UIColor.systemGreen.setFill()
                        let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                        circle.fill()
                        
                        UIColor.white.setFill()
                        let checkmark = UIBezierPath()
                        checkmark.move(to: CGPoint(x: pinSize * 0.3, y: pinSize * 0.5))
                        checkmark.addLine(to: CGPoint(x: pinSize * 0.45, y: pinSize * 0.65))
                        checkmark.addLine(to: CGPoint(x: pinSize * 0.7, y: pinSize * 0.35))
                        checkmark.lineWidth = 3
                        checkmark.stroke()
                    } else if targetAnnotation.isCurrent {
                        // Blue pin for current target
                        UIColor.systemBlue.setFill()
                        let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                        circle.fill()
                        
                        UIColor.white.setFill()
                        let number = "\(targetAnnotation.index + 1)"
                        let font = UIFont.boldSystemFont(ofSize: 18)
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: UIColor.white
                        ]
                        let textSize = number.size(withAttributes: attributes)
                        let textRect = CGRect(
                            x: (pinSize - textSize.width) / 2,
                            y: (pinSize - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        number.draw(in: textRect, withAttributes: attributes)
                    } else {
                        // Gray pin for future targets
                        UIColor.systemGray.setFill()
                        let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                        circle.fill()
                        
                        UIColor.white.setFill()
                        let number = "\(targetAnnotation.index + 1)"
                        let font = UIFont.boldSystemFont(ofSize: 16)
                        let attributes: [NSAttributedString.Key: Any] = [
                            .font: font,
                            .foregroundColor: UIColor.white
                        ]
                        let textSize = number.size(withAttributes: attributes)
                        let textRect = CGRect(
                            x: (pinSize - textSize.width) / 2,
                            y: (pinSize - textSize.height) / 2,
                            width: textSize.width,
                            height: textSize.height
                        )
                        number.draw(in: textRect, withAttributes: attributes)
                    }
                    
                    UIColor.white.setStroke()
                    let border = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                    border.lineWidth = 2
                    border.stroke()
                }
                
                annotationView?.image = pinImage
                return annotationView
            }
            
            // Handle feeling checkpoint annotations
            if let feelingAnnotation = annotation as? FeelingAnnotation {
                let identifier = "FeelingAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                
                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                } else {
                    annotationView?.annotation = annotation
                }
                
                // Create custom pin with feeling color
                let pinSize: CGFloat = 30
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: pinSize, height: pinSize))
                let pinImage = renderer.image { context in
                    feelingAnnotation.checkpoint.feeling.uiColor.setFill()
                    let circle = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: pinSize, height: pinSize))
                    circle.fill()
                    
                    UIColor.white.setStroke()
                    circle.lineWidth = 3
                    circle.stroke()
                }
                
                annotationView?.image = pinImage
                return annotationView
            }
            
            return nil
        }
    }
}

// MARK: - Plan Target Annotation
class PlanTargetAnnotation: NSObject, MKAnnotation {
    let target: ExposureTarget
    let index: Int
    var isCurrent: Bool
    var isCompleted: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
    }
    
    var title: String? {
        target.name.isEmpty ? "Target \(index + 1)" : target.name
    }
    
    init(target: ExposureTarget, index: Int, isCurrent: Bool, isCompleted: Bool) {
        self.target = target
        self.index = index
        self.isCurrent = isCurrent
        self.isCompleted = isCompleted
        super.init()
    }
}

// MARK: - Location Tracking Manager
class LocationTrackingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isTracking = false
    @Published var trackingPoints: [CLLocation] = []
    @Published var feelingCheckpoints: [FeelingCheckpoint] = []
    @Published var hesitationPoints: [HesitationPoint] = []
    @Published var currentFeeling: FeelingLevel?
    @Published var showStats = false
    @Published var hapticsEnabled = true
    @Published var trackingDuration: String = "00:00"
    @Published var totalDistance: String = "0.0 km"
    @Published var averagePace: String = "0:00"
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    // Plan state management
    @Published var activePlan: ExposurePlan?
    @Published var currentTargetIndex: Int = 0
    @Published var isWaitingAtTarget: Bool = false
    @Published var waitTimerRemaining: TimeInterval = 0
    @Published var planCompleted: Bool = false
    
    var useMiles: Bool = false // Set from view based on user preference
    
    private let locationManager = CLLocationManager()
    private var startTime: Date?
    private var timer: Timer?
    private var saveTimer: Timer?
    private var waitTimer: Timer?
    private var distanceMeters: Double = 0
    var currentJourneyId: UUID? // Made public to access after journey ends
    private let geocoder = CLGeocoder()
    private var currentLocationName: String = "Finding location..."
    private var currentGeofence: CLCircularRegion?
    
    // Smoothing buffer for GPS coordinates
    private var smoothingBuffer: [CLLocation] = []
    private let smoothingWindowSize = 5
    
    // Hesitation detection state
    private var hesitationStartLocation: CLLocation?
    private var hesitationStartTime: Date?
    private let hesitationRadius: CLLocationDistance = 10.0 // 10 meters
    private let hesitationMinDuration: TimeInterval = 15.0 // 15 seconds
    
    // Live Activity
    @available(iOS 16.1, *)
    private var liveActivity: Activity<LocationTrackingAttributes>?
    
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    let successHaptic = UINotificationFeedbackGenerator()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        lightHaptic.prepare()
        mediumHaptic.prepare()
        successHaptic.prepare()
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
    
    func startTracking(with plan: ExposurePlan? = nil) {
        if hapticsEnabled {
            mediumHaptic.impactOccurred(intensity: 0.8)
        }
        
        isTracking = true
        
        // Track journey started
        Analytics.logEvent("journey_started", parameters: nil)
        
        trackingPoints = []
        feelingCheckpoints = []
        hesitationPoints = []
        smoothingBuffer = []
        hesitationStartLocation = nil
        hesitationStartTime = nil
        distanceMeters = 0
        totalDistance = useMiles ? "0.0 mi" : "0.0 km"
        averagePace = "0:00"
        startTime = Date()
        
        // Initialize plan state
        // Thaw the plan if it's frozen (from Realm)
        if let plan = plan {
            let thawedPlan: ExposurePlan
            if plan.isFrozen {
                if let realm = try? Realm() {
                    thawedPlan = realm.object(ofType: ExposurePlan.self, forPrimaryKey: plan.id) ?? plan
                } else {
                    thawedPlan = plan
                }
            } else {
                thawedPlan = plan
            }
            activePlan = thawedPlan
            currentTargetIndex = 0
            isWaitingAtTarget = false
            waitTimerRemaining = 0
            planCompleted = false
            currentGeofence = nil
            
            // Setup geofence for first target if plan exists
            let targets = thawedPlan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
            if !targets.isEmpty {
                setupGeofenceForTarget(targets[0])
            }
        } else {
            activePlan = nil
            currentTargetIndex = 0
            isWaitingAtTarget = false
            waitTimerRemaining = 0
            planCompleted = false
            currentGeofence = nil
        }
        
        // Find or create the current Journey object
        let realm = try? Realm()
        let currentJourney = realm?.objects(Journey.self).filter("current == true").first
        
        if let existingJourney = currentJourney {
            // Use existing journey's ID
            currentJourneyId = existingJourney.id
            
            // Update linkedPlanId if a plan is provided
            if let plan = plan {
                try? realm?.write {
                    existingJourney.linkedPlanId = plan.id
                    existingJourney.needsSync = true
                    existingJourney.isSynced = false
                    existingJourney.updatedAt = Date()
                }
            }
        } else {
            // Create new Journey if none exists
            let newJourney = Journey()
            newJourney.type = .None // Will be set from onboarding or can be updated
            newJourney.startDate = Date()
            newJourney.current = true
            newJourney.isCompleted = false
            
            // Set linkedPlanId if a plan is provided
            if let plan = plan {
                newJourney.linkedPlanId = plan.id
            }
            
            // saveJourney already handles the write transaction internally
            realm?.saveJourney(newJourney, needsSync: true)
            currentJourneyId = newJourney.id
        }
        
        // Create initial journey in Realm (JourneyRealm for tracking data)
        saveJourneyToRealm()
        
        locationManager.startUpdatingLocation()
        
        // Start timer for duration
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDuration()
        }
        
        // Start timer for saving to Realm every 5 seconds
        saveTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.saveJourneyToRealm()
        }
        
        // Start Live Activity
        if #available(iOS 16.1, *) {
            startLiveActivity()
        }
    }
    
    func stopTracking() {
        if hapticsEnabled {
            successHaptic.notificationOccurred(.success)
        }
        
        isTracking = false
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil
        saveTimer?.invalidate()
        saveTimer = nil
        waitTimer?.invalidate()
        waitTimer = nil
        
        // Stop monitoring geofence
        if let geofence = currentGeofence {
            locationManager.stopMonitoring(for: geofence)
            currentGeofence = nil
        }
        
        // Reset plan state
        activePlan = nil
        currentTargetIndex = 0
        isWaitingAtTarget = false
        waitTimerRemaining = 0
        planCompleted = false
        
        // End Live Activity
        if #available(iOS 16.1, *) {
            endLiveActivity()
        }
        
        // Track journey completed with metrics
        let duration = Int(Date().timeIntervalSince(startTime ?? Date()))
        Analytics.logEvent("journey_completed", parameters: [
            "duration_seconds": duration as NSObject,
            "distance_meters": Int(distanceMeters) as NSObject,
            "hesitation_count": hesitationPoints.count as NSObject
        ])
        
        // Save JourneyRealm (tracking data) FIRST - this must complete synchronously
        saveJourneyToRealm()
        
        // Also update the Journey object to mark it as completed and needing sync
        if let journeyId = currentJourneyId {
            if let realm = try? Realm() {
                if let journey = realm.object(ofType: Journey.self, forPrimaryKey: journeyId) {
                    try! realm.write {
                        journey.isCompleted = true
                        journey.current = false
                        journey.needsSync = true
                        journey.isSynced = false
                        journey.updatedAt = Date()
                    }
                }
            }
        }
    }
    
    func recordFeeling(_ feeling: FeelingLevel) {
        guard let location = trackingPoints.last else { return }
        
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.6)
        }
        
        let checkpoint = FeelingCheckpoint(
            id: UUID(),
            location: location,
            feeling: feeling,
            timestamp: Date()
        )
        
        feelingCheckpoints.append(checkpoint)
        currentFeeling = feeling
    }
    
    private func updateDuration() {
        guard let startTime = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        trackingDuration = String(format: "%02d:%02d", minutes, seconds)
        
        // Calculate pace (min/km or min/mi)
        if distanceMeters > 0 && elapsed > 0 {
            let distance = useMiles ? (distanceMeters / 1609.34) : (distanceMeters / 1000.0) // miles or km
            let paceMinPerUnit = Double(elapsed) / 60.0 / distance
            let paceMin = Int(paceMinPerUnit)
            let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
            averagePace = String(format: "%d:%02d", paceMin, paceSec)
        }
        
        // Update Live Activity
        if #available(iOS 16.1, *) {
            updateLiveActivity()
        }
    }
    
    // MARK: - Live Activity Methods
    @available(iOS 16.1, *)
    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        let attributes = LocationTrackingAttributes(startTime: startTime!)
        let location = trackingPoints.last ?? CLLocation(latitude: 0, longitude: 0)
        let contentState = LocationTrackingAttributes.ContentState(
            duration: trackingDuration,
            distance: totalDistance,
            pace: averagePace,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            locationName: currentLocationName
        )
        
        do {
            liveActivity = try Activity<LocationTrackingAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
        } catch {
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity() {
        guard let activity = liveActivity else { return }
        
        let location = trackingPoints.last ?? CLLocation(latitude: 0, longitude: 0)
        let contentState = LocationTrackingAttributes.ContentState(
            duration: trackingDuration,
            distance: totalDistance,
            pace: averagePace,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitude: location.altitude,
            locationName: currentLocationName
        )
        
        Task {
            await activity.update(using: contentState)
        }
    }
    
    @available(iOS 16.1, *)
    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
        }
        
        liveActivity = nil
    }
    
    private func calculateDistance() {
        guard trackingPoints.count > 1 else { return }
        
        var totalDist: Double = 0
        for i in 1..<trackingPoints.count {
            let dist = trackingPoints[i].distance(from: trackingPoints[i-1])
            totalDist += dist
        }
        
        distanceMeters = totalDist
        
        if useMiles {
            let miles = distanceMeters / 1609.34
            totalDistance = String(format: "%.2f mi", miles)
        } else {
            let kilometers = distanceMeters / 1000.0
            totalDistance = String(format: "%.2f km", kilometers)
        }
        
        // Also update pace
        if let startTime = startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            if distanceMeters > 0 && elapsed > 0 {
                let distance = useMiles ? (distanceMeters / 1609.34) : (distanceMeters / 1000.0)
                let paceMinPerUnit = Double(elapsed) / 60.0 / distance
                let paceMin = Int(paceMinPerUnit)
                let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
                averagePace = String(format: "%d:%02d", paceMin, paceSec)
            }
        }
    }
    
    // Public method to update distance display when unit preference changes
    func updateDistanceDisplay() {
        if useMiles {
            let miles = distanceMeters / 1609.34
            totalDistance = String(format: "%.2f mi", miles)
        } else {
            let kilometers = distanceMeters / 1000.0
            totalDistance = String(format: "%.2f km", kilometers)
        }
        
        // Also update pace
        if let startTime = startTime {
            let elapsed = Int(Date().timeIntervalSince(startTime))
            if distanceMeters > 0 && elapsed > 0 {
                let distance = useMiles ? (distanceMeters / 1609.34) : (distanceMeters / 1000.0)
                let paceMinPerUnit = Double(elapsed) / 60.0 / distance
                let paceMin = Int(paceMinPerUnit)
                let paceSec = Int((paceMinPerUnit - Double(paceMin)) * 60)
                averagePace = String(format: "%d:%02d", paceMin, paceSec)
            }
        }
    }
    
    func saveJourneyToRealm() {
        guard let journeyId = currentJourneyId else {
            return
        }
        
        guard let realm = try? Realm() else {
            return
        }
        
        do {
            try realm.write {
                let journeyIdString = journeyId.uuidString
                
                // Check if journey exists
                if let existingJourney = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyIdString) {
                    // Update existing journey
                    existingJourney.endTime = Date()
                    existingJourney.distance = distanceMeters
                    existingJourney.duration = Int(Date().timeIntervalSince(startTime ?? Date()))
                    existingJourney.updatedAt = Date()
                    existingJourney.needsSync = true
                    existingJourney.isSynced = false
                    
                    // Clear and re-add path points
                    existingJourney.pathPoints.removeAll()
                    for location in trackingPoints {
                        let pathPoint = PathPointRealm()
                        pathPoint.latitude = location.coordinate.latitude
                        pathPoint.longitude = location.coordinate.longitude
                        pathPoint.timestamp = location.timestamp
                        existingJourney.pathPoints.append(pathPoint)
                    }
                    
                    // Clear and re-add checkpoints
                    existingJourney.checkpoints.removeAll()
                    for checkpoint in feelingCheckpoints {
                        let realmCheckpoint = FeelingCheckpointRealm()
                        realmCheckpoint.id = checkpoint.id.uuidString
                        realmCheckpoint.latitude = checkpoint.location.coordinate.latitude
                        realmCheckpoint.longitude = checkpoint.location.coordinate.longitude
                        realmCheckpoint.feeling = checkpoint.feeling.rawValue
                        realmCheckpoint.timestamp = checkpoint.timestamp
                        existingJourney.checkpoints.append(realmCheckpoint)
                    }
                    
                    // Clear and re-add hesitation points
                    existingJourney.hesitationPoints.removeAll()
                    for hesitation in hesitationPoints {
                        let realmHesitation = HesitationPointRealm()
                        realmHesitation.id = hesitation.id.uuidString
                        realmHesitation.latitude = hesitation.location.coordinate.latitude
                        realmHesitation.longitude = hesitation.location.coordinate.longitude
                        realmHesitation.startTime = hesitation.startTime
                        realmHesitation.endTime = hesitation.endTime
                        realmHesitation.duration = hesitation.duration
                        existingJourney.hesitationPoints.append(realmHesitation)
                    }
                } else {
                    // Create new journey
                    let journey = JourneyRealm()
                    journey.id = journeyIdString
                    journey.startTime = startTime ?? Date()
                    journey.endTime = Date()
                    journey.distance = distanceMeters
                    journey.duration = Int(Date().timeIntervalSince(startTime ?? Date()))
                    journey.updatedAt = Date()
                    journey.needsSync = true
                    journey.isSynced = false
                    
                    // Add path points
                    for location in trackingPoints {
                        let pathPoint = PathPointRealm()
                        pathPoint.latitude = location.coordinate.latitude
                        pathPoint.longitude = location.coordinate.longitude
                        pathPoint.timestamp = location.timestamp
                        journey.pathPoints.append(pathPoint)
                    }
                    
                    // Add checkpoints
                    for checkpoint in feelingCheckpoints {
                        let realmCheckpoint = FeelingCheckpointRealm()
                        realmCheckpoint.id = checkpoint.id.uuidString
                        realmCheckpoint.latitude = checkpoint.location.coordinate.latitude
                        realmCheckpoint.longitude = checkpoint.location.coordinate.longitude
                        realmCheckpoint.feeling = checkpoint.feeling.rawValue
                        realmCheckpoint.timestamp = checkpoint.timestamp
                        journey.checkpoints.append(realmCheckpoint)
                    }
                    
                    // Add hesitation points
                    for hesitation in hesitationPoints {
                        let realmHesitation = HesitationPointRealm()
                        realmHesitation.id = hesitation.id.uuidString
                        realmHesitation.latitude = hesitation.location.coordinate.latitude
                        realmHesitation.longitude = hesitation.location.coordinate.longitude
                        realmHesitation.startTime = hesitation.startTime
                        realmHesitation.endTime = hesitation.endTime
                        realmHesitation.duration = hesitation.duration
                        journey.hesitationPoints.append(realmHesitation)
                    }
                    
                    realm.add(journey)
                }
            }
            
            // Update safe area points AFTER write transaction completes
            let journeyIdString = journeyId.uuidString
            updateSafeAreaPoints(journeyId: journeyIdString)
        } catch {
            print("❌ Error saving journey to Realm: \(error)")
        }
    }
    
    // MARK: - Coordinate Smoothing
    /// Apply moving average smoothing to GPS coordinates
    private func smoothCoordinate(_ location: CLLocation) -> CLLocation {
        smoothingBuffer.append(location)
        
        // Keep buffer size limited
        if smoothingBuffer.count > smoothingWindowSize {
            smoothingBuffer.removeFirst()
        }
        
        // If we have enough points, calculate average
        guard smoothingBuffer.count >= 2 else {
            return location
        }
        
        // Calculate weighted average (more weight to recent points)
        var totalWeight: Double = 0
        var weightedLat: Double = 0
        var weightedLon: Double = 0
        var weightedAlt: Double = 0
        var totalAccuracy: Double = 0
        
        for (index, loc) in smoothingBuffer.enumerated() {
            let weight = Double(index + 1) // More recent = higher weight
            totalWeight += weight
            weightedLat += loc.coordinate.latitude * weight
            weightedLon += loc.coordinate.longitude * weight
            weightedAlt += loc.altitude * weight
            totalAccuracy += loc.horizontalAccuracy
        }
        
        let avgLat = weightedLat / totalWeight
        let avgLon = weightedLon / totalWeight
        let avgAlt = weightedAlt / totalWeight
        let avgAccuracy = totalAccuracy / Double(smoothingBuffer.count)
        
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon),
            altitude: avgAlt,
            horizontalAccuracy: avgAccuracy,
            verticalAccuracy: location.verticalAccuracy,
            timestamp: location.timestamp
        )
    }
    
    // MARK: - Hesitation Detection
    private func detectHesitation(for location: CLLocation) {
        if let startLoc = hesitationStartLocation, let startTime = hesitationStartTime {
            // Check if still within hesitation radius
            let distance = location.distance(from: startLoc)
            
            if distance <= hesitationRadius {
                // Still hesitating
                let duration = Date().timeIntervalSince(startTime)
                
                if duration >= hesitationMinDuration {
                    // Check if we already have a hesitation point for this location
                    let existingIndex = hesitationPoints.firstIndex { hp in
                        hp.location.distance(from: startLoc) <= hesitationRadius
                    }
                    
                    if let index = existingIndex {
                        // Update existing hesitation point duration
                        let existing = hesitationPoints[index]
                        hesitationPoints[index] = HesitationPoint(
                            id: existing.id,
                            location: existing.location,
                            startTime: existing.startTime,
                            endTime: Date(),
                            duration: duration
                        )
                    } else {
                        // Create new hesitation point
                        let hesitationPoint = HesitationPoint(
                            id: UUID(),
                            location: startLoc,
                            startTime: startTime,
                            endTime: Date(),
                            duration: duration
                        )
                        hesitationPoints.append(hesitationPoint)
                    }
                }
            } else {
                // Moved outside radius, reset hesitation tracking
                hesitationStartLocation = nil
                hesitationStartTime = nil
            }
        } else {
            // Check if we're at the same location as recent points
            if trackingPoints.count >= 2 {
                let recentPoints = trackingPoints.suffix(3)
                let avgDistance = recentPoints.reduce(0.0) { total, point in
                    total + location.distance(from: point)
                } / Double(recentPoints.count)
                
                if avgDistance <= hesitationRadius {
                    // Start tracking potential hesitation
                    hesitationStartLocation = location
                    hesitationStartTime = Date()
                }
            }
        }
    }
    
    // MARK: - Safe Area Tracking
    private func updateSafeAreaPoints(journeyId: String) {
        guard let realm = try? Realm() else { return }
        
        guard let journey = realm.object(ofType: JourneyRealm.self, forPrimaryKey: journeyId) else {
            return
        }
        
        // Find first anxious/panic checkpoint timestamp (if any)
        let unsafeCheckpoints = journey.checkpoints.filter { checkpoint in
            let feeling = FeelingLevel(rawValue: checkpoint.feeling) ?? .okay
            return feeling == .anxious || feeling == .panic
        }
        
        let firstUnsafeTime = unsafeCheckpoints.sorted(by: { $0.timestamp < $1.timestamp }).first?.timestamp
        
        // Remove existing safe area points for this journey
        try? realm.write {
            let existingPoints = realm.objects(SafeAreaPointRealm.self).filter("journeyId == %@", journeyId)
            realm.delete(existingPoints)
        }
        
        // Add safe path points
        try? realm.write {
            for pathPoint in journey.pathPoints {
                // If no unsafe checkpoints, or this point is before first unsafe checkpoint
                if firstUnsafeTime == nil || pathPoint.timestamp < firstUnsafeTime! {
                    let safePoint = SafeAreaPointRealm()
                    safePoint.latitude = pathPoint.latitude
                    safePoint.longitude = pathPoint.longitude
                    safePoint.timestamp = pathPoint.timestamp
                    safePoint.journeyId = journeyId
                    realm.add(safePoint)
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }
        
        for location in locations {
            if location.horizontalAccuracy < 50 { // Only add accurate locations
                // Apply smoothing
                let smoothedLocation = smoothCoordinate(location)
                trackingPoints.append(smoothedLocation)
                
                // Detect hesitations
                detectHesitation(for: smoothedLocation)
                
                calculateDistance()
                
                // Reverse geocode to get street name (every 5th update to avoid overuse)
                if trackingPoints.count % 5 == 0 {
                    geocodeLocation(smoothedLocation)
                }
            }
        }
    }
    
    private func geocodeLocation(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            
            if let _ = error { return }
            
            if let placemark = placemarks?.first {
                // Get street name or fallback to locality
                let name = placemark.thoroughfare ?? placemark.locality ?? "Unknown location"
                DispatchQueue.main.async {
                    self.currentLocationName = name
                }
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        permissionStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { }
    
    // MARK: - Geofencing for Exposure Plans
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion,
              let plan = activePlan,
              !isWaitingAtTarget else { return }
        
        // Get current target
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        guard currentTargetIndex < targets.count else { return }
        
        let target = targets[currentTargetIndex]
        
        // Verify this is the correct region
        let targetCoordinate = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
        let regionCenter = circularRegion.center
        let distance = CLLocation(latitude: targetCoordinate.latitude, longitude: targetCoordinate.longitude)
            .distance(from: CLLocation(latitude: regionCenter.latitude, longitude: regionCenter.longitude))
        
        guard distance < 50 else { return } // Within 50 meters
        
        // Target reached!
        if hapticsEnabled {
            successHaptic.notificationOccurred(.success)
        }
        
        // Start wait timer
        isWaitingAtTarget = true
        waitTimerRemaining = TimeInterval(target.waitTimeInSeconds)
        startWaitTimer()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Optional: Handle if user leaves before wait completes
        // For now, we'll just log it
        if isWaitingAtTarget {
            print("⚠️ User left target region before wait completed")
        }
    }
    
    private func setupGeofenceForTarget(_ target: ExposureTarget) {
        // Remove existing geofence
        if let existingGeofence = currentGeofence {
            locationManager.stopMonitoring(for: existingGeofence)
        }
        
        // Calculate dynamic radius based on location accuracy
        // Get current location accuracy if available
        let baseRadius: CLLocationDistance = 10.0 // Minimum 10 meters
        let maxRadius: CLLocationDistance = 20.0 // Maximum 20 meters
        
        // Use a default radius, or calculate from current location if available
        var radius = baseRadius
        if let lastLocation = trackingPoints.last {
            // Use location accuracy to determine radius
            let accuracy = lastLocation.horizontalAccuracy
            radius = min(maxRadius, max(baseRadius, accuracy * 2))
        } else {
            radius = baseRadius
        }
        
        // Create geofence
        let coordinate = CLLocationCoordinate2D(latitude: target.latitude, longitude: target.longitude)
        let region = CLCircularRegion(center: coordinate, radius: radius, identifier: "target_\(target.id.uuidString)")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        currentGeofence = region
        locationManager.startMonitoring(for: region)
        
        print("📍 Geofence set up for target: \(target.name) at radius: \(radius)m")
    }
    
    // MARK: - Wait Timer
    
    private func startWaitTimer() {
        waitTimer?.invalidate()
        
        waitTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.waitTimerRemaining > 0 {
                self.waitTimerRemaining -= 1
            } else {
                // Timer completed
                self.waitTimer?.invalidate()
                self.waitTimer = nil
                self.completeWait()
            }
        }
    }
    
    func skipWaitTimer() {
        waitTimer?.invalidate()
        waitTimer = nil
        completeWait()
    }
    
    private func completeWait() {
        guard let plan = activePlan else { return }
        
        let targets = plan.targets.filter { !$0.isDeleted }.sorted(by: { $0.orderIndex < $1.orderIndex })
        
        if hapticsEnabled {
            successHaptic.notificationOccurred(.success)
        }
        
        // Check if this was the last target
        if currentTargetIndex >= targets.count - 1 {
            // Plan completed!
            planCompleted = true
            isWaitingAtTarget = false
            waitTimerRemaining = 0
            
            // Stop monitoring geofence
            if let geofence = currentGeofence {
                locationManager.stopMonitoring(for: geofence)
                currentGeofence = nil
            }
        } else {
            // Advance to next target
            currentTargetIndex += 1
            isWaitingAtTarget = false
            waitTimerRemaining = 0
            
            // Setup geofence for next target
            if currentTargetIndex < targets.count {
                setupGeofenceForTarget(targets[currentTargetIndex])
            }
        }
    }
}

// MARK: - Models
enum FeelingLevel: String, CaseIterable {
    case great = "Great"
    case good = "Good"
    case okay = "Okay"
    case anxious = "Anxious"
    case panic = "Panic"
    
    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .good: return "face.smiling"
        case .okay: return "minus.circle.fill"
        case .anxious: return "exclamationmark.triangle.fill"
        case .panic: return "exclamationmark.octagon.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .great: return .green
        case .good: return .blue
        case .okay: return .yellow
        case .anxious: return .orange
        case .panic: return .red
        }
    }
    
    var uiColor: UIColor {
        switch self {
        case .great: return .systemGreen
        case .good: return .systemBlue
        case .okay: return .systemYellow
        case .anxious: return .systemOrange
        case .panic: return .systemRed
        }
    }
    
    var title: String {
        return rawValue
    }
}

struct FeelingCheckpoint: Identifiable {
    let id: UUID
    let location: CLLocation
    let feeling: FeelingLevel
    let timestamp: Date
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
    }
}

// MARK: - Hesitation Point Model
struct HesitationPoint: Identifiable {
    let id: UUID
    let location: CLLocation
    let startTime: Date
    let endTime: Date
    let duration: TimeInterval
    
    var coordinate: CLLocationCoordinate2D {
        location.coordinate
    }
}

class FeelingAnnotation: NSObject, MKAnnotation {
    let checkpoint: FeelingCheckpoint
    
    var coordinate: CLLocationCoordinate2D {
        checkpoint.coordinate
    }
    
    var title: String? {
        checkpoint.feeling.title
    }
    
    var subtitle: String? {
        checkpoint.timestamp.formatted(date: .omitted, time: .shortened)
    }
    
    init(checkpoint: FeelingCheckpoint) {
        self.checkpoint = checkpoint
    }
}

// MARK: - Hesitation Annotation
class HesitationAnnotation: NSObject, MKAnnotation {
    let hesitationPoint: HesitationPoint
    
    var coordinate: CLLocationCoordinate2D {
        hesitationPoint.coordinate
    }
    
    var title: String? {
        "Hesitation"
    }
    
    var subtitle: String? {
        "\(Int(hesitationPoint.duration))s"
    }
    
    init(hesitationPoint: HesitationPoint) {
        self.hesitationPoint = hesitationPoint
    }
}

// MARK: - Realm Models
class JourneyRealm: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date = Date()
    @Persisted var distance: Double = 0.0 // in meters
    @Persisted var duration: Int = 0 // in seconds
    @Persisted var pathPoints = RealmSwift.List<PathPointRealm>()
    @Persisted var checkpoints = RealmSwift.List<FeelingCheckpointRealm>()
    @Persisted var hesitationPoints = RealmSwift.List<HesitationPointRealm>()
    
    // Sync metadata
    @Persisted var isSynced: Bool = false // Has been synced to cloud
    @Persisted var needsSync: Bool = false // Needs to be synced (create/update)
    @Persisted var isDeleted: Bool = false // Soft delete flag
    @Persisted var lastSyncedAt: Date? = nil // Last successful sync timestamp
    @Persisted var updatedAt: Date = Date() // Last local update
}

class PathPointRealm: Object {
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var timestamp: Date = Date()
}

class FeelingCheckpointRealm: Object {
    @Persisted var id: String = ""
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var feeling: String = ""
    @Persisted var timestamp: Date = Date()
}

class HesitationPointRealm: Object {
    @Persisted var id: String = ""
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var startTime: Date = Date()
    @Persisted var endTime: Date = Date()
    @Persisted var duration: Double = 0.0 // in seconds
}

class SafeAreaPointRealm: Object {
    @Persisted var latitude: Double = 0.0
    @Persisted var longitude: Double = 0.0
    @Persisted var timestamp: Date = Date()
    @Persisted var journeyId: String = "" // Track which journey this point came from
}

// MARK: - Preview
#Preview {
    @Previewable @State var isTabBarVisible = true
    LocationTrackingView(isTabBarVisible: $isTabBarVisible)
}

