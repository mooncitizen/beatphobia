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

// MARK: - Onboarding Step Enum
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case about = 1
    case disclaimer = 2
    case contentModeration = 3
    case eula = 4
    case auth = 5
    
    var isLast: Bool {
        self == .auth
    }
    
    var canGoBack: Bool {
        self != .welcome
    }
}

// MARK: - Sign In Onboarding View Model
@MainActor
class SignInOnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var hasAcceptedEULA: Bool = false
    private let onboardingCompletedKey = "onboarding_completed"
    
    var isEULAAccepted: Bool {
        UserDefaults.standard.bool(forKey: "eula_accepted")
    }
    
    init() {
        // Load saved EULA acceptance
        hasAcceptedEULA = isEULAAccepted
        
        // If EULA already accepted and onboarding completed, skip to auth
        if hasAcceptedEULA && UserDefaults.standard.bool(forKey: onboardingCompletedKey) {
            currentStep = .auth
        }
    }
    
    func next() {
        // Block progression from EULA if not accepted
        if currentStep == .eula && !hasAcceptedEULA {
            return
        }
        
        // Save EULA acceptance when moving forward from EULA
        if currentStep == .eula && hasAcceptedEULA {
            UserDefaults.standard.set(true, forKey: "eula_accepted")
            UserDefaults.standard.set(Date(), forKey: "eula_accepted_date")
        }
        
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex < OnboardingStep.allCases.count - 1 else {
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let nextStep = OnboardingStep.allCases[currentIndex + 1]
            currentStep = nextStep
            // Mark onboarding completed when we reach auth screen
            if nextStep == .auth {
                UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
            }
        }
    }
    
    func previous() {
        // Can't go back from EULA if not accepted (but can go back if accepted)
        guard let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep),
              currentIndex > 0 else {
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = OnboardingStep.allCases[currentIndex - 1]
        }
    }
    
    func acceptEULA() {
        hasAcceptedEULA = true
    }
}

// MARK: - Sign In View
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = SignInOnboardingViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content fills available space
            Group {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeOnboardingView(viewModel: viewModel, colorScheme: colorScheme)
                case .about:
                    AboutOnboardingView(viewModel: viewModel, colorScheme: colorScheme)
                case .disclaimer:
                    DisclaimerOnboardingView(viewModel: viewModel, colorScheme: colorScheme)
                case .contentModeration:
                    ContentModerationOnboardingView(viewModel: viewModel, colorScheme: colorScheme)
                case .eula:
                    EULAOnboardingView(viewModel: viewModel, colorScheme: colorScheme)
                case .auth:
                    AuthScreen(colorScheme: colorScheme)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppConstants.backgroundColor(for: colorScheme).ignoresSafeArea())
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // Navigation Controls (not shown on auth screen)
            if viewModel.currentStep != .auth {
                VStack(spacing: 0) {
                    // Page Indicators
                    HStack(spacing: 8) {
                        ForEach(OnboardingStep.allCases.dropLast(), id: \.rawValue) { step in
                            Capsule()
                                .fill(
                                    step.rawValue <= viewModel.currentStep.rawValue ?
                                    AppConstants.adaptivePrimaryColor(for: colorScheme) :
                                    AppConstants.secondaryTextColor(for: colorScheme).opacity(0.3)
                                )
                                .frame(
                                    width: step == viewModel.currentStep ? 24 : 8,
                                    height: 8
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentStep)
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if viewModel.currentStep.canGoBack {
                            Button(action: { viewModel.previous() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .semibold))
                                        .fontDesign(.rounded)
                                }
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.1))
                                .cornerRadius(16)
                            }
                        }

                        Button(action: { viewModel.next() }) {
                            HStack(spacing: 8) {
                                Text(viewModel.currentStep == .eula ? "Accept & Continue" : "Continue")
                                    .font(.system(size: 16, weight: .bold))
                                    .fontDesign(.rounded)
                                if viewModel.currentStep != .eula {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [
                                        canProceed() ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme),
                                        canProceed() ? AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: canProceed() ? AppConstants.shadowColor(for: colorScheme) : Color.clear, radius: 10, y: 4)
                        }
                        .disabled(!canProceed())
                        .opacity(canProceed() ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                    .background(AppConstants.backgroundColor(for: colorScheme).ignoresSafeArea(edges: .bottom))
                }
            }
        }
        .id(viewModel.currentStep)
    }
    
    private func canProceed() -> Bool {
        if viewModel.currentStep == .eula {
            return viewModel.hasAcceptedEULA
        }
        return true
    }
}

