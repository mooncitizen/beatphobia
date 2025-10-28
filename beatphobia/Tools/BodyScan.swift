//
//  BodyScan.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI
import AVFoundation

struct BodyScanView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentStep: Int = 0
    @State private var isScanning: Bool = false
    @State private var isPaused: Bool = false
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    
    let bodyScanSteps: [BodyScanStep] = [
        BodyScanStep(bodyPart: "Toes", duration: 20, instruction: "Focus on your toes. Notice any sensations - warmth, coolness, tingling, or tension.", icon: "figure.walk"),
        BodyScanStep(bodyPart: "Feet", duration: 20, instruction: "Move your attention to your feet. Feel the surface beneath them. Notice any pressure or contact.", icon: "figure.walk"),
        BodyScanStep(bodyPart: "Ankles & Calves", duration: 25, instruction: "Bring awareness to your ankles and calves. Notice any tightness or relaxation in these muscles.", icon: "figure.walk"),
        BodyScanStep(bodyPart: "Knees & Thighs", duration: 25, instruction: "Focus on your knees and thighs. Observe any sensations without trying to change them.", icon: "figure.walk"),
        BodyScanStep(bodyPart: "Hips & Lower Back", duration: 30, instruction: "Notice your hips and lower back. This area often holds tension. Simply observe what you feel.", icon: "figure.stand"),
        BodyScanStep(bodyPart: "Abdomen", duration: 25, instruction: "Bring attention to your abdomen. Notice the gentle rise and fall with each breath.", icon: "lungs.fill"),
        BodyScanStep(bodyPart: "Chest & Heart", duration: 25, instruction: "Focus on your chest and heart area. Feel your heartbeat and the rhythm of your breathing.", icon: "heart.fill"),
        BodyScanStep(bodyPart: "Shoulders", duration: 25, instruction: "Notice your shoulders. Are they tense or relaxed? Simply observe without judgment.", icon: "figure.arms.open"),
        BodyScanStep(bodyPart: "Arms & Hands", duration: 25, instruction: "Bring awareness to your arms and hands. Notice any tingling, warmth, or other sensations.", icon: "hand.raised.fill"),
        BodyScanStep(bodyPart: "Neck & Throat", duration: 20, instruction: "Focus on your neck and throat. Feel the muscles supporting your head.", icon: "person.bust"),
        BodyScanStep(bodyPart: "Face & Jaw", duration: 20, instruction: "Notice your face and jaw. Many hold tension here. Simply observe the sensations.", icon: "face.smiling"),
        BodyScanStep(bodyPart: "Head & Crown", duration: 20, instruction: "Bring attention to the top of your head. Feel the weight and presence of your entire body.", icon: "brain.head.profile"),
        BodyScanStep(bodyPart: "Whole Body", duration: 30, instruction: "Now, expand your awareness to your entire body. Feel yourself as a complete, connected whole.", icon: "figure.stand")
    ]
    
    var currentBodyPart: BodyScanStep {
        bodyScanSteps[currentStep]
    }
    
    var totalDuration: Int {
        bodyScanSteps.reduce(0) { $0 + $1.duration }
    }
    
    var progress: Double {
        guard currentStep < bodyScanSteps.count else { return 1.0 }
        let completedDuration = bodyScanSteps.prefix(currentStep).reduce(0) { $0 + $1.duration }
        let currentProgress = min(elapsedTime, Double(currentBodyPart.duration))
        let totalCompleted = Double(completedDuration) + currentProgress
        return totalCompleted / Double(totalDuration)
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Always visible
                headerView
                
                Spacer()
                
                // Main content
                if isScanning {
                    scanningView
                } else {
                    mainScanView
                }
                
                Spacer()
                
                // Bottom controls - Always visible
                bottomControlsView
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if isScanning {
                    endScan()
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
            .opacity(isScanning ? 0.3 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Body Scan")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if isScanning {
                    Text("Step \(currentStep + 1) of \(bodyScanSteps.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Stop button - minimal style
            if isScanning {
                Button(action: {
                    endScan()
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
    
    // MARK: - Main Scan View (start screen)
    private var mainScanView: some View {
        VStack(spacing: 32) {
            // Duration info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppConstants.primaryColor.opacity(0.15))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 4) {
                        Text("\(totalDuration / 60)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                        
                        Text("minutes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
                
                Text("13 body areas to scan")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            
            // Body parts preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Body Areas")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(Array(bodyScanSteps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 8) {
                            Image(systemName: step.icon)
                                .font(.system(size: 12))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Text(step.bodyPart)
                                .font(.system(size: 13))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Scanning View
    private var scanningView: some View {
        VStack(spacing: 32) {
            // Current body part card
            VStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppConstants.primaryColor.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: currentBodyPart.icon)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                }
                
                // Body part name
                Text(currentBodyPart.bodyPart)
                    .font(.system(size: 36, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                // Instruction
                Text(currentBodyPart.instruction)
                    .font(.system(size: 17))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
            
            // Timer display
            Text(formatTime(elapsedTime))
                .font(.system(size: 48, weight: .bold))
                .fontDesign(.monospaced)
                .foregroundColor(AppConstants.primaryColor)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            if !isScanning {
                Button(action: startScan) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Start Body Scan")
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
            } else {
                Button(action: {
                    isPaused.toggle()
                    if isPaused {
                        timer?.invalidate()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(isPaused ? "Resume" : "Pause")
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
            }
        }
    }
    
    // MARK: - Actions
    private func startScan() {
        isScanning = true
        currentStep = 0
        elapsedTime = 0
        isPaused = false
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            
            // Check if current step is complete
            if elapsedTime >= Double(currentBodyPart.duration) {
                if currentStep < bodyScanSteps.count - 1 {
                    // Move to next step
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    currentStep += 1
                    elapsedTime = 0
                } else {
                    // Scan complete
                    completeScan()
                }
            }
        }
    }
    
    private func completeScan() {
        timer?.invalidate()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Complete and go back to start
        endScan()
    }
    
    private func endScan() {
        timer?.invalidate()
        isScanning = false
        currentStep = 0
        elapsedTime = 0
        isPaused = false
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Body Scan Step Model
struct BodyScanStep {
    let bodyPart: String
    let duration: Int // in seconds
    let instruction: String
    let icon: String
}

#Preview {
    BodyScanView()
}
