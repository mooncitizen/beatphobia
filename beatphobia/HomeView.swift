//
//  HomeView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import SwiftUI

struct HomeView: View {
    // Injecting the AuthManager for potential Sign Out functionality in the Profile tab
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) var colorScheme
    
    // Optional: State to manage the currently selected tab
    @State private var selectedTab: Tab = .journeys
    
    // State to control tab bar visibility
    @State private var isTabBarVisible: Bool = true
    
    // State to show paywall on first launch
    @AppStorage("shown_paywall") private var hasShownPaywall = false
    @State private var showPaywall = false
    
    // Defines the tabs and their associated system images/titles
    enum Tab: String {
        case journeys = "Journeys"
        case community = "Community"
        case journal = "Journal"
        case profile = "Profile"
        
        var systemImage: String {
            switch self {
            case .journeys: return "brain.head.profile"
            case .community: return "bubble.left.and.bubble.right"
            case .journal: return "book.pages"
            case .profile: return "person.crop.circle"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Group {
                switch selectedTab {
                case .journeys:
                    JourneysView(isTabBarVisible: $isTabBarVisible)
                case .community:
                    CommunityOverview()
                case .journal:
                    JournalHome()
                case .profile:
                    ProfileView()
                }
            }
            
            VStack {
                Spacer()
                
                if isTabBarVisible {
                    customTabBar.padding(.bottom, 15)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .onAppear {
                // Show paywall once on first launch if user is not already pro
                if !hasShownPaywall && !subscriptionManager.isPro {
                    // Small delay to let the home view settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showPaywall = true
                        hasShownPaywall = true
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                NavigationStack {
                    PaywallView()
                        .environmentObject(subscriptionManager)
                }
            }
        }
    }
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(tab: .journeys, icon: "brain.head.profile")
            tabButton(tab: .community, icon: "bubble.left.and.bubble.right")
            tabButton(tab: .journal, icon: "book.pages")
            tabButton(tab: .profile, icon: "person.crop.circle")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Group {
                // Custom background for dark mode - slightly whiter
                // let bgColor = colorScheme == .dark 
                //     ? Color(red: 38/255, green: 38/255, blue: 42/255) // Slightly whiter dark gray
                //     : AppConstants.cardBackgroundColor(for: colorScheme)
                
                // bgColor
                //     .opacity(0.75)
                
                // Blur effect for depth
                // VisualEffectView(effect: UIBlurEffect(style: colorScheme == .dark ? .systemThinMaterialDark : .systemThinMaterialLight))
                //     .opacity(colorScheme == .dark ? 0.5 : 0.6)
            }
        )
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 10, y: -5)
        .padding(.horizontal, 20)
        .padding(.bottom, 0)
    }
    
    private func tabButton(tab: Tab, icon: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: selectedTab == tab ? .semibold : .regular))
                .foregroundColor(selectedTab == tab ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme))
                .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Visual Effect View
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

struct ForumView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Forum")
            }
            .navigationTitle("Forum")
        }
    }
}


#Preview {
    let mockAuthManager = AuthManager()
        
    HomeView()
        .environmentObject(mockAuthManager)
        .environmentObject(SubscriptionManager())
        .environmentObject(ThemeManager())
}