// MARK: - Welcome Onboarding View
struct WelcomeOnboardingView: View {
    @ObservedObject var viewModel: SignInOnboardingViewModel
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Icon/Logo
            AppIconView(colorScheme: colorScheme)
                .frame(width: 90, height: 90)
            
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
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - About Onboarding View
struct AboutOnboardingView: View {
    @ObservedObject var viewModel: SignInOnboardingViewModel
    let colorScheme: ColorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 40)
                
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
                
                // Removed bottom spacer; navigation is now fixed below content
            }
        }
    }
}

// MARK: - Disclaimer Onboarding View
struct DisclaimerOnboardingView: View {
    @ObservedObject var viewModel: SignInOnboardingViewModel
    let colorScheme: ColorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
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
                    Text("Important Disclaimer")
                        .font(.system(size: 32, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text("This app is not a substitute for professional medical advice, diagnosis, or treatment")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    DisclaimerPoint(
                        icon: "stethoscope",
                        text: "Always seek the advice of qualified health providers with any questions you may have regarding a medical condition",
                        colorScheme: colorScheme
                    )
                    
                    DisclaimerPoint(
                        icon: "phone.fill",
                        text: "If you are experiencing a medical emergency, call emergency services immediately",
                        colorScheme: colorScheme
                    )
                    
                    DisclaimerPoint(
                        icon: "heart.text.square.fill",
                        text: "This app is designed to support your mental health journey, not replace professional care",
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal, 30)
                
                // Removed bottom spacer; navigation is now fixed below content
            }
        }
    }
}

// MARK: - Content Moderation Onboarding View
struct ContentModerationOnboardingView: View {
    @ObservedObject var viewModel: SignInOnboardingViewModel
    let colorScheme: ColorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 40)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 16) {
                    Text("Safe & Moderated Community")
                        .font(.system(size: 32, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                    
                    Text("Your safety and well-being are our top priorities")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    ModerationPoint(
                        icon: "eye.fill",
                        title: "Active Monitoring",
                        text: "All content is actively monitored for safety, harassment, and inappropriate material",
                        colorScheme: colorScheme
                    )
                    
                    ModerationPoint(
                        icon: "flag.fill",
                        title: "Report & Block",
                        text: "You can report objectionable content and block users who violate community guidelines",
                        colorScheme: colorScheme
                    )
                    
                    ModerationPoint(
                        icon: "clock.fill",
                        title: "Quick Response",
                        text: "Reports are reviewed within 24 hours by our moderation team",
                        colorScheme: colorScheme
                    )
                    
                    ModerationPoint(
                        icon: "lock.shield.fill",
                        title: "Zero Tolerance",
                        text: "We have a zero-tolerance policy for harassment, hate speech, or harmful content",
                        colorScheme: colorScheme
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer()
                    .frame(height: 120) // Space for navigation buttons
            }
        }
    }
}

// MARK: - Moderation Point View
struct ModerationPoint: View {
    let icon: String
    let title: String
    let text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(text)
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - EULA Onboarding View
struct EULAOnboardingView: View {
    @ObservedObject var viewModel: SignInOnboardingViewModel
    let colorScheme: ColorScheme
    @State private var eulaText: String = ""
    @State private var isLoadingEULA: Bool = true
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    
                    Text("End User License Agreement")
                        .font(.system(size: 24, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 30)
                    
                    Text("Please read and accept the terms to continue")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                // EULA Content - Properly scrollable
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if isLoadingEULA {
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Loading EULA...")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            Text(eulaText)
                                .font(.system(size: 13, design: .serif))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                .lineSpacing(4)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                    .frame(minHeight: geometry.size.height * 0.4)
                }
                .frame(height: min(geometry.size.height * 0.5, 400))
                
                // Acceptance Checkbox
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation {
                            viewModel.hasAcceptedEULA.toggle()
                            if viewModel.hasAcceptedEULA {
                                viewModel.acceptEULA()
                            }
                        }
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(viewModel.hasAcceptedEULA ? AppConstants.adaptivePrimaryColor(for: colorScheme) : Color.clear)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 2)
                                )
                            
