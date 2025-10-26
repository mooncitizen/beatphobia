//
//  UsernameSetupView.swift
//  beatphobia
//
//  Reusable username setup screen
//

import SwiftUI
import Supabase

struct UsernameSetupView: View {
    let onComplete: () -> Void
    
    @State private var username: String = ""
    @State private var isChecking = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var isAvailable: Bool?
    @FocusState private var isFocused: Bool
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var normalizedUsername: String {
        username.lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isValid: Bool {
        let normalized = normalizedUsername
        return normalized.count >= 3 && 
               normalized.count <= 30 && 
               normalized.range(of: "^[a-z0-9_-]+$", options: .regularExpression) != nil
    }
    
    var validationMessage: String? {
        let normalized = normalizedUsername
        
        if normalized.isEmpty {
            return nil
        }
        
        if normalized.count < 3 {
            return "Username must be at least 3 characters"
        }
        
        if normalized.count > 30 {
            return "Username must be 30 characters or less"
        }
        
        if normalized.range(of: "^[a-z0-9_-]+$", options: .regularExpression) == nil {
            return "Only lowercase letters, numbers, _ and - allowed"
        }
        
        return nil
    }
    
    var canSubmit: Bool {
        isValid && isAvailable == true && !isSubmitting
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)
                    
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AppConstants.primaryColor.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "at")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                    
                    // Header
                    VStack(spacing: 12) {
                        Text("Choose Your Username")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Text("Your username is how others will see you in the community")
                            .font(.system(size: 16))
                            .foregroundColor(.black.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Username Input
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Text("@")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.black.opacity(0.3))
                            
                            TextField("username", text: $username)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppConstants.primaryColor)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($isFocused)
                                .onChange(of: username) { _ in
                                    // Auto-convert to lowercase
                                    username = username.lowercased()
                                    // Reset availability check
                                    isAvailable = nil
                                    errorMessage = nil
                                    // Check availability with debounce
                                    scheduleAvailabilityCheck()
                                }
                            
                            if isChecking {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if let isAvailable = isAvailable {
                                Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(isAvailable ? .green : .red)
                            }
                        }
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isAvailable == true ? Color.green :
                                    isAvailable == false ? Color.red :
                                    isFocused ? AppConstants.primaryColor :
                                    Color.black.opacity(0.1),
                                    lineWidth: 2
                                )
                        )
                        
                        // Validation/Error Messages
                        if let validation = validationMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 12))
                                Text(validation)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.orange)
                        } else if let error = errorMessage {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                Text(error)
                                    .font(.system(size: 13))
                            }
                            .foregroundColor(.red)
                        } else if isAvailable == true {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                Text("@\(normalizedUsername) is available!")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Guidelines
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Username Guidelines")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        GuidelineRow(icon: "checkmark", text: "3-30 characters long")
                        GuidelineRow(icon: "checkmark", text: "Lowercase letters (a-z)")
                        GuidelineRow(icon: "checkmark", text: "Numbers (0-9)")
                        GuidelineRow(icon: "checkmark", text: "Underscores (_) and hyphens (-)")
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: submitUsername) {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Creating...")
                            } else {
                                Text("Continue")
                            }
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSubmit ? AppConstants.primaryColor : Color.gray)
                        .cornerRadius(16)
                    }
                    .disabled(!canSubmit)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .background(AppConstants.defaultBackgroundColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            lightHaptic.prepare()
            mediumHaptic.prepare()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .interactiveDismissDisabled() // Prevent dismissal until username is set
    }
    
    // MARK: - Availability Check
    
    private func scheduleAvailabilityCheck() {
        // Cancel previous check
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        guard isValid else {
            isAvailable = nil
            return
        }
        
        // Schedule new check after 0.5 second delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkUsernameAvailability()
        }
    }
    
    private func checkUsernameAvailability() {
        guard isValid else { return }
        
        isChecking = true
        errorMessage = nil
        
        Task {
            do {
                // Check if username exists
                let response: [Profile] = try await supabase
                    .from("profile")
                    .select()
                    .eq("username", value: normalizedUsername)
                    .execute()
                    .value
                
                await MainActor.run {
                    isChecking = false
                    isAvailable = response.isEmpty
                    if !response.isEmpty {
                        errorMessage = "Username is already taken"
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    errorMessage = "Could not check availability"
                }
            }
        }
    }
    
    // MARK: - Submit
    
    private func submitUsername() {
        guard canSubmit else { return }
        
        isSubmitting = true
        mediumHaptic.impactOccurred(intensity: 0.7)
        
        Task {
            do {
                let userId = try await supabase.auth.session.user.id
                
                // Update profile with username
                try await supabase
                    .from("profile")
                    .update(["username": normalizedUsername])
                    .eq("id", value: userId.uuidString)
                    .execute()
                
                await MainActor.run {
                    isSubmitting = false
                    mediumHaptic.impactOccurred(intensity: 1.0)
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to save username. Please try again."
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct GuidelineRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon + ".circle.fill")
                .font(.system(size: 12))
                .foregroundColor(AppConstants.primaryColor.opacity(0.7))
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

// MARK: - Preview

#Preview {
    UsernameSetupView {
        print("Username setup complete!")
    }
}

