//
//  PositiveAffirmations.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct AffirmationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentAffirmationIndex: Int = 0
    @State private var showInstructions: Bool = false
    @State private var savedAffirmations: Set<Int> = []
    @State private var isAutoPlaying: Bool = false
    @State private var timer: Timer?
    
    let affirmations: [Affirmation] = [
        Affirmation(text: "I am safe right now", category: .safety, icon: "shield.fill", color: .blue),
        Affirmation(text: "This feeling will pass", category: .temporary, icon: "clock.arrow.circlepath", color: .purple),
        Affirmation(text: "I am stronger than my anxiety", category: .strength, icon: "figure.strengthtraining.traditional", color: .orange),
        Affirmation(text: "I trust my body to keep me safe", category: .safety, icon: "heart.fill", color: .red),
        Affirmation(text: "I choose peace over fear", category: .peace, icon: "leaf.fill", color: .green),
        Affirmation(text: "My anxiety does not define me", category: .identity, icon: "person.fill", color: .indigo),
        Affirmation(text: "I am doing my best, and that is enough", category: .acceptance, icon: "hand.thumbsup.fill", color: .yellow),
        Affirmation(text: "Every breath brings me calm", category: .calm, icon: "wind", color: .cyan),
        Affirmation(text: "I am worthy of peace and happiness", category: .worth, icon: "sparkles", color: .pink),
        Affirmation(text: "I can handle whatever comes my way", category: .strength, icon: "mountain.2.fill", color: .brown),
        Affirmation(text: "I release what I cannot control", category: .acceptance, icon: "hands.sparkles.fill", color: .purple),
        Affirmation(text: "I am brave for facing my fears", category: .courage, icon: "flame.fill", color: .orange),
        Affirmation(text: "My feelings are valid and temporary", category: .temporary, icon: "cloud.fill", color: .gray),
        Affirmation(text: "I am growing stronger every day", category: .growth, icon: "chart.line.uptrend.xyaxis", color: .green),
        Affirmation(text: "I deserve compassion and kindness", category: .worth, icon: "heart.circle.fill", color: .red),
        Affirmation(text: "I trust myself to get through this", category: .trust, icon: "checkmark.seal.fill", color: .blue),
        Affirmation(text: "Peace is my natural state", category: .peace, icon: "moon.stars.fill", color: .indigo),
        Affirmation(text: "I am learning and healing", category: .growth, icon: "sprout.fill", color: .green),
        Affirmation(text: "I choose courage over comfort", category: .courage, icon: "bolt.fill", color: .yellow),
        Affirmation(text: "I am proud of my progress", category: .pride, icon: "star.fill", color: .yellow)
    ]
    
    var currentAffirmation: Affirmation {
        affirmations[currentAffirmationIndex]
    }
    
    var body: some View {
        ZStack {
            // Static gradient background
            LinearGradient(
                colors: [
                    currentAffirmation.color,
                    currentAffirmation.color.opacity(0.8),
                    currentAffirmation.color.opacity(0.6)
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
                    
                    // Counter
                    Text("\(currentAffirmationIndex + 1)/\(affirmations.count)")
                        .font(.system(size: 16, weight: .bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                    
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
                
                // Instructions (if visible)
                if showInstructions {
                    instructionsCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Main Affirmation Card
                VStack(spacing: 30) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: currentAffirmation.icon)
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    // Affirmation Text
                    Text(currentAffirmation.text)
                        .font(.system(size: 32, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 40)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.8)
                    
                    // Category badge
                    Text(currentAffirmation.category.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                    
                    // Save button
                    Button(action: {
                        toggleSave()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: savedAffirmations.contains(currentAffirmationIndex) ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .semibold))
                            
                            Text(savedAffirmations.contains(currentAffirmationIndex) ? "Saved" : "Save Favorite")
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                    }
                }
                .padding(.vertical, 40)
                
                Spacer()
                
                // Navigation Controls
                VStack(spacing: 20) {
                    // Auto-play toggle
                    Button(action: toggleAutoPlay) {
                        HStack(spacing: 12) {
                            Image(systemName: isAutoPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text(isAutoPlaying ? "Pause Auto-Play" : "Start Auto-Play")
                                .font(.system(size: 16, weight: .bold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)
                    
                    // Navigation arrows
                    HStack(spacing: 20) {
                        Button(action: previousAffirmation) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .disabled(currentAffirmationIndex == 0)
                        .opacity(currentAffirmationIndex == 0 ? 0.3 : 1.0)
                        
                        Spacer()
                        
                        Button(action: nextAffirmation) {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        .disabled(currentAffirmationIndex == affirmations.count - 1)
                        .opacity(currentAffirmationIndex == affirmations.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, 60)
                }
                .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("How to Use")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                AffirmationInfoRow(icon: "text.bubble.fill", text: "Read each affirmation slowly and mindfully")
                AffirmationInfoRow(icon: "arrow.clockwise", text: "Repeat it silently or aloud 3 times")
                AffirmationInfoRow(icon: "heart.fill", text: "Save your favorites for quick access")
                AffirmationInfoRow(icon: "play.circle.fill", text: "Use auto-play for a guided session")
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
    
    // MARK: - Actions
    private func nextAffirmation() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if currentAffirmationIndex < affirmations.count - 1 {
            currentAffirmationIndex += 1
        }
    }
    
    private func previousAffirmation() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if currentAffirmationIndex > 0 {
            currentAffirmationIndex -= 1
        }
    }
    
    private func toggleSave() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if savedAffirmations.contains(currentAffirmationIndex) {
            savedAffirmations.remove(currentAffirmationIndex)
        } else {
            savedAffirmations.insert(currentAffirmationIndex)
        }
    }
    
    private func toggleAutoPlay() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if isAutoPlaying {
            // Stop auto-play
            timer?.invalidate()
            timer = nil
            isAutoPlaying = false
        } else {
            // Start auto-play
            isAutoPlaying = true
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                if currentAffirmationIndex < affirmations.count - 1 {
                    withAnimation {
                        currentAffirmationIndex += 1
                    }
                } else {
                    // Stop at the end
                    timer?.invalidate()
                    timer = nil
                    isAutoPlaying = false
                }
            }
        }
    }
}

// MARK: - Affirmation Model
struct Affirmation {
    let text: String
    let category: AffirmationCategory
    let icon: String
    let color: Color
}

enum AffirmationCategory: String {
    case safety = "Safety"
    case temporary = "Temporary"
    case strength = "Strength"
    case peace = "Peace"
    case identity = "Identity"
    case acceptance = "Acceptance"
    case calm = "Calm"
    case worth = "Self-Worth"
    case courage = "Courage"
    case growth = "Growth"
    case trust = "Trust"
    case pride = "Pride"
}

// MARK: - Info Row Component
struct AffirmationInfoRow: View {
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
    AffirmationsView()
}

