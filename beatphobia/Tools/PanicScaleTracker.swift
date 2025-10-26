//
//  PanicScaleTracker.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI
import RealmSwift
import Auth

// MARK: - Realm Models
class PanicEpisode: Object, Identifiable {
    @Persisted(primaryKey: true) var id: String = UUID().uuidString
    @Persisted var userId: String = ""
    @Persisted var timestamp: Date = Date()
    
    // Core metrics
    @Persisted var initialIntensity: Int = 0 // 0-10
    @Persisted var peakIntensity: Int = 0 // 0-10
    @Persisted var finalIntensity: Int = 0 // 0-10
    @Persisted var duration: TimeInterval = 0 // in seconds
    
    // Physical symptoms (0-10 each)
    @Persisted var heartRate: Int = 0
    @Persisted var breathingDifficulty: Int = 0
    @Persisted var chestTightness: Int = 0
    @Persisted var sweating: Int = 0
    @Persisted var trembling: Int = 0
    @Persisted var dizziness: Int = 0
    @Persisted var nausea: Int = 0
    
    // Cognitive symptoms (0-10 each)
    @Persisted var fearOfDying: Int = 0
    @Persisted var fearOfLosingControl: Int = 0
    @Persisted var derealization: Int = 0 // feeling of unreality
    @Persisted var racingThoughts: Int = 0
    
    // Context
    @Persisted var location: String = "" // home, public, work, etc
    @Persisted var trigger: String = "" // known trigger if any
    @Persisted var timeOfDay: String = "" // morning, afternoon, evening, night
    @Persisted var aloneOrWithOthers: String = "" // alone, with people
    
    // Coping strategies used
    @Persisted var copingStrategiesUsed: RealmSwift.List<String>
    @Persisted var strategyEffectiveness: Int = 0 // 0-10
    
    // Aftermath
    @Persisted var recoveryTime: TimeInterval = 0 // time to feel normal again
    @Persisted var afterEffects: RealmSwift.List<String> // fatigue, headache, etc
    
    // Notes
    @Persisted var notes: String = ""
}

enum PanicSymptomCategory: String, CaseIterable {
    case physical = "Physical"
    case cognitive = "Mental"
    case intensity = "Intensity"
    
