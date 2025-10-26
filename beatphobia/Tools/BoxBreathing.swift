//
//  BoxBreathing.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import Combine

struct BoxBreathingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var breathingManager = BreathingManager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                // Main breathing animation
                breathingAnimationView
                
                Spacer()
                
                // Controls
                controlsView
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            breathingManager.prepareHaptics()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if breathingManager.hapticsEnabled {
                    breathingManager.lightHaptic.impactOccurred(intensity: 0.5)
                }
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(AppConstants.primaryColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Box Breathing")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("\(breathingManager.cyclesCompleted) cycles completed")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.6))
            }
            
            Spacer()
            
            // Spacer for balance
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Breathing Animation
    private var breathingAnimationView: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    breathingManager.currentPhaseColor.opacity(0.2),
                    lineWidth: 2
                )
                .frame(width: 320, height: 320)
                .blur(radius: 15)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: breathingManager.progress)
                .stroke(
                    breathingManager.currentPhaseColor,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: breathingManager.progress)
            
            // Animated box (rotating square)
            RoundedRectangle(cornerRadius: 40)
                .stroke(
                    breathingManager.currentPhaseColor,
                    lineWidth: 3
                )
                .frame(
                    width: breathingManager.boxSize,
                    height: breathingManager.boxSize
                )
                .rotationEffect(.degrees(breathingManager.boxRotation))
                .shadow(color: breathingManager.currentPhaseColor.opacity(0.3), radius: 15)
            
            // Center content
            VStack(spacing: 16) {
                // Phase icon
                Image(systemName: breathingManager.currentPhase.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(AppConstants.primaryColor)
                    .scaleEffect(breathingManager.iconScale)
                
                // Phase text
                Text(breathingManager.currentPhase.title)
                    .font(.system(size: 28, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                // Timer
                Text("\(breathingManager.secondsRemaining)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(AppConstants.primaryColor)
                    .monospacedDigit()
                
                // Duration
                Text("\(breathingManager.phaseDuration)s")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.5))
            }
        }
    }
    
    // MARK: - Controls
    private var controlsView: some View {
        VStack(spacing: 24) {
            // Start/Pause button
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    breathingManager.toggleBreathing()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: breathingManager.isBreathing ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text(breathingManager.isBreathing ? "Pause" : "Start")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(breathingManager.currentPhaseColor)
                .cornerRadius(28)
                .shadow(color: breathingManager.currentPhaseColor.opacity(0.3), radius: 10, y: 5)
            }
            
            // Reset button
            if breathingManager.cyclesCompleted > 0 {
                Button(action: {
                    withAnimation {
                        breathingManager.reset()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16))
                        Text("Reset")
                            .font(.system(size: 16, weight: .medium))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Breathing Manager
class BreathingManager: ObservableObject {
    @Published var currentPhase: BreathingPhase = .inhale
    @Published var secondsRemaining: Int = 4
    @Published var isBreathing: Bool = false
    @Published var cyclesCompleted: Int = 0
    @Published var phaseDuration: Int = 4
    @Published var hapticsEnabled: Bool = true
    
    // Animation properties
    @Published var progress: Double = 0
    @Published var boxSize: CGFloat = 180
    @Published var boxRotation: Double = 0
    @Published var iconScale: CGFloat = 1.0
    
    private var timer: Timer?
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    let successHaptic = UINotificationFeedbackGenerator()
    
    var currentPhaseColor: Color {
        currentPhase.color
    }
    
    func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        heavyHaptic.prepare()
        successHaptic.prepare()
    }
    
    func toggleBreathing() {
        isBreathing.toggle()
        
        // Haptic feedback for button press
        if hapticsEnabled {
            if isBreathing {
                // Starting - uplifting double tap
                mediumHaptic.impactOccurred(intensity: 0.7)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    self.mediumHaptic.impactOccurred(intensity: 0.7)
                }
            } else {
                // Pausing - single gentle tap
                lightHaptic.impactOccurred(intensity: 0.6)
            }
        }
        
        if isBreathing {
            startBreathing()
        } else {
            pauseBreathing()
        }
    }
    
    private func startBreathing() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func pauseBreathing() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        secondsRemaining -= 1
        
        // Update progress
        let totalSeconds = Double(phaseDuration)
        let elapsed = totalSeconds - Double(secondsRemaining)
        progress = elapsed / totalSeconds
        
        // Animate properties based on phase
        animateForCurrentPhase()
        
        // Haptic feedback during countdown
        if hapticsEnabled {
            // Light pulse on each second (except the last)
            if secondsRemaining > 0 {
                lightHaptic.impactOccurred(intensity: 0.4)
            }
            
            // Stronger haptics for countdown (3, 2, 1)
            if secondsRemaining <= 3 && secondsRemaining > 0 {
                mediumHaptic.impactOccurred(intensity: 0.6)
            }
        }
        
        if secondsRemaining <= 0 {
            moveToNextPhase()
        }
    }
    
    private func animateForCurrentPhase() {
        withAnimation(.easeInOut(duration: 1.0)) {
            switch currentPhase {
            case .inhale:
                boxSize = 180 + (CGFloat(phaseDuration - secondsRemaining) * 15)
                iconScale = 1.0 + (Double(phaseDuration - secondsRemaining) * 0.05)
            case .hold1, .hold2:
                // Keep size steady
                break
            case .exhale:
                boxSize = 240 - (CGFloat(phaseDuration - secondsRemaining) * 15)
                iconScale = 1.2 - (Double(phaseDuration - secondsRemaining) * 0.05)
            }
        }
    }
    
    private func moveToNextPhase() {
        // Trigger haptics based on phase transition
        if hapticsEnabled {
            switch currentPhase {
            case .inhale:
                // Start of hold - medium haptic
                mediumHaptic.impactOccurred(intensity: 0.8)
            case .hold1:
                // Start of exhale - heavier haptic (important transition)
                heavyHaptic.impactOccurred(intensity: 0.9)
            case .exhale:
                // Start of hold - medium haptic
                mediumHaptic.impactOccurred(intensity: 0.8)
            case .hold2:
                // Completed full cycle - success haptic!
                successHaptic.notificationOccurred(.success)
                // Add a secondary haptic for emphasis
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.heavyHaptic.impactOccurred(intensity: 1.0)
                }
            }
        }
        
        // Move to next phase
        withAnimation(.easeInOut(duration: 0.5)) {
            switch currentPhase {
            case .inhale:
                currentPhase = .hold1
                boxSize = 240
            case .hold1:
                currentPhase = .exhale
            case .exhale:
                currentPhase = .hold2
                boxSize = 180
            case .hold2:
                currentPhase = .inhale
                cyclesCompleted += 1
            }
            
            // Rotate box
            boxRotation += 90
            
            // Reset for new phase
            secondsRemaining = phaseDuration
            progress = 0
            iconScale = 1.0
        }
    }
    
    func reset() {
        pauseBreathing()
        
        // Haptic feedback for reset
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.5)
        }
        
        withAnimation {
            currentPhase = .inhale
            secondsRemaining = phaseDuration
            isBreathing = false
            cyclesCompleted = 0
            progress = 0
            boxSize = 180
            boxRotation = 0
            iconScale = 1.0
        }
    }
}

// MARK: - Breathing Phase
enum BreathingPhase {
    case inhale
    case hold1
    case exhale
    case hold2
    
    var title: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold1: return "Hold"
        case .exhale: return "Breathe Out"
        case .hold2: return "Hold"
        }
    }
    
    var icon: String {
        switch self {
        case .inhale: return "arrow.down.circle"
        case .hold1: return "pause.circle"
        case .exhale: return "arrow.up.circle"
        case .hold2: return "pause.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .inhale: return AppConstants.primaryColor // Blue
        case .hold1: return Color(hex: "6B8CAE") // Light blue
        case .exhale: return Color(hex: "8B7355") // Warm brown
        case .hold2: return Color(hex: "9BA8B8") // Soft gray-blue
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    BoxBreathingView()
}