                            if viewModel.hasAcceptedEULA {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("I have read and agree to the End User License Agreement")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 4)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 20)
                // Removed bottom spacer; navigation is now fixed below content
            }
        }
        .padding(.horizontal, 0)
        .task {
            await loadEULA()
        }
    }
    
    private func loadEULA() async {
        guard let url = Bundle.main.url(forResource: "eula", withExtension: "txt", subdirectory: "Legal") else {
            // Fallback: try without subdirectory
            guard let fallbackURL = Bundle.main.url(forResource: "eula", withExtension: "txt") else {
                eulaText = "Error: Could not load EULA file. Please contact support."
                isLoadingEULA = false
                return
            }
            
            do {
                eulaText = try String(contentsOf: fallbackURL, encoding: .utf8)
            } catch {
                eulaText = "Error loading EULA: \(error.localizedDescription)"
            }
            isLoadingEULA = false
            return
        }
        
        do {
            eulaText = try String(contentsOf: url, encoding: .utf8)
        } catch {
            eulaText = "Error loading EULA: \(error.localizedDescription)"
        }
        
        isLoadingEULA = false
    }
}

// MARK: - App Icon View
struct AppIconView: View {
    let colorScheme: ColorScheme
    @State private var appIconImage: UIImage?
    
    var body: some View {
        Group {
            if let iconImage = appIconImage {
                Image(uiImage: iconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 15, y: 8)
            } else {
                // Fallback while loading
                RoundedRectangle(cornerRadius: 40)
                    .fill(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.1))
                    .frame(width: 180, height: 180)
                    .overlay(
                        ProgressView()
                            .tint(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    )
            }
        }
        .onAppear {
            loadAppIcon()
        }
    }
    
    private func loadAppIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            var iconImage: UIImage?
            
            // Method 1: Try regular image asset (most reliable if added)
            if let assetImage = UIImage(named: "app_icon") {
                iconImage = assetImage
            }
            else if let assetImage = UIImage(named: "AppIconLarge") {
                iconImage = assetImage
            }
            // Method 2: Try ss_web.png (if it's in bundle)
            else if let webPath = Bundle.main.path(forResource: "ss_web", ofType: "png"),
               let webImage = UIImage(contentsOfFile: webPath) {
                iconImage = webImage
            }
            // Method 3: Try legacy names
            else if let assetImage = UIImage(named: "ss_light") {
                iconImage = assetImage
            }
            else if let assetImage = UIImage(named: "ss_dark") {
                iconImage = assetImage
            }
            // Method 3: Search bundle for icon files
            else if let foundPath = findIconInBundle() {
                iconImage = UIImage(contentsOfFile: foundPath)
            }
            
            DispatchQueue.main.async {
                self.appIconImage = iconImage
            }
        }
    }
    
    private func findIconInBundle() -> String? {
        guard let resourcePath = Bundle.main.resourcePath else { return nil }
        let fileManager = FileManager.default
        
        // Search for icon files
        let searchNames = ["ss_light", "ss_dark", "ss_web", "AppIcon"]
        
        for name in searchNames {
            // Try direct path
            if let path = Bundle.main.path(forResource: name, ofType: "png") {
                return path
            }
            
            // Try searching in subdirectories
            if let enumerator = fileManager.enumerator(atPath: resourcePath) {
                for case let path as String in enumerator {
                    if path.contains(name) && path.hasSuffix(".png") {
                        let fullPath = (resourcePath as NSString).appendingPathComponent(path)
                        if fileManager.fileExists(atPath: fullPath) {
                            return fullPath
                        }
                    }
                }
            }
        }
        
        return nil
    }
}

// MARK: - Supporting Views
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
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            AppConstants.secondaryTextColor(for: colorScheme).opacity(0.05)
        )
        .cornerRadius(16)
    }
}

struct DisclaimerPoint: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

// MARK: - Auth Screen (keeping existing implementation)
struct AuthScreen: View {
    @EnvironmentObject var authManager: AuthManager
    let colorScheme: ColorScheme
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningUp = false
    @State private var displayErrorMessage: String?
    @State private var displaySuccessMessage: String?
    @State private var showEULAPopup = false
    @State private var pendingAuthAction: AuthAction?
    @State private var appleNonce: String?
    
