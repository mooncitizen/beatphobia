//
//  54321Grounding.swift
//  beatphobia
//
//  Created by Paul Gardiner on 22/10/2025.
//

import SwiftUI
import Combine

struct GroundingView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var groundingManager = GroundingManager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header - Always visible
                headerView
                
                Spacer()
                
                // Main content
                mainGroundingView
                
                Spacer()
                
                // Bottom controls - Always visible
                bottomControlsView
                    .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            groundingManager.prepareHaptics()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: {
                groundingManager.pause()
                if groundingManager.hapticsEnabled {
                    groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
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
            .opacity(groundingManager.isActive ? 0.3 : 1.0)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("5-4-3-2-1 Grounding")
                    .font(.system(size: 22, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                if groundingManager.isComplete {
                    Text("Complete")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            Spacer()
            
            // Stop button - minimal style
            if groundingManager.isActive {
                Button(action: {
                    groundingManager.pause()
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
    
    // MARK: - Main Grounding View
    private var mainGroundingView: some View {
        VStack(spacing: 40) {
            // Show completion details when done
            if groundingManager.isComplete {
                completionDetailsView
            } else {
                // Instruction Card
                let currentSense = groundingManager.senses[groundingManager.currentStep]
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: currentSense.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(currentSense.color)
                        
                        Text("\(currentSense.count) things you can \(currentSense.title.lowercased())")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 3)
                .padding(.horizontal, 24)
            }
            
            // Items list with animated circles
            if !groundingManager.isComplete {
                let currentSense = groundingManager.senses[groundingManager.currentStep]
                
                VStack(spacing: 16) {
                    ForEach(0..<currentSense.count, id: \.self) { index in
                        itemRow(index: index, sense: currentSense)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Completion Details View
    private var completionDetailsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Success header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.green)
                    }
                    
                    Text("Well Done!")
                        .font(.system(size: 28, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("You've grounded yourself in the present moment")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                
                // Summary of all inputs
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Grounding Summary")
                        .font(.system(size: 20, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    ForEach(0..<groundingManager.senses.count, id: \.self) { stepIndex in
                        let sense = groundingManager.senses[stepIndex]
                        let items = groundingManager.completedItems[stepIndex]
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: sense.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(sense.color)
                                
                                Text(sense.title)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            
                            ForEach(Array(items.enumerated()), id: \.offset) { itemIndex, item in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(sense.color.opacity(0.2))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(item)
                                        .font(.system(size: 16))
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                }
                                .padding(.horizontal, 24)
                                .padding(.leading, 28)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    private func itemRow(index: Int, sense: GroundingSense) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(sense.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(sense.color)
            }
            
            TextField("Tap to add...", text: groundingManager.getBinding(for: index))
                .font(.system(size: 17))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                .submitLabel(.done)
                .onSubmit {
                    if groundingManager.hapticsEnabled {
                        groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                }
            
            if !groundingManager.getBinding(for: index).wrappedValue.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, y: 2)
    }
    
    // MARK: - Bottom Controls
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            // Start/Continue button
            if !groundingManager.isComplete && !groundingManager.isActive {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        groundingManager.start()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Start Grounding")
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
            }
            
            // Continue button when can proceed
            if groundingManager.isActive && groundingManager.canProceed {
                let currentSense = groundingManager.senses[groundingManager.currentStep]
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        groundingManager.nextStep()
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 22, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [currentSense.color, currentSense.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: currentSense.color.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            }
            
            // Done button on completion
            if groundingManager.isComplete {
                Button(action: {
                    if groundingManager.hapticsEnabled {
                        groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                        
                        Text("Done")
                            .font(.system(size: 18, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: Color.green.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 32)
            }
            
            // Reset button
            if !groundingManager.isActive && groundingManager.currentStep > 0 {
                Button(action: {
                    withAnimation(.spring(response: 0.4)) {
                        groundingManager.reset()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text("Reset")
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
}

// MARK: - Grounding Manager
class GroundingManager: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var completedItems: [[String]] = [[], [], [], [], []]
    @Published var item0: String = ""
    @Published var item1: String = ""
    @Published var item2: String = ""
    @Published var item3: String = ""
    @Published var item4: String = ""
    @Published var hapticsEnabled: Bool = true
    @Published var isActive: Bool = false
    
    let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    let successHaptic = UINotificationFeedbackGenerator()
    
    let senses: [GroundingSense] = [
        GroundingSense(title: "See", icon: "eye.fill", count: 5, color: .blue),
        GroundingSense(title: "Touch", icon: "hand.raised.fill", count: 4, color: .green),
        GroundingSense(title: "Hear", icon: "ear.fill", count: 3, color: .purple),
        GroundingSense(title: "Smell", icon: "nose.fill", count: 2, color: .orange),
        GroundingSense(title: "Taste", icon: "mouth.fill", count: 1, color: .pink)
    ]
    
    var canProceed: Bool {
        guard !isComplete else { return false }
        let currentSense = senses[currentStep]
        let items = getCurrentItems()
        let filledCount = items.prefix(currentSense.count).filter { !$0.isEmpty }.count
        return filledCount == currentSense.count
    }
    
    var isComplete: Bool {
        currentStep >= senses.count
    }
    
    func prepareHaptics() {
        lightHaptic.prepare()
        mediumHaptic.prepare()
        successHaptic.prepare()
    }
    
    func start() {
        isActive = true
        if hapticsEnabled {
            mediumHaptic.impactOccurred(intensity: 0.7)
        }
    }
    
    func pause() {
        isActive = false
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.5)
        }
    }
    
    func getCurrentItems() -> [String] {
        return [item0, item1, item2, item3, item4]
    }
    
    func getBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                switch index {
                case 0: return self.item0
                case 1: return self.item1
                case 2: return self.item2
                case 3: return self.item3
                case 4: return self.item4
                default: return self.item0
                }
            },
            set: { newValue in
                switch index {
                case 0: self.item0 = newValue
                case 1: self.item1 = newValue
                case 2: self.item2 = newValue
                case 3: self.item3 = newValue
                case 4: self.item4 = newValue
                default: break
                }
            }
        )
    }
    
    func nextStep() {
        // Save current items
        let currentSense = senses[currentStep]
        let items = getCurrentItems()
        completedItems[currentStep] = Array(items.prefix(currentSense.count))
        
        // Haptic feedback
        if hapticsEnabled {
            if currentStep == senses.count - 1 {
                // Completed all steps!
                successHaptic.notificationOccurred(.success)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.mediumHaptic.impactOccurred(intensity: 1.0)
                }
            } else {
                mediumHaptic.impactOccurred(intensity: 0.7)
            }
        }
        
        // Move to next step
        currentStep += 1
        
        // Reset current items for next step
        item0 = ""
        item1 = ""
        item2 = ""
        item3 = ""
        item4 = ""
    }
    
    func reset() {
        pause()
        
        if hapticsEnabled {
            lightHaptic.impactOccurred(intensity: 0.5)
        }
        
        currentStep = 0
        completedItems = [[], [], [], [], []]
        item0 = ""
        item1 = ""
        item2 = ""
        item3 = ""
        item4 = ""
    }
}

// MARK: - Models
struct GroundingSense {
    let title: String
    let icon: String
    let count: Int
    let color: Color
}

#Preview {
    GroundingView()
}
