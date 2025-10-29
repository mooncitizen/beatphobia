//
//  Tapper.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct TapperView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var isGameActive = false
    @State private var score = 0
    @State private var highScore = 0
    @State private var timeRemaining = 60
    @State private var gameTimer: Timer?
    @State private var targets: [TapTarget] = []
    @State private var gameSession: Int = 0
    @State private var showInstructions = false
    @State private var gameAreaSize: CGSize = .zero
    
    struct TapTarget: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat = 80
        var remainingTime: Double = 3.0
        var isHit = false
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                Spacer()
                
                if !isGameActive {
                    mainContentView
                } else {
                    gameActiveView
                }
                
                Spacer()
                
                // Bottom controls
                bottomControlsView
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadHighScore()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                if isGameActive {
                    endGame()
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
            .opacity(isGameActive ? 0.3 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("Tapper")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if isGameActive {
                    Text("Time: \(timeRemaining)s")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            Spacer()
            
            if isGameActive {
                Button(action: {
                    endGame()
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
    
    // MARK: - Main Content (Start Screen)
    private var mainContentView: some View {
        VStack(spacing: 32) {
            // High Score Display
            VStack(spacing: 12) {
                Text("Best Score")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                Text("\(highScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(AppConstants.primaryColor)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 48)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(20)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 24)
            
            // Instructions
            if showInstructions {
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to Play")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Tap the blue circles as fast as you can before they disappear. You have 60 seconds to score as many points as possible!")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .padding(20)
                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, y: 2)
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Game Active View
    private var gameActiveView: some View {
        VStack(spacing: 0) {
            // Score display at top
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Text("\(score)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(AppConstants.primaryColor)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(16)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Game area with GeometryReader for accurate positioning
            GeometryReader { geometry in
                ZStack {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                    
                    // Targets
                    ForEach(targets) { target in
                        if !target.isHit {
                            Button(action: {
                                tapTarget(target)
                            }) {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppConstants.primaryColor,
                                                AppConstants.primaryColor.opacity(0.8)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: target.size, height: target.size)
                                    .shadow(color: AppConstants.primaryColor.opacity(0.4), radius: 8, y: 4)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    )
                            }
                            .position(target.position)
                            .opacity(target.isHit ? 0 : 1)
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    gameAreaSize = geometry.size
                }
                .onChange(of: geometry.size) { oldSize, newSize in
                    gameAreaSize = newSize
                }
            }
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            if !isGameActive {
                Button(action: startGame) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Start Game")
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
                
                Button(action: {
                    showInstructions.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 16, weight: .medium))
                        Text(showInstructions ? "Hide Instructions" : "How to Play")
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
    
    // MARK: - Game Logic
    private func startGame() {
        isGameActive = true
        score = 0
        timeRemaining = 60
        targets.removeAll()
        gameSession += 1
        
        // Wait a moment for game area to be sized properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Start game timer
            gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                    spawnRandomTarget()
                } else {
                    endGame()
                }
            }
            
            // Spawn first target
            spawnRandomTarget()
            
            // Continuously spawn targets
            spawnLoop()
        }
    }
    
    private func spawnLoop() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
            if isGameActive {
                if targets.count < 3 { // Max 3 targets on screen
                    spawnRandomTarget()
                }
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func spawnRandomTarget() {
        // Ensure we have valid game area dimensions
        guard gameAreaSize.width > 0 && gameAreaSize.height > 0 else { return }
        
        // Calculate safe zones within the game area
        // Add padding to keep targets away from edges and bottom
        let sidePadding: CGFloat = 80
        let topPadding: CGFloat = 80    // Keep away from top of game area
        let bottomPadding: CGFloat = 120 // Extra padding from bottom to avoid home bar area
        
        let minX = sidePadding
        let maxX = gameAreaSize.width - sidePadding
        let minY = topPadding
        let maxY = gameAreaSize.height - bottomPadding
        
        // Only spawn if we have valid ranges
        guard maxX > minX && maxY > minY else { return }
        
        let randomX = CGFloat.random(in: minX...maxX)
        let randomY = CGFloat.random(in: minY...maxY)
        
        let newTarget = TapTarget(
            position: CGPoint(x: randomX, y: randomY),
            size: 80,
            remainingTime: 3.0
        )
        
        targets.append(newTarget)
        
        // Auto-remove after 3 seconds if not hit
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let index = targets.firstIndex(where: { $0.id == newTarget.id }), !targets[index].isHit {
                targets[index].isHit = true
                targets.removeAll { $0.isHit }
            }
        }
    }
    
    private func tapTarget(_ target: TapTarget) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Increase score
        score += 1
        
        // Mark as hit
        if let index = targets.firstIndex(where: { $0.id == target.id }) {
            targets[index].isHit = true
            
            // Animate out
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                targets[index].size = 120
            }
            
            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                targets.removeAll { $0.isHit }
            }
        }
        
        // Spawn new target
        spawnRandomTarget()
    }
    
    private func endGame() {
        isGameActive = false
        gameTimer?.invalidate()
        targets.removeAll()
        
        // Update high score
        if score > highScore {
            highScore = score
            saveHighScore()
            
            // Success haptic
            let successGenerator = UINotificationFeedbackGenerator()
            successGenerator.notificationOccurred(.success)
        } else {
            // Regular haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    private func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "TapperHighScore")
    }
    
    private func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "TapperHighScore")
    }
}

#Preview {
    TapperView()
}

