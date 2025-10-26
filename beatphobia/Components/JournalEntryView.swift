//
//  JournalEntryView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 20/10/2025.
//
import SwiftUI
import RealmSwift


struct JournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    
    let mood: Mood
    
    @State private var journalText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    private var characterCount: Int {
        journalText.count
    }
    
    private var canSave: Bool {
        !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.defaultBackgroundColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with mood
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Text editor card
                        textEditorCard
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(characterCount) characters")
                                .font(.system(size: 13))
                                .foregroundColor(AppConstants.primaryColor.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 100)
                    }
                }
                
                // Bottom buttons (fixed at bottom)
                VStack {
                    Spacer()
                    bottomButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        lightHaptic.impactOccurred(intensity: 0.5)
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
            .onAppear {
                lightHaptic.prepare()
                mediumHaptic.prepare()
                
                // Auto-focus text editor
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Mood icon in a circle
            ZStack {
                Circle()
                    .fill(getMoodColor().opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: mood.iconName)
                    .font(.system(size: 38, weight: .medium))
                    .foregroundColor(getMoodColor())
            }
            
            // Title and description
            VStack(spacing: 8) {
                Text("Feeling \(mood.text)")
                    .font(.system(size: 28, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("Take a moment to express your thoughts and feelings")
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Text Editor Card
    private var textEditorCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Placeholder
                if journalText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's on your mind?")
                            .font(.system(size: 16))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        Text("Write about your day, your feelings, or anything you'd like to remember...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
                }
                
                // Text Editor
                TextEditor(text: $journalText)
                    .font(.system(size: 16))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryColor)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(minHeight: 300)
                    .focused($isTextEditorFocused)
            }
            .background(Color.white)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        }
    }
    
    // MARK: - Bottom Buttons
    private var bottomButtons: some View {
        VStack(spacing: 0) {
            // Gradient fade at top
            LinearGradient(
                colors: [
                    AppConstants.defaultBackgroundColor.opacity(0),
                    AppConstants.defaultBackgroundColor
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            HStack(spacing: 12) {
                // Cancel button
                Button(action: {
                    lightHaptic.impactOccurred(intensity: 0.5)
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 17, weight: .semibold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppConstants.primaryColor.opacity(0.1))
                        .cornerRadius(27)
                }
                
                // Save button
                Button(action: {
                    saveEntry()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Save Entry")
                            .font(.system(size: 17, weight: .semibold))
                            .fontDesign(.serif)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canSave ? getMoodColor() : Color.gray.opacity(0.4))
                    .cornerRadius(27)
                    .shadow(color: canSave ? getMoodColor().opacity(0.3) : .clear, radius: 10, y: 5)
                }
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(AppConstants.defaultBackgroundColor)
        }
    }
    
    // MARK: - Actions
    private func saveEntry() {
        mediumHaptic.impactOccurred(intensity: 0.8)
        
        let newEntry = JournalEntryModel()
        newEntry.id = UUID()
        newEntry.mood = mood
        newEntry.date = Date()
        newEntry.text = journalText
        
        let realm = try! Realm()
        try! realm.write {
            realm.add(newEntry)
        }
        
        // Success haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let successHaptic = UINotificationFeedbackGenerator()
            successHaptic.notificationOccurred(.success)
        }
        
        dismiss()
    }
    
    // MARK: - Helper Functions
    private func getMoodColor() -> Color {
        switch mood {
        case .happy: return .green
        case .excited: return .orange
        case .angry: return .red
        case .stressed: return .purple
        case .sad: return .blue
        case .none: return .white
        }
    }
}

#Preview {
    JournalEntryView(mood: .happy)
}
