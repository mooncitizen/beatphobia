//
//  PastJourneysView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI
import RealmSwift

struct PastJourneysView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var journeys: [JourneyRealm] = []
    @AppStorage("setting.miles") private var enableMiles = false
    @State private var currentPage: Int? = 0
    @State private var showPaywall = false
    
    // Computed property for displayed journeys (limited to 3 if not Pro)
    private var displayedJourneys: [JourneyRealm] {
        let sortedJourneys = journeys.sorted(by: { $0.startTime > $1.startTime })
        if subscriptionManager.isPro {
            return sortedJourneys
        } else {
            return Array(sortedJourneys.prefix(3))
        }
    }
    
    var body: some View {
        ZStack {
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            if journeys.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Stats cards - Only for Pro users
                        if subscriptionManager.isPro {
                            VStack(spacing: 12) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 16) {
                                        // Last 7 Days Card
                                        last7DaysStatsCard
                                            .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                                            .id(0)
                                        
                                        // Overall Stats Card
                                        overallStatsCard
                                            .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                                            .id(1)
                                    }
                                    .scrollTargetLayout()
                                }
                                .scrollTargetBehavior(.paging)
                                .scrollPosition(id: $currentPage)
                                .padding(.horizontal, 20)
                                
                                // Page indicators
                                HStack(spacing: 8) {
                                    ForEach(0..<2, id: \.self) { index in
                                        Circle()
                                            .fill((currentPage ?? 0) == index ? AppConstants.primaryColor : Color.black.opacity(0.2))
                                            .frame(width: 8, height: 8)
                                            .animation(.easeInOut(duration: 0.2), value: currentPage)
                                    }
                                }
                            }
                        }
                        
                        // Journey list
                        VStack(spacing: 16) {
                            ForEach(displayedJourneys, id: \.id) { journey in
                                NavigationLink(destination: JourneyDetailView(journey: journey)) {
                                    JourneyCard(journey: journey, enableMiles: enableMiles)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Simple upgrade button for free users
                            if !subscriptionManager.isPro && journeys.count > 3 {
                                simpleUpgradeButton
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Past Journeys")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
            }
        }
        .toolbar(.visible, for: .tabBar)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
        }
        .onAppear {
            loadJourneys()
        }
    }
    
    // MARK: - Simple Upgrade Button
    private var simpleUpgradeButton: some View {
        Button(action: { showPaywall = true }) {
            Text("View All \(journeys.count) Journeys")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(AppConstants.primaryColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConstants.primaryColor.opacity(0.3), lineWidth: 1.5)
                )
        }
        .padding(.top, 8)
    }
    
    // MARK: - Last 7 Days Stats Card
    private var last7DaysStatsCard: some View {
        let last7DaysJourneys = journeys.filter { journey in
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return journey.startTime >= sevenDaysAgo
        }
        
        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last 7 Days")
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    Text("Your recent progress")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.5))
                }
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.3))
            }
            
            HStack(spacing: 12) {
                summaryStatBox(
                    title: "Journeys",
                    value: "\(last7DaysJourneys.count)",
                    icon: "map.circle.fill",
                    color: .blue
                )
                
                summaryStatBox(
                    title: "Distance",
                    value: formatDistance(last7DaysJourneys.reduce(0.0) { $0 + $1.distance }),
                    icon: "figure.walk",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                summaryStatBox(
                    title: "Time",
                    value: formatDuration(last7DaysJourneys.reduce(0) { $0 + $1.duration }),
                    icon: "clock.fill",
                    color: .orange
                )
                
                summaryStatBox(
                    title: "Checkpoints",
                    value: "\(last7DaysJourneys.reduce(0) { $0 + $1.checkpoints.count })",
                    icon: "heart.fill",
                    color: .pink
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
    }
    
    // MARK: - Overall Stats Card
    private var overallStatsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("All Time")
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    Text("Your total progress")
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.5))
                }
                Spacer()
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.3))
            }
            
            HStack(spacing: 12) {
                summaryStatBox(
                    title: "Journeys",
                    value: "\(journeys.count)",
                    icon: "map.circle.fill",
                    color: .blue
                )
                
                summaryStatBox(
                    title: "Distance",
                    value: formatTotalDistance(),
                    icon: "figure.walk",
                    color: .green
                )
            }
            
            HStack(spacing: 12) {
                summaryStatBox(
                    title: "Time",
                    value: formatTotalDuration(),
                    icon: "clock.fill",
                    color: .orange
                )
                
                summaryStatBox(
                    title: "Checkpoints",
                    value: "\(totalCheckpoints())",
                    icon: "heart.fill",
                    color: .pink
                )
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
    }
    
    private func summaryStatBox(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(.black)
            
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.black.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppConstants.primaryColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "map.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.5))
            }
            
            VStack(spacing: 12) {
                Text("No Journeys Yet")
                    .font(.system(size: 28, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Start your first journey to track your progress and feelings as you explore outside your safe space.")
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadJourneys() {
        guard let realm = try? Realm() else { return }
        let results = realm.objects(JourneyRealm.self)
        journeys = Array(results)
    }
    
    private func formatDistance(_ meters: Double) -> String {
        if enableMiles {
            let miles = meters / 1609.34
            return String(format: "%.1f mi", miles)
        } else {
            let km = meters / 1000.0
            return String(format: "%.1f km", km)
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
    
    private func formatTotalDistance() -> String {
        let totalMeters = journeys.reduce(0.0) { $0 + $1.distance }
        return formatDistance(totalMeters)
    }
    
    private func formatTotalDuration() -> String {
        let totalSeconds = journeys.reduce(0) { $0 + $1.duration }
        return formatDuration(totalSeconds)
    }
    
    private func totalCheckpoints() -> Int {
        journeys.reduce(0) { $0 + $1.checkpoints.count }
    }
}

// MARK: - Journey Card
struct JourneyCard: View {
    let journey: JourneyRealm
    let enableMiles: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with date and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(journey.startTime.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                        Text(journey.startTime.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.black.opacity(0.5))
                }
                
                Spacer()
                
                // Duration badge
                VStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 18))
                        .foregroundColor(AppConstants.primaryColor)
                    Text(formatDuration(journey.duration))
                        .font(.system(size: 14, weight: .semibold))
                        .fontDesign(.monospaced)
                        .foregroundColor(.black)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppConstants.primaryColor.opacity(0.1))
                .cornerRadius(10)
            }
            
            Divider()
            
            // Stats row
            HStack(spacing: 16) {
                journeyStatPill(
                    icon: "figure.walk",
                    value: formatDistance(journey.distance),
                    color: .green
                )
                
                journeyStatPill(
                    icon: "gauge.high",
                    value: calculatePace(),
                    color: .orange
                )
                
                if !journey.checkpoints.isEmpty {
                    journeyStatPill(
                        icon: "heart.fill",
                        value: "\(journey.checkpoints.count)",
                        color: .pink
                    )
                }
            }
            
            // Emotion badges
            if !journey.checkpoints.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotional Journey")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black.opacity(0.5))
                    
                    HStack(spacing: 8) {
                        ForEach(Array(journey.checkpoints.prefix(6)), id: \.id) { checkpoint in
                            emotionBadge(feeling: checkpoint.feeling)
                        }
                        if journey.checkpoints.count > 6 {
                            Text("+\(journey.checkpoints.count - 6)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, y: 4)
    }
    
    private func journeyStatPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func emotionBadge(feeling: String) -> some View {
        let feelingLevel = FeelingLevel(rawValue: feeling) ?? .okay
        
        return Image(systemName: feelingLevel.icon)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(feelingLevel.color)
            .frame(width: 32, height: 32)
            .background(feelingLevel.color.opacity(0.15))
            .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
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
            return String(format: "%dh%dm", hours, mins)
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