    enum AuthAction {
        case signIn
        case signUp
        case appleSignIn
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Spacer()
                    .frame(height: 60)
                
                // Header
                VStack(spacing: 16) {
                    Text("Get Started")
                        .font(.system(size: 42, weight: .bold))
                        .fontDesign(.serif)
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Create an account or sign in to continue")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 30)
                
                // Email/Password Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(.plain)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .padding(16)
                            .background(
                                AppConstants.secondaryTextColor(for: colorScheme).opacity(0.1)
                            )
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(.plain)
                            .padding(16)
                            .background(
                                AppConstants.secondaryTextColor(for: colorScheme).opacity(0.1)
                            )
                            .cornerRadius(12)
                    }
                    
                    // Error/Success Messages
                    if let errorMessage = displayErrorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    if let successMessage = displaySuccessMessage {
                        Text(successMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                            .padding(.horizontal)
                    }
                    
                    // Sign Up / Sign In Button
                    Button(action: {
                        handleAuthAction(isSigningUp ? .signUp : .signIn)
                    }) {
                        HStack(spacing: 12) {
                            Text(isSigningUp ? "Create Account" : "Sign In")
                                .font(.system(size: 18, weight: .bold))
                                .fontDesign(.rounded)
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
                    
                    // Toggle Sign Up / Sign In
                    Button(action: {
                        withAnimation {
                            isSigningUp.toggle()
                            displayErrorMessage = nil
                            displaySuccessMessage = nil
                        }
                    }) {
                        Text(isSigningUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    }
                }
                .padding(.horizontal, 30)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                
                // Sign in with Apple
                SignInWithAppleButtonView(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        // Generate and attach nonce for Apple request
                        let nonce = randomNonceString()
                        appleNonce = nonce
                        request.nonce = sha256(nonce)
                    },
                    onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            handleAppleSignIn(authorization: authorization)
                        case .failure(let error):
                            displayErrorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                        }
                    }
                )
                .frame(height: 56)
                .frame(maxWidth: 375)
                .cornerRadius(16)
                .padding(.horizontal, 30)
                
                Spacer()
                    .frame(height: 40)
            }
        }
        .sheet(isPresented: $showEULAPopup) {
            EULAPopupView(onAccept: {
                handlePendingAuthAction()
            })
        }
    }
    
    private func handleAuthAction(_ action: AuthAction) {
        let isEULAAccepted = UserDefaults.standard.bool(forKey: "eula_accepted")
        
        if !isEULAAccepted {
            pendingAuthAction = action
            showEULAPopup = true
        } else {
            executeAuthAction(action)
        }
    }
    
    private func handlePendingAuthAction() {
        if let action = pendingAuthAction {
            executeAuthAction(action)
            pendingAuthAction = nil
        }
    }
    
    private func executeAuthAction(_ action: AuthAction) {
        switch action {
        case .signIn:
            Task {
                await signIn()
            }
        case .signUp:
            Task {
                await signUp()
            }
        case .appleSignIn:
            // Apple Sign In is handled by the button
            break
        }
    }
    
    private func handleAppleSignIn(authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            displayErrorMessage = "Failed to get Apple ID credential"
            return
        }
        
        Task {
            await performAppleSignIn(credential: appleIDCredential)
        }
    }
    
    private func signIn() async {
        displayErrorMessage = nil
        displaySuccessMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            displayErrorMessage = "Please enter both email and password"
            return
        }
        
        do {
            try await authManager.signIn(email: email, password: password)
            displaySuccessMessage = "Signed in successfully!"
        } catch {
            displayErrorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
    
    private func signUp() async {
        displayErrorMessage = nil
        displaySuccessMessage = nil
        
        guard !email.isEmpty, !password.isEmpty else {
            displayErrorMessage = "Please enter both email and password"
            return
        }
        
        guard password.count >= 6 else {
            displayErrorMessage = "Password must be at least 6 characters"
            return
        }
        
        do {
            try await authManager.signUp(email: email, password: password)
            displaySuccessMessage = "Account created! Please check your email to verify your account."
        } catch {
            displayErrorMessage = "Sign up failed: \(error.localizedDescription)"
        }
    }
    
    private func performAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        displayErrorMessage = nil
        displaySuccessMessage = nil
        
        guard let identityToken = credential.identityToken,
              let identityTokenString = String(data: identityToken, encoding: .utf8) else {
            displayErrorMessage = "Failed to get Apple ID token"
            return
        }
        
        // Use the same raw nonce that was attached to the request
        let nonceToUse: String
        if let n = appleNonce {
            nonceToUse = n
        } else {
            // Fallback (should not happen): generate a new one to avoid crash
            nonceToUse = randomNonceString()
        }
        
        do {
            try await authManager.signInWithApple(idToken: identityTokenString, nonce: nonceToUse)
            displaySuccessMessage = "Signed in with Apple successfully!"
        } catch {
            displayErrorMessage = "Apple Sign In failed: \(error.localizedDescription)"
        }
    }
    
    // Helper functions for Apple Sign In
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Sign In With Apple Button View
struct SignInWithAppleButtonView: UIViewRepresentable {
    let onRequest: (ASAuthorizationAppleIDRequest) -> Void
    let onCompletion: (Result<ASAuthorization, Error>) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.cornerRadius = 16
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleTap), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }
    
    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        
        init(onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void, onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }
        
        @objc func handleTap() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }
        
        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }
        
        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window found")
            }
            return window
        }
    }
}

