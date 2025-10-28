//
//  ProgressiveMuscleRelaxation.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import Combine

// MARK: - Muscle Group Model
struct MuscleGroup: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let instruction: String
    let tenseDuration: TimeInterval = 7.0
    let relaxDuration: TimeInterval = 20.0
}

// MARK: - PMR Phase
enum PMRPhase {
    case ready
    case tense
    case relax
    case transition
    case completed
    
    var color: Color {
        switch self {
        case .ready: return AppConstants.primaryColor
        case .tense: return Color(red: 220/255, green: 100/255, blue: 100/255)
        case .relax: return Color(red: 100/255, green: 180/255, blue: 140/255)
        case .transition: return AppConstants.primaryColor.opacity(0.6)
        case .completed: return Color(red: 100/255, green: 180/255, blue: 140/255)
        }
    }
    
    var title: String {
        switch self {
        case .ready: return "Get Ready"
        case .tense: return "Tense"
        case .relax: return "Release & Relax"
        case .transition: return "Prepare Next"
        case .completed: return "Complete"
        }
    }
}

// MARK: - PMR Manager
class PMRManager: ObservableObject {
    @Published var isActive = false
    @Published var currentPhase: PMRPhase = .ready
    @Published var currentGroupIndex = 0
    @Published var timeRemaining: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var groupsCompleted = 0
    @Published var isCompleted = false
    
    let muscleGroups: [MuscleGroup] = [
        MuscleGroup(
            name: "Feet",
            icon: "figure.walk",
            instruction: "Curl your toes downward and squeeze tightly"
        ),
        MuscleGroup(
            name: "Calves",
            icon: "figure.walk",
            instruction: "Pull your toes toward your shins and flex"
        ),
        MuscleGroup(
            name: "Thighs",
            icon: "figure.stand",
            instruction: "Squeeze your thigh muscles together tightly"
        ),
        MuscleGroup(
            name: "Buttocks",
            icon: "figure.stand",
            instruction: "Clench your buttocks firmly together"
        ),
        MuscleGroup(
            name: "Abdomen",
            icon: "figure.core.training",
            instruction: "Tighten your stomach muscles, pull them in"
        ),
        MuscleGroup(
            name: "Chest",
            icon: "heart.fill",
            instruction: "Take a deep breath and hold, tighten chest"
        ),
        MuscleGroup(
            name: "Back",
            icon: "figure.flexibility",
            instruction: "Arch your back slightly and squeeze shoulder blades"
        ),
        MuscleGroup(
            name: "Hands",
            icon: "hand.raised.fill",
            instruction: "Make tight fists with both hands"
        ),
        MuscleGroup(
            name: "Arms",
            icon: "figure.strengthtraining.traditional",
            instruction: "Flex your biceps and tense your entire arms"
        ),
        MuscleGroup(
            name: "Shoulders",
            icon: "figure.strengthtraining.traditional",
            instruction: "Raise your shoulders up toward your ears"
        ),
        MuscleGroup(
            name: "Neck",
            icon: "figure.mind.and.body",
            instruction: "Gently press your head back into support"
        ),
        MuscleGroup(
            name: "Face",
            icon: "face.smiling",
            instruction: "Scrunch your entire face together tightly"
        )
    ]
    
    var currentGroup: MuscleGroup {
        muscleGroups[min(currentGroupIndex, muscleGroups.count - 1)]
    }
    
    var totalGroups: Int {
        muscleGroups.count
    }
    
    var overallProgress: Double {
        Double(groupsCompleted) / Double(totalGroups)
    }
    
    // Haptics
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    let successHaptic = UINotificationFeedbackGenerator()
    var hapticsEnabled = true
    
    private var timer: AnyCancellable?
    private var phaseStartTime: Date?
    private var phaseDuration: TimeInterval = 0
    