    var icon: String {
        switch self {
        case .physical: return "heart.fill"
        case .cognitive: return "brain.head.profile"
        case .intensity: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Main View
struct PanicScaleView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @ObservedResults(PanicEpisode.self) var allEpisodes
    
    @State private var showTracker = false
    @State private var selectedEpisode: PanicEpisode?
    
    var userEpisodes: [PanicEpisode] {
        let userId = authManager.currentUser?.id.uuidString ?? ""
        return allEpisodes.filter { $0.userId == userId }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.98),
                    Color(red: 0.92, green: 0.92, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Panic Tracker")
                        .font(.system(size: 22, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Quick stats (fixed at top)
                if !userEpisodes.isEmpty {
                    statsSection
                        .padding(.bottom, 16)
                }
                
                // Start tracking button (fixed below stats)
                Button(action: { showTracker = true }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                        
                        Text(userEpisodes.isEmpty ? "Track Your First Episode" : "Track New Episode")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                // Scrollable episode history
                ScrollView {
                    VStack(spacing: 24) {
                        // Episode history
                        if !userEpisodes.isEmpty {
                            episodeHistorySection
                        } else {
                            emptyStateView
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showTracker) {
            PanicTrackerFlow()
        }
        .sheet(item: $selectedEpisode) { episode in
            EpisodeDetailView(episode: episode)
        }
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Insights")
                .font(.system(size: 18, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    StatCard(
                        title: "Episodes",
                        value: "\(userEpisodes.count)",
                        subtitle: "Total tracked",
                        icon: "chart.bar.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Avg Peak",
                        value: String(format: "%.1f", averagePeakIntensity),
                        subtitle: "out of 10",
                        icon: "arrow.up.circle.fill",
                        color: .red
                    )
                    
                    StatCard(
                        title: "Avg Duration",
                        value: formatDuration(averageDuration),
                        subtitle: "minutes",
                        icon: "clock.fill",
                        color: .orange
                    )
                    
                    if let commonTrigger = mostCommonTrigger {
                        StatCard(
                            title: "Top Trigger",
                            value: commonTrigger,
                            subtitle: "Most common",
                            icon: "exclamationmark.triangle.fill",
                            color: .purple
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Episode History
    private var episodeHistorySection: some View {
        VStack(spacing: 12) {
            Text("Episode History")
                .font(.system(size: 18, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
            
            ForEach(Array(userEpisodes.prefix(10)), id: \.id) { episode in
                EpisodeCard(episode: episode)
                    .onTapGesture {
                        selectedEpisode = episode
                    }
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.purple.opacity(0.5))
            
            Text("Start Tracking")
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
            
            Text("Track panic episodes to understand patterns, triggers, and what helps you most.")
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Computed Properties
    private var averagePeakIntensity: Double {
        guard !userEpisodes.isEmpty else { return 0 }
        let sum = userEpisodes.reduce(0) { $0 + $1.peakIntensity }
        return Double(sum) / Double(userEpisodes.count)
    }
    
    private var averageDuration: TimeInterval {
        guard !userEpisodes.isEmpty else { return 0 }
        let sum = userEpisodes.reduce(0.0) { $0 + $1.duration }
        return sum / Double(userEpisodes.count)
    }
    
    private var mostCommonTrigger: String? {
        let triggers = userEpisodes.compactMap { $0.trigger.isEmpty ? nil : $0.trigger }
        guard !triggers.isEmpty else { return nil }
        
        let counts = triggers.reduce(into: [:]) { counts, trigger in
            counts[trigger, default: 0] += 1
        }
        
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)"
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
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
                .foregroundColor(.black)
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.black.opacity(0.7))
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.black.opacity(0.5))
        }
        .padding(16)
        .frame(width: 140)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Episode Card Component
struct EpisodeCard: View {
    let episode: PanicEpisode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(episode.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.system(size: 13))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Spacer()
                
                // Peak intensity badge
                HStack(spacing: 4) {
                    Text("\(episode.peakIntensity)")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                    
                    Text("/10")
                        .font(.system(size: 12))
                        .foregroundColor(.black.opacity(0.5))
                }
                .foregroundColor(intensityColor(episode.peakIntensity))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(intensityColor(episode.peakIntensity).opacity(0.15))
                .cornerRadius(8)
            }
            
            // Key details
            HStack(spacing: 16) {
                if episode.duration > 0 {
                    DetailPill(icon: "clock.fill", text: formatDuration(episode.duration))
                }
                
                if !episode.location.isEmpty {
                    DetailPill(icon: "location.fill", text: episode.location)
                }
                
                if !episode.trigger.isEmpty {
                    DetailPill(icon: "exclamationmark.triangle.fill", text: episode.trigger)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
    
    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 0...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .purple
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - Detail Pill Component
struct DetailPill: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            
            Text(text)
                .font(.system(size: 12))
                .lineLimit(1)
        }
        .foregroundColor(.black.opacity(0.6))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.05))
        .cornerRadius(6)
    }
}

// MARK: - Panic Tracker Flow (Multi-step form)
struct PanicTrackerFlow: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.realm) var realm
    
    @State private var currentStep = 0
    
    // Data collection state variables
    @State private var initialIntensity: Int = 0
    @State private var peakIntensity: Int = 0
    @State private var finalIntensity: Int = 0
    
    // Physical symptoms
    @State private var heartRate: Int = 0
    @State private var breathingDifficulty: Int = 0
    @State private var chestTightness: Int = 0
    @State private var sweating: Int = 0
    @State private var trembling: Int = 0
    @State private var dizziness: Int = 0
    @State private var nausea: Int = 0
    
    // Cognitive symptoms
    @State private var fearOfDying: Int = 0
    @State private var fearOfLosingControl: Int = 0
    @State private var derealization: Int = 0
    @State private var racingThoughts: Int = 0
    
    // Context
    @State private var location: String = ""
    @State private var trigger: String = ""
    @State private var timeOfDay: String = ""
    @State private var aloneOrWithOthers: String = ""
    
    // Coping and aftermath
    @State private var selectedCopingStrategies: Set<String> = []
    @State private var selectedAfterEffects: Set<String> = []
    @State private var notes: String = ""
    
    let totalSteps = 7
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.98),
                    Color(red: 0.92, green: 0.92, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        if currentStep > 0 {
                            withAnimation {
                                currentStep -= 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: currentStep > 0 ? "arrow.left.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Step \(currentStep + 1) of \(totalSteps)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.6))
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.1))
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.purple)
                                    .frame(width: geometry.size.width * (Double(currentStep + 1) / Double(totalSteps)), height: 6)
                            }
                        }
                        .frame(width: 120, height: 6)
                    }
                    
                    Spacer()
                    
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Step content
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Navigation button
                Button(action: nextStep) {
                    Text(currentStep == totalSteps - 1 ? "Save Episode" : "Continue")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            IntensityStep(
                title: "How intense is your panic right now?",
                subtitle: "Rate your current level",
                value: $initialIntensity
            )
        case 1:
            PhysicalSymptomsStep(
                heartRate: $heartRate,
                breathingDifficulty: $breathingDifficulty,
                chestTightness: $chestTightness,
                sweating: $sweating,
                trembling: $trembling,
                dizziness: $dizziness,
                nausea: $nausea
            )
        case 2:
            CognitiveSymptomsStep(
                fearOfDying: $fearOfDying,
                fearOfLosingControl: $fearOfLosingControl,
                derealization: $derealization,
                racingThoughts: $racingThoughts
            )
        case 3:
            ContextStep(
                location: $location,
                trigger: $trigger,
                timeOfDay: $timeOfDay,
                aloneOrWithOthers: $aloneOrWithOthers
            )
        case 4:
            CopingStrategiesStep(selectedStrategies: $selectedCopingStrategies)
        case 5:
            IntensityStep(
                title: "What was your peak intensity?",
                subtitle: "The highest level you felt",
                value: $peakIntensity
            )
        case 6:
            FinalStep(
                finalIntensity: $finalIntensity,
                selectedAfterEffects: $selectedAfterEffects,
                notes: $notes
            )
        default:
            EmptyView()
        }
    }
    
    private func nextStep() {
        if currentStep < totalSteps - 1 {
            withAnimation {
                currentStep += 1
            }
        } else {
            saveEpisode()
        }
    }
    
    private func saveEpisode() {
        let episode = PanicEpisode()
        episode.userId = authManager.currentUser?.id.uuidString ?? ""
        episode.timestamp = Date()
        
        // Intensity
        episode.initialIntensity = initialIntensity
        episode.peakIntensity = peakIntensity
        episode.finalIntensity = finalIntensity
        
        // Physical symptoms
        episode.heartRate = heartRate
        episode.breathingDifficulty = breathingDifficulty
        episode.chestTightness = chestTightness
        episode.sweating = sweating
        episode.trembling = trembling
        episode.dizziness = dizziness
        episode.nausea = nausea
        
        // Cognitive symptoms
        episode.fearOfDying = fearOfDying
        episode.fearOfLosingControl = fearOfLosingControl
        episode.derealization = derealization
        episode.racingThoughts = racingThoughts
        
        // Context
        episode.location = location
        episode.trigger = trigger
        episode.timeOfDay = timeOfDay
        episode.aloneOrWithOthers = aloneOrWithOthers
        
        // Convert sets to Realm lists
        episode.copingStrategiesUsed.append(objectsIn: selectedCopingStrategies)
        episode.afterEffects.append(objectsIn: selectedAfterEffects)
        
        // Notes
        episode.notes = notes
        
        // Calculate duration (for now, just time spent in tracker)
        episode.duration = Date().timeIntervalSince(episode.timestamp)
        
        try? realm.write {
            realm.add(episode)
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

// MARK: - Step: Intensity
struct IntensityStep: View {
    let title: String
    let subtitle: String
    @Binding var value: Int
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            // Visual intensity scale
            VStack(spacing: 12) {
                Text("\(value)")
                    .font(.system(size: 56, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(intensityColor(value))
                
                Text(intensityLabel(value))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black.opacity(0.7))
                
                Slider(value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ), in: 0...10, step: 1)
                .tint(intensityColor(value))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                
                // Number buttons
                HStack(spacing: 5) {
                    ForEach(0...10, id: \.self) { num in
                        Button(action: { value = num }) {
                            Text("\(num)")
                                .font(.system(size: 12, weight: value == num ? .bold : .regular))
                                .foregroundColor(value == num ? .white : .black.opacity(0.6))
                                .frame(width: 26, height: 26)
                                .background(value == num ? intensityColor(num) : Color.black.opacity(0.05))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        }
    }
    
    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 0: return .gray
        case 1...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .purple
        }
    }
    
    private func intensityLabel(_ intensity: Int) -> String {
        switch intensity {
        case 0: return "No panic"
        case 1...2: return "Mild discomfort"
        case 3...4: return "Moderate anxiety"
        case 5...6: return "Strong panic"
        case 7...8: return "Severe panic"
        case 9...10: return "Extreme panic"
        default: return ""
        }
    }
}

// MARK: - Step: Physical Symptoms
struct PhysicalSymptomsStep: View {
    @Binding var heartRate: Int
    @Binding var breathingDifficulty: Int
    @Binding var chestTightness: Int
    @Binding var sweating: Int
    @Binding var trembling: Int
    @Binding var dizziness: Int
    @Binding var nausea: Int
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Physical Symptoms")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Rate how intense each symptom is")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            VStack(spacing: 16) {
                SymptomRow(icon: "heart.fill", label: "Heart Racing", value: $heartRate)
                SymptomRow(icon: "wind", label: "Hard to Breathe", value: $breathingDifficulty)
                SymptomRow(icon: "lungs.fill", label: "Chest Tightness", value: $chestTightness)
                SymptomRow(icon: "drop.fill", label: "Sweating", value: $sweating)
                SymptomRow(icon: "hand.raised.fill", label: "Trembling/Shaking", value: $trembling)
                SymptomRow(icon: "circle.hexagongrid.circle.fill", label: "Dizziness", value: $dizziness)
                SymptomRow(icon: "pills.fill", label: "Nausea", value: $nausea)
            }
        }
    }
}

// MARK: - Step: Cognitive Symptoms
struct CognitiveSymptomsStep: View {
    @Binding var fearOfDying: Int
    @Binding var fearOfLosingControl: Int
    @Binding var derealization: Int
    @Binding var racingThoughts: Int
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Mental Symptoms")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Rate how intense each feeling is")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            VStack(spacing: 16) {
                SymptomRow(icon: "heart.slash.fill", label: "Fear of Dying", value: $fearOfDying)
                SymptomRow(icon: "brain.head.profile", label: "Fear of Losing Control", value: $fearOfLosingControl)
                SymptomRow(icon: "eye.trianglebadge.exclamationmark.fill", label: "Feeling Unreal", value: $derealization)
                SymptomRow(icon: "bolt.fill", label: "Racing Thoughts", value: $racingThoughts)
            }
        }
    }
}

// MARK: - Symptom Row Component
struct SymptomRow: View {
    let icon: String
    let label: String
    @Binding var value: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                    .frame(width: 24)
                
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(value)")
                    .font(.system(size: 16, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(value > 0 ? .purple : .black.opacity(0.3))
                    .frame(width: 24)
            }
            
            HStack(spacing: 4) {
                ForEach(0...10, id: \.self) { num in
                    Button(action: { value = num }) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(num <= value ? Color.purple : Color.black.opacity(0.1))
                            .frame(height: 8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Step: Context
struct ContextStep: View {
    @Binding var location: String
    @Binding var trigger: String
    @Binding var timeOfDay: String
    @Binding var aloneOrWithOthers: String
    
    let locations = ["Home", "Work", "Public Place", "Transport", "Social Event", "Other"]
    let timesOfDay = ["Morning", "Afternoon", "Evening", "Night"]
    let socialContexts = ["Alone", "With Friends", "With Family", "With Strangers", "In Crowd"]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Context")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Help identify patterns and triggers")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 20) {
                // Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Where were you?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(locations, id: \.self) { loc in
                            ContextPill(
                                text: loc,
                                isSelected: location == loc,
                                action: { location = loc }
                            )
                        }
                    }
                }
                
                // Time of day
                VStack(alignment: .leading, spacing: 12) {
                    Text("What time of day?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(timesOfDay, id: \.self) { time in
                            ContextPill(
                                text: time,
                                isSelected: timeOfDay == time,
                                action: { timeOfDay = time }
                            )
                        }
                    }
                }
                