// MARK: - EULA Popup Modal (for auth screen)
struct EULAPopupView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var eulaText: String = ""
    @State private var hasAcceptedEULA: Bool = false
    @State private var isLoadingEULA: Bool = true
    let onAccept: () -> Void
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.blue)
                        }
                        
                        Text("End User License Agreement")
                            .font(.system(size: 24, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Text("Please read and accept the terms to continue")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                    
                    // EULA Content - Properly scrollable with fixed height
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if isLoadingEULA {
                                VStack(spacing: 16) {
                                    ProgressView()
                                    Text("Loading EULA...")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                Text(eulaText)
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    .lineSpacing(4)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                        .frame(minHeight: geometry.size.height * 0.4)
                    }
                    .frame(height: min(geometry.size.height * 0.5, 400))
                    
                    // Acceptance Checkbox
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                hasAcceptedEULA.toggle()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(hasAcceptedEULA ? AppConstants.adaptivePrimaryColor(for: colorScheme) : Color.clear)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 2)
                                    )
                                
                                if hasAcceptedEULA {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("I have read and agree to the End User License Agreement")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Accept Button
                    Button(action: {
                        if hasAcceptedEULA {
                            // Save acceptance to UserDefaults
                            UserDefaults.standard.set(true, forKey: "eula_accepted")
                            UserDefaults.standard.set(Date(), forKey: "eula_accepted_date")
                            
                            onAccept()
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Text("Accept & Continue")
                                .font(.system(size: 17, weight: .bold))
                                .fontDesign(.rounded)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [
                                    hasAcceptedEULA ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme),
                                    hasAcceptedEULA ? AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.8) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: hasAcceptedEULA ? AppConstants.shadowColor(for: colorScheme) : Color.clear, radius: 10, y: 4)
                    }
                    .disabled(!hasAcceptedEULA)
                    .opacity(hasAcceptedEULA ? 1.0 : 0.5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    
                    Spacer()
                }
                .background(AppConstants.backgroundColor(for: colorScheme))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.primaryColor)
                }
            }
        }
        .interactiveDismissDisabled(!hasAcceptedEULA)
        .task {
            await loadEULA()
        }
    }
    
    private func loadEULA() async {
        guard let url = Bundle.main.url(forResource: "eula", withExtension: "txt", subdirectory: "Legal") else {
            guard let fallbackURL = Bundle.main.url(forResource: "eula", withExtension: "txt") else {
                eulaText = "Error: Could not load EULA file. Please contact support."
                isLoadingEULA = false
                return
            }
            
            do {
                eulaText = try String(contentsOf: fallbackURL, encoding: .utf8)
            } catch {
                eulaText = "Error loading EULA: \(error.localizedDescription)"
            }
            isLoadingEULA = false
            return
        }
        
        do {
            eulaText = try String(contentsOf: url, encoding: .utf8)
        } catch {
            eulaText = "Error loading EULA: \(error.localizedDescription)"
        }
        
        isLoadingEULA = false
    }
}