    func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        successHaptic.prepare()
    }
    
    func start() {
        guard !isActive else { return }
        isActive = true
        currentGroupIndex = 0
        groupsCompleted = 0
        isCompleted = false
        startReadyPhase()
        
        if hapticsEnabled {
            mediumHaptic.impactOccurred()
        }
    }
    
    func pause() {
        isActive = false
        timer?.cancel()
        timer = nil
        
        if hapticsEnabled {
            lightHaptic.impactOccurred()
        }
    }
    
    func reset() {
        pause()
        currentGroupIndex = 0
        currentPhase = .ready
        groupsCompleted = 0
        timeRemaining = 0
        progress = 0
        isCompleted = false
        
        if hapticsEnabled {
            lightHaptic.impactOccurred()
        }
    }
    
    func skip() {
        if hapticsEnabled {
            lightHaptic.impactOccurred()
        }
        
        moveToNextGroup()
    }
    
    private func startReadyPhase() {
        currentPhase = .ready
        phaseDuration = 3.0
        timeRemaining = phaseDuration
        phaseStartTime = Date()
        progress = 0
        startPhaseTimer()
    }
    
    private func startTensePhase() {
        currentPhase = .tense
        phaseDuration = currentGroup.tenseDuration
        timeRemaining = phaseDuration
        phaseStartTime = Date()
        progress = 0
        
        if hapticsEnabled {
            mediumHaptic.impactOccurred()
        }
        
        // Countdown haptics at 3, 2, 1
        DispatchQueue.main.asyncAfter(deadline: .now() + (phaseDuration - 3)) {
            if self.currentPhase == .tense && self.hapticsEnabled {
                self.lightHaptic.impactOccurred(intensity: 0.3)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (phaseDuration - 2)) {
            if self.currentPhase == .tense && self.hapticsEnabled {
                self.lightHaptic.impactOccurred(intensity: 0.5)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + (phaseDuration - 1)) {
            if self.currentPhase == .tense && self.hapticsEnabled {
                self.lightHaptic.impactOccurred(intensity: 0.7)
            }
        }
        
        startPhaseTimer()
    }
    
    private func startRelaxPhase() {
        currentPhase = .relax
        phaseDuration = currentGroup.relaxDuration
        timeRemaining = phaseDuration
        phaseStartTime = Date()
        progress = 0
        
        if hapticsEnabled {
            heavyHaptic.impactOccurred(intensity: 1.0)
        }
        
        startPhaseTimer()
    }
    
    private func startTransitionPhase() {
        currentPhase = .transition
        phaseDuration = 2.0
        timeRemaining = phaseDuration
        phaseStartTime = Date()
        progress = 0
        
        if hapticsEnabled {
            lightHaptic.impactOccurred()
        }
        
        startPhaseTimer()
    }
    
    private func startPhaseTimer() {
        timer?.cancel()
        
        timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimer()
            }
    }
    
    private func updateTimer() {
        guard isActive, let startTime = phaseStartTime else { return }
        
        let elapsed = Date().timeIntervalSince(startTime)
        timeRemaining = max(0, phaseDuration - elapsed)
        progress = min(1.0, elapsed / phaseDuration)
        
        if timeRemaining <= 0 {
            phaseDidComplete()
        }
    }
    
    private func phaseDidComplete() {
        switch currentPhase {
        case .ready:
            startTensePhase()
        case .tense:
            startRelaxPhase()
        case .relax:
            groupsCompleted += 1
            if currentGroupIndex < muscleGroups.count - 1 {
                startTransitionPhase()
            } else {
                completeSession()
            }
        case .transition:
            moveToNextGroup()
        case .completed:
            break
        }
    }
    
    private func moveToNextGroup() {
        if currentGroupIndex < muscleGroups.count - 1 {
            currentGroupIndex += 1
            startReadyPhase()
        } else {
            completeSession()
        }
    }
    
    private func completeSession() {
        currentPhase = .completed
        isCompleted = true
        isActive = false
        timer?.cancel()
        timer = nil
        
        if hapticsEnabled {
            successHaptic.notificationOccurred(.success)
        }
    }
}

// MARK: - Main View
struct ProgressiveMuscleRelaxationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var pmrManager = PMRManager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Always visible
                headerView
                
                Spacer()
                
                // Main content
                if pmrManager.isCompleted {
                    completionView
                } else {
                    mainContentView
                }
                
                Spacer()
                
                // Bottom controls - Always visible
                bottomControlsView
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            pmrManager.prepareHaptics()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                pmrManager.pause()
                if pmrManager.hapticsEnabled {
                    pmrManager.lightHaptic.impactOccurred(intensity: 0.5)
                }
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppConstants.cardBackgroundColor(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, y: 2)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
            }
            .opacity(pmrManager.isActive ? 0.3 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Progressive Muscle Relaxation")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if pmrManager.groupsCompleted > 0 {
                    Text("\(pmrManager.groupsCompleted) of \(pmrManager.totalGroups) groups")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Stop button - minimal style
            if pmrManager.isActive {
                Button(action: {
                    pmrManager.pause()
                }) {
                    Text("Stop")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.7))
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 32) {
            // Phase indicator
            let currentPhase = pmrManager.currentPhase
            
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(currentPhase.color.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: phaseIcon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(currentPhase.color)
                }
                
                Text(currentPhase.title)
                    .font(.system(size: 28, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(currentPhase.color)
                
                if pmrManager.isActive {
                    Text("\(Int(pmrManager.timeRemaining)) seconds")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 32)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
            
            // Muscle group card
            VStack(spacing: 16) {
                Text(pmrManager.currentGroup.name)
                    .font(.system(size: 36, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(pmrManager.currentGroup.instruction)
                    .font(.system(size: 18))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
        }
    }
    
    private var phaseIcon: String {
        switch pmrManager.currentPhase {
        case .ready: return "hand.raised.circle.fill"
        case .tense: return "hand.raised.fill"
        case .relax: return "leaf.fill"
        case .transition: return "arrow.right.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            if !pmrManager.isActive && pmrManager.groupsCompleted == 0 {
                Button(action: {
                    pmrManager.start()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Start Session")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: AppConstants.primaryColor.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            } else if pmrManager.isActive {
                Button(action: {
                    pmrManager.pause()
                }) {
                    Text("Pause")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 220/255, green: 100/255, blue: 100/255), Color(red: 200/255, green: 80/255, blue: 80/255).opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(red: 220/255, green: 100/255, blue: 100/255).opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            } else if !pmrManager.isActive && pmrManager.groupsCompleted > 0 {
                Button(action: {
                    pmrManager.start()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Resume")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: AppConstants.primaryColor.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            }
            
            if pmrManager.groupsCompleted > 0 && !pmrManager.isCompleted {
                Button(action: {
                    pmrManager.reset()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reset")
                            .font(.system(size: 16, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.7))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Session Complete!")
                    .font(.system(size: 32, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("You've completed all \(pmrManager.totalGroups) muscle groups")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                statCard(value: "\(pmrManager.totalGroups)", label: "Groups")
                statCard(value: "~\(Int((7 + 20) * Double(pmrManager.totalGroups) / 60))m", label: "Duration")
                statCard(value: "100%", label: "Complete")
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryColor)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
    }
}

#Preview {
    ProgressiveMuscleRelaxationView()
}