                // Social context
                VStack(alignment: .leading, spacing: 12) {
                    Text("Were you alone or with others?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(socialContexts, id: \.self) { context in
                            ContextPill(
                                text: context,
                                isSelected: aloneOrWithOthers == context,
                                action: { aloneOrWithOthers = context }
                            )
                        }
                    }
                }
                
                // Trigger
                VStack(alignment: .leading, spacing: 12) {
                    Text("Known trigger (optional)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                    
                    ZStack(alignment: .leading) {
                        if trigger.isEmpty {
                            Text("e.g., crowded space, argument, health concern")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.black.opacity(0.4))
                                .padding(.horizontal, 12)
                        }
                        TextField("", text: $trigger)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, design: .serif))
                            .padding(12)
                            .foregroundColor(.black)
                            .submitLabel(.done)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
        }
    }
}

// MARK: - Context Pill Component
struct ContextPill: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .black.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.white)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        }
    }
}

// MARK: - Step: Coping Strategies
struct CopingStrategiesStep: View {
    @Binding var selectedStrategies: Set<String>
    
    let strategies = [
        "Deep Breathing",
        "4-7-8 Breathing",
        "Box Breathing",
        "Grounding (5-4-3-2-1)",
        "Progressive Muscle Relaxation",
        "Cold Water",
        "Movement/Walking",
        "Called Someone",
        "Meditation",
        "Positive Affirmations",
        "Distraction",
        "Left the Situation",
        "Medication",
        "Nothing - Rode it Out"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Coping Strategies")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("What did you try? (Select all that apply)")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(strategies, id: \.self) { strategy in
                    ContextPill(
                        text: strategy,
                        isSelected: selectedStrategies.contains(strategy),
                        action: {
                            if selectedStrategies.contains(strategy) {
                                selectedStrategies.remove(strategy)
                            } else {
                                selectedStrategies.insert(strategy)
                            }
                        }
                    )
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
        }
    }
}

