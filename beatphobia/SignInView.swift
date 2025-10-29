//
//  SignInView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI
import Combine
import Supabase
import AuthenticationServices
import CryptoKit

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @State private var currentPage: Int = 0
    
    var body: some View {
        ZStack {
            AppConstants.backgroundColor(for: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                WelcomeScreen(currentPage: $currentPage, colorScheme: colorScheme)
                    .tag(0)
                
                AboutAppScreen(currentPage: $currentPage, colorScheme: colorScheme)
                    .tag(1)
                
                DisclaimerScreen(currentPage: $currentPage, colorScheme: colorScheme)
                    .tag(2)
                
                AuthScreen(colorScheme: colorScheme)
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
                            .fill(currentPage == index ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.3))
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
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.2),
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.05)
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
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.3),
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 70, weight: .semibold))
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
            }
            
            VStack(spacing: 16) {
                Text("Welcome to")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                Text(AppConstants.appName)
                    .font(.system(size: 48, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("Your journey to overcome anxiety starts here")
                    .font(.system(size: 17))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
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
                            AppConstants.adaptivePrimaryColor(for: colorScheme),
                            AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 15, y: 8)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 80)
        }
    }
}

// MARK: - About App Screen
struct AboutAppScreen: View {
    @Binding var currentPage: Int
    let colorScheme: ColorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 60)
                
                VStack(spacing: 16) {
                    Text("Tools to Help You Thrive")
                        .font(.system(size: 36, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Text("Everything you need to manage anxiety and track your progress")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "map.fill",
                        color: .blue,
                        title: "Journey Tracker",
                        description: "Track your location and emotions as you face your fears",
                        colorScheme: colorScheme
                    )
                    
                    FeatureCard(
                        icon: "wind",
                        color: .green,
                        title: "Breathing Exercises",
                        description: "Calm your nervous system with guided techniques",
                        colorScheme: colorScheme
                    )
                    
                    FeatureCard(
                        icon: "book.fill",
                        color: .orange,
                        title: "Daily Journal",
                        description: "Record your thoughts and track emotional patterns",
                        colorScheme: colorScheme
                    )
                    
                    FeatureCard(
                        icon: "person.3.fill",
                        color: .purple,
                        title: "Community Support",
                        description: "Connect with others on the same journey",
                        colorScheme: colorScheme
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
                                AppConstants.adaptivePrimaryColor(for: colorScheme),
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 15, y: 8)
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
    let colorScheme: ColorScheme
    
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
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text("This app is designed to support you, but it does not replace professional medical advice, diagnosis, or treatment.")
                        .font(.system(size: 17))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)
                }
                
                VStack(spacing: 16) {
                    DisclaimerPoint(
                        icon: "cross.case.fill",
                        text: "Always consult with qualified healthcare professionals",
                        colorScheme: colorScheme
                    )
                    
                    DisclaimerPoint(
                        icon: "phone.arrow.up.right.fill",
                        text: "If experiencing a crisis, contact emergency services immediately",
                        colorScheme: colorScheme
                    )
                    
                    DisclaimerPoint(
                        icon: "heart.text.square.fill",
                        text: "Use this app as a complementary tool alongside professional care",
                        colorScheme: colorScheme
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
                            AppConstants.adaptivePrimaryColor(for: colorScheme),
                            AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 15, y: 8)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 80)
        }
    }
}

struct DisclaimerPoint: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                .frame(width: 40)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 4)
    }
}

// MARK: - Sign in with Apple Coordinator
class SignInWithAppleCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    var authManager: AuthManager?
    var currentNonce: String?
    
    func signInWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // Provide presentation context
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("🍎 Apple authorization received")
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            print("❌ Failed to cast to ASAuthorizationAppleIDCredential")
            return
        }
        
        guard let identityToken = credential.identityToken else {
            print("❌ No identity token in credential")
            return
        }
        
        guard let tokenString = String(data: identityToken, encoding: .utf8) else {
            print("❌ Failed to decode identity token")
            return
        }
        
        guard let nonce = currentNonce else {
            print("❌ No current nonce available")
            return
        }
        
        print("✅ Got Apple credential successfully")
        print("   - User ID: \(credential.user)")
        print("   - Token length: \(tokenString.count)")
        print("   - Nonce: \(nonce)")
        
        Task {
            await authManager?.signInWithApple(idToken: tokenString, nonce: nonce)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Error 1000 is user cancellation - don't show error for this
        let nsError = error as NSError
        if nsError.code == 1000 {
            print("ℹ️ User canceled Apple Sign In")
            return
        }
        
        print("❌ Sign in with Apple error: \(error.localizedDescription)")
        Task {
            await MainActor.run {
                self.authManager?.authError = error
            }
        }
    }
    
    // Generate random nonce for security
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    // Hash nonce with SHA256
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Screen
struct AuthScreen: View {
    @EnvironmentObject var authManager: AuthManager
    let colorScheme: ColorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var displayErrorMessage: String?
    @State private var displaySuccessMessage: String?
    @State private var appleSignInCoordinator = SignInWithAppleCoordinator()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 60)
                
                VStack(spacing: 8) {
                    Text(isSigningUp ? "Create Account" : "Welcome Back")
                        .font(.system(size: 36, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text(isSigningUp ? "Start your journey today" : "Sign in to continue")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        TextField("your@email.com", text: $email)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        SecureField("Enter your password", text: $password)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                            )
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }
                }
                .padding(.horizontal, 30)
                
                // Error/Success Messages
                if let errorMessage = displayErrorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
                } else if let authError = authManager.authError {
                    Text(authError.localizedDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                        .multilineTextAlignment(.center)
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
                                    AppConstants.adaptivePrimaryColor(for: colorScheme),
                                    AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 15, y: 8)
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                // Divider with "or"
                HStack(spacing: 16) {
                    Rectangle()
                        .fill(AppConstants.borderColor(for: colorScheme))
                        .frame(height: 1)
                    
                    Text("or")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Rectangle()
                        .fill(AppConstants.borderColor(for: colorScheme))
                        .frame(height: 1)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 8)
                
                // Sign in with Apple Button
                Button(action: {
                    // Clear any existing errors
                    displayErrorMessage = nil
                    displaySuccessMessage = nil
                    authManager.authError = nil
                    
                    appleSignInCoordinator.signInWithApple()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text("Continue with Apple")
                            .font(.system(size: 17, weight: .semibold))
                            .fontDesign(.rounded)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                
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
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        Text(isSigningUp ? "Sign In" : "Create One")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            // Connect coordinator to authManager
            appleSignInCoordinator.authManager = authManager
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
    let colorScheme: ColorScheme
    
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 10, y: 4)
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthManager())
        .environmentObject(ThemeManager())
}
