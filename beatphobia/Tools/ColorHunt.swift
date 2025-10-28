//
//  ColorHunt.swift
//  beatphobia
//
//  Created by Paul Gardiner on 25/10/2025.
//

import SwiftUI

struct ColorHuntView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedColor: HuntColor?
    @State private var foundColors: Set<String> = []
    @State private var showInstructions: Bool = false
    @State private var isGameActive: Bool = false
    @State private var showConfetti: Bool = false
    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    
    let colors: [HuntColor] = [
        HuntColor(name: "Red", color: .red, emoji: "🔴"),
        HuntColor(name: "Orange", color: .orange, emoji: "🟠"),
        HuntColor(name: "Yellow", color: .yellow, emoji: "🟡"),
        HuntColor(name: "Green", color: .green, emoji: "🟢"),
        HuntColor(name: "Blue", color: .blue, emoji: "🔵"),
        HuntColor(name: "Purple", color: .purple, emoji: "🟣"),
        HuntColor(name: "Pink", color: .pink, emoji: "🌸"),
        HuntColor(name: "Brown", color: .brown, emoji: "🟤"),
        HuntColor(name: "White", color: .white, emoji: "⚪️"),
        HuntColor(name: "Black", color: .black, emoji: "⚫️")
    ]
    
    var nextColor: HuntColor? {
        colors.first { !foundColors.contains($0.name) }
    }
    
    var progress: Double {
        Double(foundColors.count) / Double(colors.count)
    }
    
    var isComplete: Bool {
        foundColors.count == colors.count
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
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
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    }
                    
                    Spacer()
                    
                    if isGameActive {
                        // Timer display
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                            
                            Text(formatTime(elapsedTime))
                                .font(.system(size: 16, weight: .bold))
                                .fontDesign(.monospaced)
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showInstructions.toggle()
                    }) {
                        Image(systemName: showInstructions ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Color Hunt")
                                .font(.system(size: 36, weight: .bold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                            Text("Find objects of different colors around you")
                                .font(.system(size: 15))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Instructions (if visible and not active)
                        if showInstructions && !isGameActive {
                            instructionsCard
                                .padding(.horizontal, 20)
                        }
                        
                        // Game Content
                        if !isGameActive {
                            // Start screen with color preview
                            colorGridPreview
                                .padding(.horizontal, 20)
                            
                            Button(action: startGame) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Text("Start Hunt")
                                        .font(.system(size: 18, weight: .bold))
                                        .fontDesign(.rounded)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            AppConstants.primaryColor,
                                            AppConstants.primaryColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: AppConstants.primaryColor.opacity(0.4), radius: 15, y: 8)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        } else {
                            // Active game view
                            if !isComplete {
                                activeGameView
                                    .padding(.horizontal, 20)
                            } else {
                                completionView
                                    .padding(.horizontal, 20)
                            }
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
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("How to Play")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
            }
            
            Text("Look around you and find objects that match each color. Tap 'Found It!' when you spot something of that color.")
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
            
            Divider()
                .padding(.vertical, 8)
            
            VStack(alignment: .leading, spacing: 12) {
                ColorHuntInfoRow(icon: "eye.fill", text: "Helps you focus on your surroundings")
                ColorHuntInfoRow(icon: "arrow.clockwise", text: "Redirects anxious thoughts")
                ColorHuntInfoRow(icon: "sparkles", text: "Makes you more present and mindful")
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - Color Grid Preview
    private var colorGridPreview: some View {
        VStack(spacing: 16) {
            Text("Find all 10 colors")
                .font(.system(size: 18, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(colors, id: \.name) { color in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                        
                        Text(color.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
        }
    }
    
    // MARK: - Active Game View
    private var activeGameView: some View {
        VStack(spacing: 30) {
            // Progress bar
            VStack(spacing: 12) {
                HStack {
                    Text("Progress")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(foundColors.count)/\(colors.count)")
                        .font(.system(size: 14, weight: .bold))
                        .fontDesign(.monospaced)
                        .foregroundColor(AppConstants.primaryColor)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.1))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [AppConstants.primaryColor, AppConstants.primaryColor.opacity(0.7)],
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
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            
            // Current color to find
            if let nextColor = nextColor {
                VStack(spacing: 24) {
                    Text("Find something...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black.opacity(0.6))
                    
                    // Big color circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        nextColor.color.opacity(0.3),
                                        nextColor.color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 200, height: 200)
                        
                        VStack(spacing: 12) {
                            Text(nextColor.emoji)
                                .font(.system(size: 60))
                            
                            Text(nextColor.name)
                                .font(.system(size: 32, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.black)
                        }
                    }
                    
                    // Found button
                    Button(action: {
                        foundColor(nextColor)
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                            
                            Text("Found It!")
                                .font(.system(size: 20, weight: .bold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [nextColor.color, nextColor.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: nextColor.color.opacity(0.4), radius: 15, y: 8)
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 20)
            }
            
            // Found colors grid
            if !foundColors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Found Colors")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black.opacity(0.6))
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(colors.filter { foundColors.contains($0.name) }, id: \.name) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                        }
                    }
                }
                .padding(20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 30) {
            // Success icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.2),
                                Color.green.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 70, weight: .bold))
                    .foregroundColor(.yellow)
            }
            
            VStack(spacing: 12) {
                Text("Amazing!")
                    .font(.system(size: 36, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("You found all the colors!")
                    .font(.system(size: 18))
                    .foregroundColor(.black.opacity(0.6))
                
                Text("Time: \(formatTime(elapsedTime))")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(AppConstants.primaryColor)
                    .padding(.top, 8)
            }
            
            // All colors display
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(colors, id: \.name) { color in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 4, y: 2)
                        
                        Text(color.name)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                    }
                }
            }
            .padding(20)
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
            
            HStack(spacing: 16) {
                Button(action: resetGame) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Play Again")
                            .font(.system(size: 16, weight: .bold))
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(AppConstants.primaryColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppConstants.primaryColor.opacity(0.1))
                    .cornerRadius(16)
                }
                
                Button(action: {
                    timer?.invalidate()
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Finish")
                            .font(.system(size: 16, weight: .bold))
                            .fontDesign(.rounded)
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
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Actions
    private func startGame() {
        isGameActive = true
        foundColors.removeAll()
        startTime = Date()
        elapsedTime = 0
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let startTime = startTime {
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func resetGame() {
        timer?.invalidate()
        foundColors.removeAll()
        isGameActive = false
        showConfetti = false
        startTime = nil
        elapsedTime = 0
    }
    
    private func foundColor(_ color: HuntColor) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        _ = withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            foundColors.insert(color.name)
        }
        
        // Check if complete
        if isComplete {
            timer?.invalidate()
            triggerConfetti()
        }
    }
    
    private func triggerConfetti() {
        let successGenerator = UINotificationFeedbackGenerator()
        successGenerator.notificationOccurred(.success)
        
        showConfetti = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showConfetti = false
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Hunt Color Model
struct HuntColor {
    let name: String
    let color: Color
    let emoji: String
}

// MARK: - Info Row Component
struct ColorHuntInfoRow: View {
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

#Preview {
    ColorHuntView()
}