// MARK: - Step: Final
struct FinalStep: View {
    @Binding var finalIntensity: Int
    @Binding var selectedAfterEffects: Set<String>
    @Binding var notes: String
    @FocusState private var isNotesFocused: Bool
    
    let afterEffects = ["Fatigue", "Headache", "Muscle Tension", "Emotional", "Brain Fog", "None"]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Almost Done")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Just a couple more questions")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
            }
            
            VStack(alignment: .leading, spacing: 16) {
                // Current intensity
                VStack(alignment: .leading, spacing: 10) {
                    Text("Current intensity (0-10)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    HStack(spacing: 5) {
                        ForEach(0...10, id: \.self) { num in
                            Button(action: { 
                                finalIntensity = num
                                isNotesFocused = false
                            }) {
                                Text("\(num)")
                                    .font(.system(size: 12, weight: finalIntensity == num ? .bold : .regular))
                                    .foregroundColor(finalIntensity == num ? .white : .black.opacity(0.6))
                                    .frame(width: 26, height: 26)
                                    .background(finalIntensity == num ? Color.purple : Color.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                
                // After effects
                VStack(alignment: .leading, spacing: 10) {
                    Text("Any after-effects?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(afterEffects, id: \.self) { effect in
                            ContextPill(
                                text: effect,
                                isSelected: selectedAfterEffects.contains(effect),
                                action: {
                                    if selectedAfterEffects.contains(effect) {
                                        selectedAfterEffects.remove(effect)
                                    } else {
                                        selectedAfterEffects.insert(effect)
                                    }
                                    isNotesFocused = false
                                }
                            )
                        }
                    }
                }
                
                // Notes
                VStack(alignment: .leading, spacing: 10) {
                    Text("Additional notes (optional)")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                    
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("e.g., what helped, what made it worse, triggers...")
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.black.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                        }
                        TextField("", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, design: .serif))
                            .lineLimit(3...5)
                            .padding(12)
                            .foregroundColor(.black)
                            .focused($isNotesFocused)
                            .onSubmit {
                                isNotesFocused = false
                            }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.5))
            .cornerRadius(16)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isNotesFocused = false
        }
    }
}

