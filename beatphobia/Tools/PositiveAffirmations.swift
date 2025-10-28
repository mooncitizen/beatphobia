//
//  PositiveAffirmations.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct AffirmationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentAffirmationIndex: Int = 0
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
            // Dynamic gradient background
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
                headerView
                
                Spacer()
                
                // Main Content
                mainAffirmationContent
                
                Spacer()
                
                // Bottom Controls
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
                if isAutoPlaying {
                    toggleAutoPlay()
                }
                dismiss()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .opacity(isAutoPlaying ? 0.7 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Affirmations")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.white)
                
                Text("\(currentAffirmationIndex + 1) of \(affirmations.count)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            if isAutoPlaying {
                Button(action: {
                    toggleAutoPlay()
                }) {
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
    
    // MARK: - Main Content
    private var mainAffirmationContent: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)
                
                Image(systemName: currentAffirmation.icon)
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Affirmation Text
            Text(currentAffirmation.text)
                .font(.system(size: 32, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(8)
                .padding(.horizontal, 32)
                .frame(minHeight: 120)
            
            // Category badge
            Text(currentAffirmation.category.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.15))
                .cornerRadius(25)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Save button
            Button(action: toggleSave) {
                HStack(spacing: 8) {
                    Image(systemName: savedAffirmations.contains(currentAffirmationIndex) ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text(savedAffirmations.contains(currentAffirmationIndex) ? "Saved" : "Save Favorite")
                        .font(.system(size: 16, weight: .semibold))
                        .fontDesign(.serif)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(25)
            }
            .padding(.horizontal, 32)
            
            // Navigation controls
            HStack(spacing: 16) {
                // Previous button
                Button(action: previousAffirmation) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .opacity(currentAffirmationIndex == 0 ? 0.3 : 1.0)
                }
                .disabled(currentAffirmationIndex == 0)
                
                Spacer()
                
                // Auto-play button
                Button(action: toggleAutoPlay) {
                    Text(isAutoPlaying ? "Pause" : "Auto-Play")
                        .font(.system(size: 18, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(.white)
                        .frame(width: 120, height: 50)
                        .background(Color.white.opacity(0.25))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
                
                Spacer()
                
                // Next button
                Button(action: nextAffirmation) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.white)
                        .opacity(currentAffirmationIndex == affirmations.count - 1 ? 0.3 : 1.0)
                }
                .disabled(currentAffirmationIndex == affirmations.count - 1)
            }
            .padding(.horizontal, 24)
        }
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

#Preview {
    AffirmationsView()
}
