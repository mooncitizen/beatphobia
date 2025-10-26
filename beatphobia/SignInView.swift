//
//  SignInView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI
import Combine
import Supabase

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            AppConstants.defaultBackgroundColor
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomeScreen(currentPage: $currentPage)
                    .tag(0)
                
                AboutAppScreen(currentPage: $currentPage)
                    .tag(1)
                
                DisclaimerScreen(currentPage: $currentPage)
                    .tag(2)
                
                AuthScreen()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            
            // Custom page indicators
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? AppConstants.primaryColor : Color.black.opacity(0.2))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.primaryColor.opacity(0.2),
                                AppConstants.primaryColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.primaryColor.opacity(0.3),
                                AppConstants.primaryColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundColor(AppConstants.primaryColor)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black.opacity(0.6))
                
                Text(AppConstants.appName)
                    .font(.system(size: 48, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Your journey to overcome anxiety starts here")
                    .font(.system(size: 17))
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                HStack(spacing: 12) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
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
            .padding(.bottom, 80)
        }
    }
}

// MARK: - About App Screen
struct AboutAppScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 60)
                
                VStack(spacing: 16) {
                    Text("Tools to Help You Thrive")
                        .font(.system(size: 36, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Text("Everything you need to manage anxiety and track your progress")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "map.fill",
                        color: .blue,
                        title: "Journey Tracker",
                        description: "Track your location and emotions as you face your fears"
                    )
                    
                    FeatureCard(
                        icon: "wind",
                        color: .green,
                        title: "Breathing Exercises",
                        description: "Calm your nervous system with guided techniques"
                    )
                    
                    FeatureCard(
                        icon: "book.fill",
                        color: .orange,
                        title: "Daily Journal",
                        description: "Record your thoughts and track emotional patterns"
                    )
                    
                    FeatureCard(
                        icon: "person.3.fill",
                        color: .purple,
                        title: "Community Support",
                        description: "Connect with others on the same journey"
                    )
                }
                .padding(.horizontal, 30)
                
                Button(action: {
                    withAnimation {
                        currentPage = 2
                    }
                }) {
                    HStack(spacing: 12) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.rounded)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
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
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Disclaimer Screen
struct DisclaimerScreen: View {
    @Binding var currentPage: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 16) {
                    Text("Important Notice")
                        .font(.system(size: 32, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("This app is designed to support you, but it does not replace professional medical advice, diagnosis, or treatment.")
                        .font(.system(size: 17))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                }
                
                VStack(spacing: 16) {
                    DisclaimerPoint(
                        icon: "cross.case.fill",
                        text: "Always consult with qualified healthcare professionals"
                    )
                    
                    DisclaimerPoint(
                        icon: "phone.arrow.up.right.fill",
                        text: "If experiencing a crisis, contact emergency services immediately"
                    )
                    
                    DisclaimerPoint(
                        icon: "heart.text.square.fill",
                        text: "Use this app as a complementary tool alongside professional care"
                    )
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    currentPage = 3
                }
            }) {
                HStack(spacing: 12) {
                    Text("I Understand")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
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
                .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 15, y: 8)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 80)
        }
    }
}

struct DisclaimerPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppConstants.primaryColor)
                .frame(width: 40)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}

// MARK: - Auth Screen
struct AuthScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var displayErrorMessage: String?
    @State private var displaySuccessMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 60)
                
                VStack(spacing: 8) {
                    Text(isSigningUp ? "Create Account" : "Welcome Back")
                        .font(.system(size: 36, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(.black)
                    
                    Text(isSigningUp ? "Start your journey today" : "Sign in to continue")
                        .font(.system(size: 16))
                        .foregroundColor(.black.opacity(0.6))
                }
                
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        TextField("your@email.com", text: $email)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(.black)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        SecureField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                            )
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 30)
                
                // Error/Success Messages
                if let errorMessage = displayErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                }
                
                if let successMessage = displaySuccessMessage {
                    Text(successMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.green)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                }
                
                // Main Action Button
                Button(action: {
                    handleAuthAction()
                }) {
                    Text(isSigningUp ? "Create Account" : "Sign In")
                        .font(.system(size: 18, weight: .bold))
                        .fontDesign(.rounded)
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
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                // Toggle Button
                Button(action: {
                    withAnimation {
                        isSigningUp.toggle()
                        displayErrorMessage = nil
                        displaySuccessMessage = nil
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(isSigningUp ? "Already have an account?" : "Don't have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.6))
                        
                        Text(isSigningUp ? "Sign In" : "Create One")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    func handleAuthAction() {
        displayErrorMessage = nil
        displaySuccessMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            displayErrorMessage = "Please enter both email and password"
            return
        }
        
        Task {
            if isSigningUp {
                await handleSignUp()
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
    
    private func handleSignUp() async {
        await authManager.signUp(email: email, password: password)
        if authManager.authError == nil {
            if authManager.authState == .signedOut {
                displaySuccessMessage = "Registration successful! Please check your email inbox (and spam folder) to confirm your account."
            }
        }
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .fontDesign(.rounded)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, y: 4)
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
}
