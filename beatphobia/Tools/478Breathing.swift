//
//  478Breathing.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import Combine

struct Breathing478View: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var breathingManager = Breathing478Manager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                // Main content
                if breathingManager.showStartCountdown {
                    startCountdownView
                } else {
                    mainBreathingView
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
            breathingManager.prepareHaptics()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                breathingManager.pauseBreathing()
                if breathingManager.hapticsEnabled {
                    breathingManager.lightHaptic.impactOccurred(intensity: 0.5)
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
            .opacity(breathingManager.isBreathing ? 0.3 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("4-7-8 Breathing")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if breathingManager.cyclesCompleted > 0 {
                    Text("Cycle \(breathingManager.cyclesCompleted)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Stop button - minimal style
            if breathingManager.isBreathing {
                Button(action: {
                    breathingManager.pauseBreathing()
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
    
    // MARK: - Start Countdown View
    private var startCountdownView: some View {
        VStack(spacing: 32) {
            Text("Get Ready")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            ZStack {
                // Background circle
                Circle()
                    .fill(breathingManager.currentPhaseColor.opacity(0.15))
                    .frame(width: 280, height: 280)
                
                // Countdown number
                Text("\(breathingManager.startCountdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(breathingManager.currentPhaseColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.default, value: breathingManager.startCountdown)
            }
        }
    }
    
    // MARK: - Main Breathing View
    private var mainBreathingView: some View {
        VStack(spacing: 40) {
            // Instruction Card
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: breathingManager.currentPhase.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(breathingManager.currentPhaseColor)
                    
                    Text(breathingManager.currentPhase.title)
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                
                Text("For \(breathingManager.currentPhase.duration) seconds")
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
            
            // Breathing circle - animated
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(breathingManager.currentPhaseColor.opacity(0.1))
                    .frame(width: breathingManager.circleSize, height: breathingManager.circleSize)
                    .blur(radius: 20)
                
                // Main circle
                Circle()
                    .fill(LinearGradient(
                        colors: [breathingManager.currentPhaseColor.opacity(0.9), breathingManager.currentPhaseColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: breathingManager.circleSize, height: breathingManager.circleSize)
                    .shadow(color: breathingManager.currentPhaseColor.opacity(0.4), radius: 15, y: 8)
                
                // Center content
                VStack(spacing: 8) {
                    Text("\(breathingManager.secondsRemaining)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.default, value: breathingManager.secondsRemaining)
                    
                    Text("seconds")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(height: 280)
            .animation(.easeInOut(duration: Double(breathingManager.currentPhase.duration)), value: breathingManager.circleSize)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Only show start button when NOT breathing
            if !breathingManager.isBreathing {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        breathingManager.toggleBreathing()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Start Breathing")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [breathingManager.currentPhaseColor, breathingManager.currentPhaseColor.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: breathingManager.currentPhaseColor.opacity(0.4), radius: 12, y: 6)
                }
                .disabled(breathingManager.showStartCountdown)
                .opacity(breathingManager.showStartCountdown ? 0.6 : 1.0)
                .padding(.horizontal, 32)
            }
            
            // Reset button
            if breathingManager.cyclesCompleted > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        breathingManager.reset()
                    }
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
                .disabled(breathingManager.showStartCountdown)
                .opacity(breathingManager.showStartCountdown ? 0.3 : 1.0)
            }
        }
    }
}

// MARK: - Breathing Manager
class Breathing478Manager: ObservableObject {
    @Published var currentPhase: Breathing478Phase = .inhale
    @Published var secondsRemaining: Int = 4
    @Published var isBreathing: Bool = false
    @Published var cyclesCompleted: Int = 0
    @Published var hapticsEnabled: Bool = true
    @Published var showStartCountdown: Bool = false
    @Published var startCountdown: Int = 3
    
    // Animation properties
    @Published var progress: Double = 0
    @Published var circleSize: CGFloat = 160
    @Published var isInBreak: Bool = false
    
    private var timer: Timer?
    private var startCountdownTimer: Timer?
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
        showStartCountdown = true
        startCountdown = 3
        startCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            self.mediumHaptic.impactOccurred(intensity: 0.7)
            self.startCountdown -= 1
            
            if self.startCountdown <= 0 {
                timer.invalidate()
                self.startCountdownTimer = nil
                self.showStartCountdown = false
                self.isBreathing = true
                self.startBreathing()
            }
        }
    }
    
    func pauseBreathing() {
        // Stop all timers
        timer?.invalidate()
        timer = nil
        startCountdownTimer?.invalidate()
        startCountdownTimer = nil
        
        // Reset state
        showStartCountdown = false
        isBreathing = false
        isInBreak = false
        
        // Stop haptics
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.5)
        }
    }
    
    private func startBreathing() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    private func tick() {
        // Don't tick during breaks - the timer should be paused
        guard !isInBreak else { 
            // If in break, just return without doing anything
            return 
        }
        
        secondsRemaining -= 1
        
        // Update progress
        let totalSeconds = Double(currentPhase.duration)
        let elapsed = totalSeconds - Double(secondsRemaining)
        progress = elapsed / totalSeconds
        
        // Animate circle based on phase
        animateForCurrentPhase()
        
        // Haptic feedback
        if hapticsEnabled {
            if secondsRemaining > 0 {
                lightHaptic.impactOccurred(intensity: 0.4)
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
                // Grow from 160 to 280 over 4 seconds
                let progress = Double(currentPhase.duration - secondsRemaining) / Double(currentPhase.duration)
                circleSize = 160 + CGFloat(progress * 120)
            case .hold:
                // Hold at max size 280 - no change, just stay
                circleSize = 280
            case .exhale:
                // Shrink from 280 to 160 over 8 seconds
                let progress = Double(currentPhase.duration - secondsRemaining) / Double(currentPhase.duration)
                circleSize = 280 - CGFloat(progress * 120)
            }
        }
    }
    
    private func moveToNextPhase() {
        if hapticsEnabled {
            switch currentPhase {
            case .inhale:
                mediumHaptic.impactOccurred(intensity: 0.8)
            case .hold:
                heavyHaptic.impactOccurred(intensity: 0.9)
            case .exhale:
                successHaptic.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.heavyHaptic.impactOccurred(intensity: 1.0)
                }
            }
        }
        
        // Add breaks between steps and STOP the timer
        // Inhale -> Hold: 1s, Hold -> Exhale: 1s, Exhale -> Inhale: 1s
        let breakDuration: Double = 1.0
        
        // Stop the timer during the break
        timer?.invalidate()
        timer = nil
        
        isInBreak = true
        DispatchQueue.main.asyncAfter(deadline: .now() + breakDuration) {
            self.isInBreak = false
            
            // Switch phase first
            withAnimation(.easeInOut(duration: 0.3)) {
                switch self.currentPhase {
                case .inhale:
                    self.currentPhase = .hold
                    self.circleSize = 280
                case .hold:
                    self.currentPhase = .exhale
                    self.circleSize = 280
                case .exhale:
                    self.currentPhase = .inhale
                    self.cyclesCompleted += 1
                    self.circleSize = 160
                }
                
                // Reset for new phase
                self.secondsRemaining = self.currentPhase.duration
                self.progress = 0
            }
            
            // Restart the timer after the break
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.tick()
            }
        }
    }
    
    func reset() {
        pauseBreathing()
        
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.5)
        }
        
        withAnimation(.spring(response: 0.5)) {
            currentPhase = .inhale
            secondsRemaining = currentPhase.duration
            cyclesCompleted = 0
            progress = 0
            circleSize = 160
            isInBreak = false
        }
    }
}

// MARK: - Breathing Phase
enum Breathing478Phase {
    case inhale
    case hold
    case exhale
    
    var duration: Int {
        switch self {
        case .inhale: return 4
        case .hold: return 7
        case .exhale: return 8
        }
    }
    
    var title: String {
        switch self {
        case .inhale: return "Breathe In"
        case .hold: return "Hold"
        case .exhale: return "Breathe Out"
        }
    }
    
    var icon: String {
        switch self {
        case .inhale: return "arrow.down.circle.fill"
        case .hold: return "pause.circle.fill"
        case .exhale: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .inhale: return AppConstants.primaryColor
        case .hold: return Color(red: 90/255, green: 159/255, blue: 212/255)
        case .exhale: return Color(red: 159/255, green: 127/255, blue: 169/255)
        }
    }
}

// MARK: - Preview
#Preview {
    Breathing478View()
}
