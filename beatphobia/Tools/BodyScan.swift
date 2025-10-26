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
    @State private var currentStep: Int = 0
    @State private var isScanning: Bool = false
    @State private var showInstructions: Bool = false
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
            // Calming gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.3, blue: 0.5),
                    Color(red: 0.3, green: 0.2, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        timer?.invalidate()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if isScanning {
                        // Timer display
                        Text(formatTime(elapsedTime))
                            .font(.system(size: 16, weight: .bold))
                            .fontDesign(.monospaced)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showInstructions.toggle()
                    }) {
                        Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        if !isScanning {
                            VStack(spacing: 8) {
                                Text("Body Scan")
                                    .font(.system(size: 36, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundColor(.white)
                                
                                Text("Mindfully scan through your body to release tension")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        
                        // Instructions (if visible and not scanning)
                        if showInstructions && !isScanning {
                            instructionsCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Main Content
                        if !isScanning {
                            // Start Screen
                            startView
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        } else {
                            // Scanning View
                            scanningView
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.stand")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("How to Practice")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                BodyScanInfoRow(icon: "hand.point.up.left.fill", text: "Find a comfortable position - sitting or lying down")
                BodyScanInfoRow(icon: "eye.slash.fill", text: "Close your eyes or soften your gaze")
                BodyScanInfoRow(icon: "figure.mind.and.body", text: "Notice sensations without trying to change them")
                BodyScanInfoRow(icon: "wind", text: "Breathe naturally and stay present")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
    
    // MARK: - Start View
    private var startView: some View {
        VStack(spacing: 30) {
            // Duration info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    VStack(spacing: 4) {
                        Text("\(totalDuration / 60)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("minutes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text("13 body areas to scan")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 20)
            
            // Body parts preview
            VStack(alignment: .leading, spacing: 12) {
                Text("What You'll Scan")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(Array(bodyScanSteps.enumerated()), id: \.offset) { index, step in
                        HStack(spacing: 8) {
                            Image(systemName: step.icon)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(step.bodyPart)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            
            // Start button
            Button(action: startScan) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Begin Body Scan")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.purple.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Scanning View
    private var scanningView: some View {
        VStack(spacing: 40) {
            // Progress bar
            VStack(spacing: 12) {
                HStack {
                    Text("Step \(currentStep + 1) of \(bodyScanSteps.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(.white)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 12)
                    }
                }
                .frame(height: 12)
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            
            // Current body part
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: currentBodyPart.icon)
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Body part name
                Text(currentBodyPart.bodyPart)
                    .font(.system(size: 36, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
                
                // Instruction
                Text(currentBodyPart.instruction)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 30)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 30)
            
            // Control buttons
            HStack(spacing: 16) {
                Button(action: {
                    isPaused.toggle()
                    if isPaused {
                        timer?.invalidate()
                    } else {
                        startTimer()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24, weight: .semibold))
                        
                        Text(isPaused ? "Resume" : "Pause")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(16)
                }
                
                Button(action: endScan) {
                    VStack(spacing: 8) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .semibold))
                        
                        Text("End")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 40)
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
        
        // Could show completion view here
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

// MARK: - Info Row Component
struct BodyScanInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

#Preview {
    BodyScanView()
}