// MARK: - Episode Detail View
struct EpisodeDetailView: View {
    @Environment(\.dismiss) var dismiss
    let episode: PanicEpisode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.95, blue: 0.98),
                    Color(red: 0.92, green: 0.92, blue: 0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.black.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("Episode Details")
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    Color.clear.frame(width: 28, height: 28)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Timestamp
                        VStack(spacing: 4) {
                            Text(episode.timestamp.formatted(date: .long, time: .omitted))
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.black)
                            
                            Text(episode.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 15))
                                .foregroundColor(.black.opacity(0.6))
                        }
                        .padding(.top, 10)
                        
                        // Intensity journey
                        IntensityJourneyView(episode: episode)
                        
                        // Physical symptoms
                        if hasPhysicalSymptoms {
                            DetailSection(title: "Physical Symptoms", icon: "heart.fill") {
                                VStack(spacing: 8) {
                                    if episode.heartRate > 0 {
                                        DetailRow(label: "Heart Racing", value: episode.heartRate)
                                    }
                                    if episode.breathingDifficulty > 0 {
                                        DetailRow(label: "Breathing Difficulty", value: episode.breathingDifficulty)
                                    }
                                    if episode.chestTightness > 0 {
                                        DetailRow(label: "Chest Tightness", value: episode.chestTightness)
                                    }
                                    if episode.sweating > 0 {
                                        DetailRow(label: "Sweating", value: episode.sweating)
                                    }
                                    if episode.trembling > 0 {
                                        DetailRow(label: "Trembling", value: episode.trembling)
                                    }
                                    if episode.dizziness > 0 {
                                        DetailRow(label: "Dizziness", value: episode.dizziness)
                                    }
                                    if episode.nausea > 0 {
                                        DetailRow(label: "Nausea", value: episode.nausea)
                                    }
                                }
                            }
                        }
                        
                        // Cognitive symptoms
                        if hasCognitiveSymptoms {
                            DetailSection(title: "Mental Symptoms", icon: "brain.head.profile") {
                                VStack(spacing: 8) {
                                    if episode.fearOfDying > 0 {
                                        DetailRow(label: "Fear of Dying", value: episode.fearOfDying)
                                    }
                                    if episode.fearOfLosingControl > 0 {
                                        DetailRow(label: "Fear of Losing Control", value: episode.fearOfLosingControl)
                                    }
                                    if episode.derealization > 0 {
                                        DetailRow(label: "Feeling Unreal", value: episode.derealization)
                                    }
                                    if episode.racingThoughts > 0 {
                                        DetailRow(label: "Racing Thoughts", value: episode.racingThoughts)
                                    }
                                }
                            }
                        }
                        
                        // Context
                        DetailSection(title: "Context", icon: "location.fill") {
                            VStack(spacing: 12) {
                                if !episode.location.isEmpty {
                                    HStack {
                                        Text("Location:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.6))
                                        Spacer()
                                        Text(episode.location)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                }
                                if !episode.timeOfDay.isEmpty {
                                    HStack {
                                        Text("Time of Day:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.6))
                                        Spacer()
                                        Text(episode.timeOfDay)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                }
                                if !episode.aloneOrWithOthers.isEmpty {
                                    HStack {
                                        Text("Social Context:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.6))
                                        Spacer()
                                        Text(episode.aloneOrWithOthers)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                }
                                if !episode.trigger.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Trigger:")
                                            .font(.system(size: 14))
                                            .foregroundColor(.black.opacity(0.6))
                                        Text(episode.trigger)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.black)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        
                        // Coping strategies
                        if !episode.copingStrategiesUsed.isEmpty {
                            DetailSection(title: "Coping Strategies", icon: "heart.circle.fill") {
                                FlowLayout(spacing: 8) {
                                    ForEach(Array(episode.copingStrategiesUsed), id: \.self) { strategy in
                                        Text(strategy)
                                            .font(.system(size: 13))
                                            .foregroundColor(.purple)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.purple.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // After effects
                        if !episode.afterEffects.isEmpty {
                            DetailSection(title: "After-Effects", icon: "moon.zzz.fill") {
                                FlowLayout(spacing: 8) {
                                    ForEach(Array(episode.afterEffects), id: \.self) { effect in
                                        Text(effect)
                                            .font(.system(size: 13))
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Notes
                        if !episode.notes.isEmpty {
                            DetailSection(title: "Notes", icon: "note.text") {
                                Text(episode.notes)
                                    .font(.system(size: 14))
                                    .foregroundColor(.black.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    private var hasPhysicalSymptoms: Bool {
        episode.heartRate > 0 || episode.breathingDifficulty > 0 ||
        episode.chestTightness > 0 || episode.sweating > 0 ||
        episode.trembling > 0 || episode.dizziness > 0 || episode.nausea > 0
    }
    
    private var hasCognitiveSymptoms: Bool {
        episode.fearOfDying > 0 || episode.fearOfLosingControl > 0 ||
        episode.derealization > 0 || episode.racingThoughts > 0
    }
}

// MARK: - Intensity Journey View
struct IntensityJourneyView: View {
    let episode: PanicEpisode
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Intensity Journey")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                IntensityBadge(label: "Initial", value: episode.initialIntensity)
                Image(systemName: "arrow.right")
                    .foregroundColor(.black.opacity(0.3))
                IntensityBadge(label: "Peak", value: episode.peakIntensity)
                Image(systemName: "arrow.right")
                    .foregroundColor(.black.opacity(0.3))
                IntensityBadge(label: "Final", value: episode.finalIntensity)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

struct IntensityBadge: View {
    let label: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(value)")
                .font(.system(size: 28, weight: .bold))
                .fontDesign(.rounded)
                .foregroundColor(intensityColor(value))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.black.opacity(0.6))
        }
    }
    
    private func intensityColor(_ intensity: Int) -> Color {
        switch intensity {
        case 0...3: return .green
        case 4...6: return .orange
        case 7...8: return .red
        default: return .purple
        }
    }
}

// MARK: - Detail Section
struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.purple)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            content
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.7))
            
            Spacer()
            
            HStack(spacing: 2) {
                ForEach(1...10, id: \.self) { index in
                    Circle()
                        .fill(index <= value ? Color.purple : Color.black.opacity(0.1))
                        .frame(width: 8, height: 8)
                }
            }
            
            Text("\(value)/10")
                .font(.system(size: 14, weight: .semibold))
                .fontDesign(.monospaced)
                .foregroundColor(.black)
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    PanicScaleView()
        .environmentObject(AuthManager())
}

