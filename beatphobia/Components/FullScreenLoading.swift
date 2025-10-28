//
//  FullScreenLoading.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import SwiftUI

struct FullScreenLoading: View {
    @Environment(\.colorScheme) var colorScheme
    
    private static let loadingMessages = [
        "You are capable of amazing things.",
        "Every day is a new beginning.",
        "Breathe deeply, you've got this.",
        "Small progress is still progress.",
        "Be kind to yourself.",
        "You are stronger than you think.",
        "Focus on the present moment.",
        "You are deserving of peace.",
        "Embrace your unique journey.",
        "Your potential is limitless.",
        "Choose calm over worry.",
        "One step at a time.",
        "This feeling is temporary.",
        "You are resilient.",
        "Believe in yourself.",
        "Patience is a virtue.",
        "You are enough.",
        "Good things are coming.",
        "Let go of what you can't control.",
        "You are making progress."
    ]
    
    @State private var loadingText: String
    @State private var displayedText: String = loadingMessages.randomElement()!
    @State private var isAnimating = false
    @State private var isPulsing = false
    private let shouldCycleMessages: Bool = true
    
    init(text: String?) {
        
        if let safeText = text, !safeText.isEmpty {
            _loadingText = State(initialValue: safeText)
        } else {
            _loadingText = State(initialValue: "Loading")
        }
    }
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Animated loading icon
                animatedLoadingIcon
                
                VStack(spacing: 12) {
                    Text(loadingText)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text(displayedText)
                        .font(.system(size: 16, design: .serif))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .id(displayedText)
                }
            }
        }
        .task {
            if shouldCycleMessages {
                await startMessageCycling()
            }
        }
    }
    
    // MARK: - Animated Loading Icon
    private var animatedLoadingIcon: some View {
        ZStack {
            // Outer rotating circle
            Circle()
                .stroke(
                    AppConstants.primaryColor.opacity(0.2),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // Inner pulsing circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            AppConstants.primaryColor,
                            AppConstants.primaryColor.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .scaleEffect(isPulsing ? 0.8 : 1.0)
                .opacity(isPulsing ? 0.6 : 1.0)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .onAppear {
            isAnimating = true
            isPulsing = true
        }
    }
    
    private func startMessageCycling() async {
        var currentIndex = 0
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(4.5))
                currentIndex = (currentIndex + 1) % Self.loadingMessages.count
                withAnimation(.easeInOut(duration: 0.5)) {
                    displayedText = Self.loadingMessages[currentIndex]
                }
            } catch {
                return
            }
        }
    }
}

#Preview("Cycling Messages") {
    FullScreenLoading(text: nil)
}

#Preview("Static Message") {
    FullScreenLoading(text: "Fetching user data...")
}
