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
    @StateObject private var groundingManager = GroundingManager()
    
    var body: some View {
        ZStack {
            // Background
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress
                        progressView
                        
                        // Current step card
                        currentStepCard
                        
                        // Completed steps summary
                        if groundingManager.currentStep > 0 {
                            completedStepsView
                        }
                        
                        // Completion or restart
                        if groundingManager.isComplete {
                            completionView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
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
                if groundingManager.hapticsEnabled {
                    groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
                }
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(AppConstants.primaryColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                }
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("5-4-3-2-1 Grounding")
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("Stay present with your senses")
                    .font(.system(size: 12))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.6))
            }
            
            Spacer()
            
            // Spacer for balance
            Color.clear
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
    
    // MARK: - Progress View
    private var progressView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index < groundingManager.currentStep ? AppConstants.primaryColor : AppConstants.primaryColor.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text("Step \(groundingManager.currentStep + 1) of 5")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppConstants.primaryColor.opacity(0.7))
        }
    }
    
    // MARK: - Current Step Card
    private var currentStepCard: some View {
        VStack(spacing: 0) {
            if !groundingManager.isComplete {
                let currentSense = groundingManager.senses[groundingManager.currentStep]
                
                VStack(spacing: 20) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(currentSense.color.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: currentSense.icon)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(currentSense.color)
                    }
                    
                    // Title and description
                    VStack(spacing: 8) {
                        Text("Identify \(currentSense.count) thing\(currentSense.count > 1 ? "s" : "")")
                            .font(.system(size: 24, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        Text("you can \(currentSense.title.lowercased())")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                    }
                    
                    // Items list
                    VStack(spacing: 12) {
                        ForEach(0..<currentSense.count, id: \.self) { index in
                            itemRow(index: index, sense: currentSense)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Next button
                    if groundingManager.canProceed {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                groundingManager.nextStep()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text("Continue")
                                    .font(.system(size: 18, weight: .semibold))
                                    .fontDesign(.serif)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(currentSense.color)
                            .cornerRadius(26)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
            }
        }
    }
    
    private func itemRow(index: Int, sense: GroundingSense) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(sense.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(sense.color)
            }
            
            TextField("Tap to add...", text: groundingManager.getBinding(for: index))
                .font(.system(size: 16))
                .foregroundColor(AppConstants.primaryColor)
                .submitLabel(.done)
                .onSubmit {
                    if groundingManager.hapticsEnabled {
                        groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                }
            
            Spacer()
            
            if !groundingManager.getBinding(for: index).wrappedValue.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(AppConstants.defaultBackgroundColor)
        .cornerRadius(12)
    }
    
    // MARK: - Completed Steps
    private var completedStepsView: some View {
        VStack(spacing: 12) {
            Text("Completed")
                .font(.system(size: 16, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(0..<groundingManager.currentStep, id: \.self) { stepIndex in
                let sense = groundingManager.senses[stepIndex]
                let items = groundingManager.completedItems[stepIndex]
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: sense.icon)
                            .font(.system(size: 16))
                            .foregroundColor(sense.color)
                        
                        Text(sense.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    
                    ForEach(items, id: \.self) { item in
                        HStack {
                            Circle()
                                .fill(sense.color.opacity(0.3))
                                .frame(width: 6, height: 6)
                            
                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Well Done!")
                    .font(.system(size: 28, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("You've grounded yourself in the present moment")
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation {
                        groundingManager.reset()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Restart")
                            .fontDesign(.serif)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppConstants.primaryColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppConstants.primaryColor.opacity(0.1))
                    .cornerRadius(24)
                }
                
                Button(action: {
                    if groundingManager.hapticsEnabled {
                        groundingManager.lightHaptic.impactOccurred(intensity: 0.5)
                    }
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Text("Done")
                            .fontDesign(.serif)
                        Image(systemName: "checkmark")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppConstants.primaryColor)
                    .cornerRadius(24)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
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

// MARK: - Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    GroundingView()
}
