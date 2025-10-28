//
//  SafeSpaceVisualization.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct SafeSpaceView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedEnvironment: SafeEnvironment?
    @State private var isVisualizing: Bool = false
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
        let promptDuration: Double = 15.0
        let totalDuration = Double(env.prompts.count) * promptDuration
        return min(elapsedTime / totalDuration, 1.0)
    }
    
    var body: some View {
        ZStack {
            if let env = currentEnvironment, isVisualizing {
                // Dynamic background during visualization
                LinearGradient(
                    colors: env.gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            } else {
                // Default background for selection
                AppConstants.backgroundColor(for: colorScheme)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Header - Always visible
                headerView
                
                Spacer()
                
                // Main content
                if isVisualizing {
                    visualizationView
                } else {
                    mainSelectionView
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
                if isVisualizing {
                    endVisualization()
                }
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isVisualizing ? Color.white.opacity(0.2) : AppConstants.cardBackgroundColor(for: colorScheme))
                        .frame(width: 44, height: 44)
                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, y: 2)
                    
                    Image(systemName: isVisualizing ? "arrow.left" : "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isVisualizing ? .white : AppConstants.primaryTextColor(for: colorScheme))
                }
            }
            .opacity(isVisualizing ? 0.9 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(isVisualizing ? (currentEnvironment?.name ?? "Safe Space") : "Safe Space")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(isVisualizing ? .white : AppConstants.primaryTextColor(for: colorScheme))
                
                if isVisualizing {
                    Text("Prompt \(currentPromptIndex + 1) of \(currentEnvironment?.prompts.count ?? 8)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            // Stop/Complete button
            if isVisualizing {
                Button(action: endVisualization) {
                    Text("Stop")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
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
    
    // MARK: - Main Selection View
    private var mainSelectionView: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Title
                VStack(spacing: 12) {
                    Text("Create Your Safe Space")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Choose a peaceful environment and visualize it with all your senses")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Environment selection grid
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
                .padding(.horizontal, 24)
            }
            .padding(.top, 24)
        }
    }
    
    // MARK: - Visualization View
    private var visualizationView: some View {
        VStack(spacing: 40) {
            // Environment icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: currentEnvironment?.icon ?? "sparkles")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Current prompt
            Text(currentPrompt)
                .font(.system(size: 28, weight: .semibold))
                .fontDesign(.serif)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 32)
                .frame(minHeight: 150)
            
            // Breathing guide
            HStack(spacing: 12) {
                Image(systemName: "wind")
                    .font(.system(size: 18))
                
                Text("Breathe deeply and slowly")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Color.white.opacity(0.15))
            .cornerRadius(30)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            if !isVisualizing && selectedEnvironment != nil {
                Button(action: startVisualization) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Begin Visualization")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [selectedEnvironment!.color, selectedEnvironment!.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: selectedEnvironment!.color.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            } else if isVisualizing {
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
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
                .padding(.horizontal, 32)
            }
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
        let promptDuration: TimeInterval = 15.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            elapsedTime += 0.1
            
            let promptProgress = elapsedTime.truncatingRemainder(dividingBy: promptDuration)
            if promptProgress < 0.1 && elapsedTime > 0.1 {
                if let env = currentEnvironment, currentPromptIndex < env.prompts.count - 1 {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    currentPromptIndex += 1
                } else {
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
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(environment.color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: environment.icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(environment.color)
            }
            
            Text(environment.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(environment.color.opacity(isSelected ? 0.6 : 0), lineWidth: 3)
        )
    }
}

#Preview {
    SafeSpaceView()
}
