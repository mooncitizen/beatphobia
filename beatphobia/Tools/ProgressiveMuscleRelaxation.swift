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
    
    func resume() {
        guard !isActive else { return }
        isActive = true
        startPhaseTimer()
        
        if hapticsEnabled {
            mediumHaptic.impactOccurred()
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
        phaseDuration = 5.0
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
        phaseDuration = 3.0
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
    @StateObject private var pmrManager = PMRManager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            if pmrManager.isCompleted {
                completionView
            } else {
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Main content in ScrollView
                    ScrollView {
                        VStack(spacing: 32) {
                            mainContentView
                                .padding(.top, 20)
                            
                            // Controls
                            controlsView
                                .padding(.bottom, 40)
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
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
                if pmrManager.hapticsEnabled {
                    pmrManager.lightHaptic.impactOccurred(intensity: 0.5)
                }
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black.opacity(0.7))
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("PMR")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("\(pmrManager.groupsCompleted) of \(pmrManager.totalGroups) groups")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.6))
            }
            
            Spacer()
            
            // Balance spacer
            Color.clear
                .frame(width: 28, height: 28)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 32) {
            // Overall progress bar
            overallProgressView
            
            // Phase indicator
            phaseIndicatorView
            
            // Current muscle group card
            muscleGroupCardView
            
            // Phase-specific guidance
            guidanceView
        }
        .padding(.horizontal, 20)
    }
    
    private var overallProgressView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Overall Progress")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                
                Spacer()
                
                Text("\(Int(pmrManager.overallProgress * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(AppConstants.primaryColor)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppConstants.primaryColor.opacity(0.1))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppConstants.primaryColor,
                                    AppConstants.primaryColor.opacity(0.7)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * pmrManager.overallProgress)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var phaseIndicatorView: some View {
        HStack(spacing: 12) {
            // Phase icon
            ZStack {
                Circle()
                    .fill(pmrManager.currentPhase.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: phaseIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(pmrManager.currentPhase.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pmrManager.currentPhase.title)
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(pmrManager.currentPhase.color)
                
                if pmrManager.isActive && pmrManager.currentPhase != .completed {
                    Text("\(Int(pmrManager.timeRemaining))s remaining")
                        .font(.system(size: 14, weight: .medium))
                        .fontDesign(.monospaced)
                        .foregroundColor(pmrManager.currentPhase.color.opacity(0.7))
                }
            }
            
            Spacer()
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
    
    private var muscleGroupCardView: some View {
        ZStack {
            cardBackground
            cardBorder
            cardContent
        }
        .frame(height: 400)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(pmrManager.currentPhase.color.opacity(0.1))
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 24)
            .stroke(
                pmrManager.currentPhase.color.opacity(pmrManager.isActive ? 0.5 : 0.3),
                lineWidth: 3
            )
    }
    
    private var cardContent: some View {
        VStack(spacing: 20) {
            muscleGroupIcon
            muscleGroupName
            
            if pmrManager.currentPhase == .ready || pmrManager.currentPhase == .tense {
                instructionText
            }
            
            if pmrManager.isActive && pmrManager.currentPhase != .completed {
                phaseProgressRing
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 30)
    }
    
    private var muscleGroupIcon: some View {
        ZStack {
            Circle()
                .fill(pmrManager.currentPhase.color.opacity(0.15))
                .frame(width: 100, height: 100)
                .scaleEffect(pmrManager.currentPhase == .tense && pmrManager.isActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: pmrManager.isActive && pmrManager.currentPhase == .tense)
            
            Image(systemName: pmrManager.currentGroup.icon)
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(pmrManager.currentPhase.color)
        }
    }
    
    private var muscleGroupName: some View {
        Text(pmrManager.currentGroup.name)
            .font(.system(size: 28, weight: .bold))
            .fontDesign(.serif)
            .foregroundColor(AppConstants.primaryColor)
    }
    
    private var instructionText: some View {
        Text(pmrManager.currentGroup.instruction)
            .font(.system(size: 16))
            .foregroundColor(AppConstants.primaryColor.opacity(0.8))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
    }
    
    private var phaseProgressRing: some View {
        ZStack {
            Circle()
                .stroke(pmrManager.currentPhase.color.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: pmrManager.progress)
                .stroke(
                    pmrManager.currentPhase.color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(pmrManager.timeRemaining))")
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(pmrManager.currentPhase.color)
        }
    }
    
    private var guidanceView: some View {
        VStack(spacing: 12) {
            if pmrManager.currentPhase == .ready {
                guidanceText("Prepare to tense your \(pmrManager.currentGroup.name.lowercased())", icon: "hand.raised.circle")
            } else if pmrManager.currentPhase == .tense {
                guidanceText("Hold the tension... breathe normally", icon: "hand.raised.circle.fill")
            } else if pmrManager.currentPhase == .relax {
                guidanceText("Let go completely... feel the difference", icon: "leaf.circle.fill")
            } else if pmrManager.currentPhase == .transition {
                guidanceText("Notice how relaxed your muscles feel", icon: "sparkles.rectangle.stack")
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func guidanceText(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(pmrManager.currentPhase.color)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppConstants.primaryColor.opacity(0.8))
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(pmrManager.currentPhase.color.opacity(0.1))
        )
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 16) {
            if !pmrManager.isActive && pmrManager.groupsCompleted == 0 {
                startButton
            } else if pmrManager.isActive {
                activeControls
            } else if !pmrManager.isActive && pmrManager.groupsCompleted > 0 {
                resumeButton
            }
            
            if pmrManager.groupsCompleted > 0 && !pmrManager.isCompleted {
                resetButton
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var startButton: some View {
        Button(action: {
            pmrManager.start()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Begin Session")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(primaryGradient)
            .cornerRadius(16)
            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    private var activeControls: some View {
        HStack(spacing: 12) {
            pauseButton
            skipButton
        }
    }
    
    private var pauseButton: some View {
        Button(action: {
            pmrManager.pause()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Pause")
                    .font(.system(size: 16, weight: .bold))
                    .fontDesign(.serif)
            }
            .foregroundColor(AppConstants.primaryColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppConstants.primaryColor.opacity(0.1))
            )
        }
    }
    
    private var skipButton: some View {
        Button(action: {
            pmrManager.skip()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Skip")
                    .font(.system(size: 16, weight: .bold))
                    .fontDesign(.serif)
            }
            .foregroundColor(AppConstants.primaryColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppConstants.primaryColor.opacity(0.1))
            )
        }
    }
    
    private var resumeButton: some View {
        Button(action: {
            pmrManager.resume()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                Text("Resume")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(primaryGradient)
            .cornerRadius(16)
            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, y: 4)
        }
    }
    
    private var resetButton: some View {
        Button(action: {
            pmrManager.reset()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Start Over")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
            }
            .foregroundColor(AppConstants.primaryColor.opacity(0.7))
            .frame(height: 44)
        }
    }
    
    private var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppConstants.primaryColor,
                AppConstants.primaryColor.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            successAnimation
            
            completionMessage
            
            statsCard
            
            Spacer()
            
            completionActions
        }
    }
    
    private var successAnimation: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 100/255, green: 180/255, blue: 140/255),
                            Color(red: 80/255, green: 160/255, blue: 120/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: Color(red: 100/255, green: 180/255, blue: 140/255).opacity(0.4), radius: 20)
            
            Image(systemName: "checkmark")
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var completionMessage: some View {
        VStack(spacing: 12) {
            Text("Session Complete!")
                .font(.system(size: 32, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryColor)
            
            Text("You've completed all \(pmrManager.totalGroups) muscle groups")
                .font(.system(size: 16))
                .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var statsCard: some View {
        statsCardContent
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppConstants.primaryColor.opacity(0.1))
            )
            .padding(.horizontal, 20)
    }
    
    private var statsCardContent: some View {
        HStack(spacing: 20) {
            statItem(value: "\(pmrManager.totalGroups)", label: "Groups")
            statDivider
            statItem(value: "~\(Int((7 + 20) * Double(pmrManager.totalGroups) / 60))m", label: "Duration")
            statDivider
            statItem(value: "100%", label: "Complete")
        }
    }
    
    private var statDivider: some View {
        Divider()
            .frame(height: 40)
            .background(AppConstants.primaryColor.opacity(0.3))
    }
    
    private var completionActions: some View {
        VStack(spacing: 12) {
            Button(action: {
                pmrManager.reset()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Do Another Session")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.serif)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [
                            AppConstants.primaryColor,
                            AppConstants.primaryColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, y: 4)
            }
            
            Button(action: {
                if pmrManager.hapticsEnabled {
                    pmrManager.lightHaptic.impactOccurred(intensity: 0.5)
                }
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                    .frame(height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryColor)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppConstants.primaryColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProgressiveMuscleRelaxationView()
}

