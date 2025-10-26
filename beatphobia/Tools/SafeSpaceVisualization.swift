//
//  SafeSpaceVisualization.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct SafeSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedEnvironment: SafeEnvironment?
    @State private var isVisualizing: Bool = false
    @State private var showInstructions: Bool = false
    @State private var currentPromptIndex: Int = 0
    @State private var timer: Timer?
    @State private var elapsedTime: TimeInterval = 0
    @State private var isPaused: Bool = false
    
    let environments: [SafeEnvironment] = [
        SafeEnvironment(
            name: "Beach Paradise",
            icon: "beach.umbrella.fill",
            color: Color(red: 0.2, green: 0.6, blue: 0.9),
            gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.9), Color(red: 0.1, green: 0.4, blue: 0.7)],
            prompts: [
                "Feel the warm sand beneath your feet...",
                "Listen to the gentle waves rolling onto shore...",
                "Notice the cool ocean breeze on your skin...",
                "See the endless blue horizon where sky meets sea...",
                "Smell the fresh salt air...",
                "Hear the seagulls calling in the distance...",
                "Feel the sun warming your face...",
                "Watch the waves rhythmically coming and going..."
            ]
        ),
        SafeEnvironment(
            name: "Forest Retreat",
            icon: "leaf.fill",
            color: Color(red: 0.2, green: 0.6, blue: 0.3),
            gradientColors: [Color(red: 0.2, green: 0.6, blue: 0.3), Color(red: 0.1, green: 0.4, blue: 0.2)],
            prompts: [
                "Notice the tall trees surrounding you...",
                "Hear the rustling of leaves in the breeze...",
                "Smell the fresh, earthy scent of the forest...",
                "See dappled sunlight filtering through the canopy...",
                "Listen to birds singing their peaceful songs...",
                "Feel the soft moss beneath your feet...",
                "Notice the gentle swaying of branches above...",
                "Breathe in the clean, crisp air..."
            ]
        ),
        SafeEnvironment(
            name: "Mountain Peak",
            icon: "mountain.2.fill",
            color: Color(red: 0.5, green: 0.4, blue: 0.6),
            gradientColors: [Color(red: 0.5, green: 0.4, blue: 0.6), Color(red: 0.3, green: 0.2, blue: 0.4)],
            prompts: [
                "Stand at the top and see the world below...",
                "Feel the cool, crisp mountain air...",
                "Notice the vast, open sky above you...",
                "See the clouds drifting peacefully by...",
                "Hear the wind whistling over the peaks...",
                "Feel a sense of perspective and calm...",
                "Notice the stillness and quiet around you...",
                "Breathe deeply in this elevated space..."
            ]
        ),
        SafeEnvironment(
            name: "Cozy Cabin",
            icon: "house.fill",
            color: Color(red: 0.8, green: 0.5, blue: 0.3),
            gradientColors: [Color(red: 0.8, green: 0.5, blue: 0.3), Color(red: 0.6, green: 0.3, blue: 0.2)],
            prompts: [
                "Feel the warmth of the fireplace...",
                "Hear the crackling of burning wood...",
                "See the soft glow of the flames dancing...",
                "Feel wrapped in a cozy blanket...",
                "Notice the comfort of this safe space...",
                "Smell the wood smoke and warmth...",
                "Hear rain gently pattering on the roof...",
                "Feel completely secure and at peace..."
            ]
        ),
        SafeEnvironment(
            name: "Starlit Field",
            icon: "moon.stars.fill",
            color: Color(red: 0.2, green: 0.2, blue: 0.5),
            gradientColors: [Color(red: 0.2, green: 0.2, blue: 0.5), Color(red: 0.1, green: 0.1, blue: 0.3)],
            prompts: [
                "Lie back and gaze at the stars above...",
                "See countless stars twinkling in the darkness...",
                "Feel the soft grass beneath you...",
                "Notice the vastness of the universe...",
                "Hear the peaceful silence of the night...",
                "See the moon glowing softly...",
                "Feel small yet connected to everything...",
                "Breathe in the cool night air..."
            ]
        ),
        SafeEnvironment(
            name: "Garden Sanctuary",
            icon: "tree.fill",
            color: Color(red: 0.9, green: 0.5, blue: 0.6),
            gradientColors: [Color(red: 0.9, green: 0.5, blue: 0.6), Color(red: 0.7, green: 0.3, blue: 0.4)],
            prompts: [
                "Walk through a beautiful garden...",
                "See colorful flowers blooming everywhere...",
                "Smell the sweet fragrance of blossoms...",
                "Hear bees buzzing gently among the flowers...",
                "Feel the soft petals between your fingers...",
                "Notice butterflies dancing in the air...",
                "See a gentle fountain bubbling nearby...",
                "Feel at peace in this natural beauty..."
            ]
        )
    ]
    
    var currentEnvironment: SafeEnvironment? {
        selectedEnvironment
    }
    
    var currentPrompt: String {
        guard let env = currentEnvironment else { return "" }
        return env.prompts[currentPromptIndex % env.prompts.count]
    }
    
    var progress: Double {
        guard let env = currentEnvironment else { return 0 }
        let promptDuration: Double = 15.0 // 15 seconds per prompt
        let totalDuration = Double(env.prompts.count) * promptDuration
        return min(elapsedTime / totalDuration, 1.0)
    }
    
    var body: some View {
        ZStack {
            // Dynamic background based on selected environment
            if let env = currentEnvironment {
                LinearGradient(
                    colors: env.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Default gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.2, blue: 0.5),
                        Color(red: 0.2, green: 0.3, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        timer?.invalidate()
                        if isVisualizing {
                            endVisualization()
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: isVisualizing ? "arrow.left.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    if isVisualizing {
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
                    
                    if !isVisualizing {
                        Button(action: {
                            showInstructions.toggle()
                        }) {
                            Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    } else {
                        // Placeholder for symmetry
                        Color.clear
                            .frame(width: 28, height: 28)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        if !isVisualizing {
                            // Title
                            VStack(spacing: 8) {
                                Text("Safe Space")
                                    .font(.system(size: 36, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundColor(.white)
                                
                                Text("Create a peaceful place in your mind")
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            
                            // Instructions (if visible)
                            if showInstructions {
                                instructionsCard
                                    .padding(.horizontal, 20)
                            }
                            
                            // Environment selection
                            environmentSelectionView
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        } else {
                            // Visualization view
                            visualizationView
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
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
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("How It Works")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                SafeSpaceInfoRow(icon: "location.fill", text: "Choose your ideal safe environment")
                SafeSpaceInfoRow(icon: "eye.fill", text: "Close your eyes and visualize each detail")
                SafeSpaceInfoRow(icon: "心", text: "Engage all your senses in the experience")
                SafeSpaceInfoRow(icon: "infinity", text: "Return to this space whenever you need calm")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
    
    // MARK: - Environment Selection View
    private var environmentSelectionView: some View {
        VStack(spacing: 20) {
            Text("Choose Your Safe Space")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.white)
                .padding(.top, 10)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(environments) { env in
                    EnvironmentCard(
                        environment: env,
                        isSelected: selectedEnvironment?.id == env.id
                    )
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        selectedEnvironment = env
                    }
                }
            }
            
            // Begin button
            if selectedEnvironment != nil {
                Button(action: startVisualization) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Begin Visualization")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [selectedEnvironment!.color, selectedEnvironment!.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: selectedEnvironment!.color.opacity(0.4), radius: 15, y: 8)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
    }
    
    // MARK: - Visualization View
    private var visualizationView: some View {
        VStack(spacing: 40) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.8))
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)
            
            // Environment icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: currentEnvironment?.icon ?? "sparkles")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Environment name
            Text(currentEnvironment?.name ?? "")
                .font(.system(size: 32, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.white)
            
            // Current prompt
            Text(currentPrompt)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 30)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)
                .frame(minHeight: 120)
            
            // Breathing guide
            HStack(spacing: 12) {
                Image(systemName: "wind")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Breathe deeply and slowly")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(25)
            
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
                
                Button(action: endVisualization) {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                        
                        Text("Complete")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
    }
    
    // MARK: - Actions
    private func startVisualization() {
        isVisualizing = true
        currentPromptIndex = 0
        elapsedTime = 0
        isPaused = false
        startTimer()
    }
    
    private func startTimer() {
        timer?.invalidate()
        let promptDuration: TimeInterval = 15.0 // 15 seconds per prompt
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            
            // Check if current prompt duration is complete
            let promptProgress = elapsedTime.truncatingRemainder(dividingBy: promptDuration)
            if promptProgress < 0.1 && elapsedTime > 0.1 {
                // Move to next prompt
                if let env = currentEnvironment, currentPromptIndex < env.prompts.count - 1 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    currentPromptIndex += 1
                } else {
                    // Complete visualization
                    completeVisualization()
                }
            }
        }
    }
    
    private func completeVisualization() {
        timer?.invalidate()
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        endVisualization()
    }
    
    private func endVisualization() {
        timer?.invalidate()
        isVisualizing = false
        currentPromptIndex = 0
        elapsedTime = 0
        isPaused = false
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Safe Environment Model
struct SafeEnvironment: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let gradientColors: [Color]
    let prompts: [String]
}

// MARK: - Environment Card Component
struct EnvironmentCard: View {
    let environment: SafeEnvironment
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(environment.color.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: environment.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(environment.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(isSelected ? 0.3 : 0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(isSelected ? 0.8 : 0.0), lineWidth: 3)
        )
    }
}

// MARK: - Info Row Component
struct SafeSpaceInfoRow: View {
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
    SafeSpaceView()
}

