//
//  CountingGame.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI
import UIKit

struct CountingGameView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedMode: CountingMode = .countUp
    @State private var currentNumber: Int = 0
    @State private var targetNumber: Int = 100
    @State private var isActive: Bool = false
    @State private var showInstructions: Bool = false
    @State private var showConfetti: Bool = false
    
    enum CountingMode: String, CaseIterable {
        case countUp = "Count Up"
        case countDown = "Count Down"
        case countBy = "Count by 3s"
        
        var icon: String {
            switch self {
            case .countUp: return "arrow.up.circle.fill"
            case .countDown: return "arrow.down.circle.fill"
            case .countBy: return "shuffle.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .countUp: return .green
            case .countDown: return .orange
            case .countBy: return .purple
            }
        }
        
        var instructions: String {
            switch self {
            case .countUp:
                return "Count from 1 upwards. Focus on each number as you tap."
            case .countDown:
                return "Count backwards from 100. Each number brings you more calm."
            case .countBy:
                return "Count by 3s starting from 0. Challenge your mind and redirect anxiety."
            }
        }
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showInstructions.toggle()
                    }) {
                        Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Counting Game")
                                .font(.system(size: 36, weight: .bold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                            Text("Redirect your thoughts through simple counting")
                                .font(.system(size: 15))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Mode Selection
                        if !isActive {
                            VStack(spacing: 16) {
                                ForEach(CountingMode.allCases, id: \.self) { mode in
                                    ModeCard(
                                        mode: mode,
                                        isSelected: selectedMode == mode,
                                        action: {
                                            selectedMode = mode
                                            resetGame()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Instructions (if visible)
                        if showInstructions && !isActive {
                            instructionsCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Main Counter Display
                        if isActive {
                            counterDisplay
                                .padding(.horizontal, 20)
                                .padding(.top, 40)
                        }
                        
                        // Action Button
                        if !isActive {
                            Button(action: startGame) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Text("Start Counting")
                                        .font(.system(size: 18, weight: .bold))
                                        .fontDesign(.rounded)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            selectedMode.color,
                                            selectedMode.color.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: selectedMode.color.opacity(0.4), radius: 15, y: 8)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        } else {
                            controlButtons
                                .padding(.horizontal, 40)
                                .padding(.top, 40)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            
            // Confetti overlay
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Instructions Card
    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: selectedMode.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(selectedMode.color)
                
                Text("How it Works")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
            }
            
            Text(selectedMode.instructions)
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                CountingInfoRow(icon: "brain.head.profile", text: "Occupies your mind with a simple task")
                CountingInfoRow(icon: "arrow.clockwise", text: "Breaks the cycle of anxious thoughts")
                CountingInfoRow(icon: "clock", text: "2-3 minutes is often enough to feel calmer")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Counter Display
    private var counterDisplay: some View {
        VStack(spacing: 30) {
            // Progress indicator (for count down/up to target)
            if selectedMode == .countUp || selectedMode == .countDown {
                VStack(spacing: 8) {
                    Text("Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                    
                    ProgressView(value: progressValue, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: selectedMode.color))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("\(Int(progressValue * 100))%")
                        .font(.system(size: 13, weight: .bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(selectedMode.color)
                }
                .padding(.horizontal, 40)
            }
            
            // Big Number Display
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                selectedMode.color.opacity(0.15),
                                selectedMode.color.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 250, height: 250)
                
                VStack(spacing: 8) {
                    Text("\(currentNumber)")
                        .font(.system(size: 80, weight: .bold, design: .rounded))
                        .foregroundColor(selectedMode.color)
                    
                    Text(selectedMode.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                }
            }
            
            // Tap to count button
            Button(action: incrementCount) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("Tap to Count")
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.rounded)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [
                            selectedMode.color,
                            selectedMode.color.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: selectedMode.color.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Control Buttons
    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button(action: resetGame) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("Reset")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(selectedMode.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedMode.color.opacity(0.1))
                .cornerRadius(16)
            }
            
            Button(action: stopGame) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .semibold))
                    
                    Text("Finish")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.green.opacity(0.4), radius: 10, y: 4)
            }
        }
    }
    
    // MARK: - Helper Properties
    private var progressValue: Double {
        switch selectedMode {
        case .countUp:
            guard targetNumber > 0 else { return 0.0 }
            return min(Double(currentNumber) / Double(targetNumber), 1.0)
        case .countDown:
            guard targetNumber > 0 else { return 0.0 }
            let initial = 100.0
            return min((initial - Double(currentNumber)) / initial, 1.0)
        case .countBy:
            return 0.0 // No progress bar for count by 3s
        }
    }
    
    // MARK: - Actions
    private func startGame() {
        isActive = true
        resetGame()
    }
    
    private func stopGame() {
        isActive = false
    }
    
    private func resetGame() {
        switch selectedMode {
        case .countUp:
            currentNumber = 0
            targetNumber = 100
        case .countDown:
            currentNumber = 100
            targetNumber = 0
        case .countBy:
            currentNumber = 0
        }
    }
    
    private func incrementCount() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            switch selectedMode {
            case .countUp:
                if currentNumber < targetNumber {
                    currentNumber += 1
                    if currentNumber >= targetNumber {
                        // Trigger confetti celebration
                        triggerConfetti()
                    }
                }
            case .countDown:
                currentNumber -= 1
                if currentNumber <= 0 {
                    currentNumber = 0
                    // Trigger confetti celebration
                    triggerConfetti()
                }
            case .countBy:
                currentNumber += 3
            }
        }
    }
    
    private func triggerConfetti() {
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
        
        showConfetti = true
        
        // Hide confetti after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
    }
}

// MARK: - Mode Card Component
struct ModeCard: View {
    let mode: CountingGameView.CountingMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(mode.color)
                }
                
                Text(mode.rawValue)
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.black)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(mode.color)
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? mode.color : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? mode.color.opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 10 : 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Row Component
struct CountingInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppConstants.primaryColor)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.8))
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: 10, height: 10)
                    .position(piece.position)
                    .opacity(piece.opacity)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        
        // Get screen bounds - suppressing deprecation warning for UIScreen.main
        #if compiler(>=6.0)
        let bounds: CGRect
        if #available(iOS 16.0, *) {
            bounds = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.screen.bounds ?? CGRect(x: 0, y: 0, width: 400, height: 800)
        } else {
            bounds = UIScreen.main.bounds
        }
        #else
        let bounds = UIScreen.main.bounds
        #endif
        
        for _ in 0..<50 {
            let randomX = CGFloat.random(in: 0...bounds.width)
            let randomY = CGFloat.random(in: -100...0)
            let randomColor = colors.randomElement() ?? .blue
            
            let piece = ConfettiPiece(
                color: randomColor,
                position: CGPoint(x: randomX, y: randomY)
            )
            
            confettiPieces.append(piece)
            
            // Animate each piece falling
            withAnimation(.linear(duration: Double.random(in: 2...4))) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].position.y = bounds.height + 100
                    confettiPieces[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    var position: CGPoint
    var opacity: Double = 1.0
}

#Preview {
    CountingGameView()
}

