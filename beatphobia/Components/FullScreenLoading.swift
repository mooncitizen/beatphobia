//
//  FullScreenLoading.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//
import SwiftUI

struct FullScreenLoading: View {
    
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
    private let shouldCycleMessages: Bool = true
    
    init(text: String?) {
        
        if let safeText = text, !safeText.isEmpty {
            _loadingText = State(initialValue: safeText)
        } else {
            _loadingText = State(initialValue: "Loading")
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(loadingText)
                .font(.system(size:32, design: .serif))
                .fontWeight(.bold)
                .foregroundStyle(Color(.black))
            Text(displayedText)
                .font(.system(size: 16, design: .serif))
                .foregroundStyle(Color(.black).opacity(0.7))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .id(displayedText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppConstants.defaultBackgroundColor.ignoresSafeArea())
        .foregroundColor(.white)
        .task {
            if shouldCycleMessages {
                await startMessageCycling()
            }
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
