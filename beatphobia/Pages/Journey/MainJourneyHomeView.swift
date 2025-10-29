//
//  JourneyAgorahobia.swift
//  beatphobia
//
//  Created by Paul Gardiner on 20/10/2025.
//
import Foundation
import SwiftUI
import RealmSwift
import MapKit

// MARK: - Models

enum ToolCategory: String, CaseIterable {
    case breathing = "Breathing"
    case grounding = "Grounding"
    case relaxation = "Relaxation"
    case focus = "Focus"
    case distraction = "Distraction"
    case affirmation = "Affirmation"
    
    var color: Color {
        switch self {
        case .breathing: return .blue
        case .grounding: return .green
        case .relaxation: return .purple
        case .focus: return .orange
        case .distraction: return .pink
        case .affirmation: return .teal
        }
    }
}

struct CalmingTool: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let category: ToolCategory
    let icon: String
    let description: String
    let duration: String
    let difficulty: String // "Easy", "Medium", "Advanced"
    let destinationView: (() -> AnyView)?
    
    static func == (lhs: CalmingTool, rhs: CalmingTool) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Main View

struct JourneyAgorahobiaView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var journalSyncService: JournalSyncService
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("anxietyLevel") private var anxietyLevel: Double = 0
    @Binding var isTabBarVisible: Bool
    @State private var showEmergencyTools = false
    @State private var journeyCount: Int = 0
    @State private var selectedToolForSheet: CalmingTool?
    @State private var showToolSheet = false
    
    private var firstName: String {
        let name: String? = authManager.currentUserProfile?.name
        return name?.split(separator: " ").first.map(String.init) ?? "there"
    }
    
    private var dailyQuote: String {
        let quotes = [
            "One breath at a time, one step at a time.",
            "You are stronger than your anxiety.",
            "Progress, not perfection.",
            "Every journey begins with courage.",
            "You've survived 100% of your bad days.",
            "Healing isn't linear, and that's okay."
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return quotes[dayOfYear % quotes.count]
    }

    
    let tools: [CalmingTool] = [
        CalmingTool(
            name: "Object Hunt",
            category: .focus,
            icon: "viewfinder",
            description: "Find objects around you using AI detection - a grounding game to stay present",
            duration: "5-10 min",
            difficulty: "Easy",
            destinationView: { AnyView(FocusView()) }
        ),
        CalmingTool(
            name: "Box Breathing",
            category: .breathing,
            icon: "square.fill",
            description: "4-4-4-4 breathing pattern to calm your nervous system",
            duration: "2-3 min",
            difficulty: "Easy",
            destinationView: { AnyView(BoxBreathingView()) }
        ),
        CalmingTool(
            name: "4-7-8 Breathing",
            category: .breathing,
            icon: "wind",
            description: "Deep breathing technique to reduce anxiety quickly",
            duration: "3-4 min",
            difficulty: "Easy",
            destinationView: { AnyView(Breathing478View()) }
        ),
        CalmingTool(
            name: "5-4-3-2-1 Grounding",
            category: .grounding,
            icon: "hand.raised.fill",
            description: "Connect with your senses to anchor yourself in the present",
            duration: "3-5 min",
            difficulty: "Easy",
            destinationView: { AnyView(GroundingView()) }
        ),
        CalmingTool(
            name: "Progressive Muscle Relaxation",
            category: .relaxation,
            icon: "figure.walk",
            description: "Systematically tense and release muscle groups to deeply relax",
            duration: "10-15 min",
            difficulty: "Medium",
            destinationView: { AnyView(ProgressiveMuscleRelaxationView()) }
        ),
        CalmingTool(
            name: "Body Scan",
            category: .relaxation,
            icon: "figure.stand",
            description: "Mindfully scan through your body to release tension",
            duration: "8-12 min",
            difficulty: "Medium",
            destinationView: { AnyView(BodyScanView()) }
        ),
        CalmingTool(
            name: "Safe Space Visualization",
            category: .relaxation,
            icon: "house.fill",
            description: "Imagine a peaceful, safe place where you feel calm",
            duration: "5-10 min",
            difficulty: "Medium",
            destinationView: { AnyView(SafeSpaceView()) }
        ),
        CalmingTool(
            name: "Counting Game",
            category: .distraction,
            icon: "number.circle.fill",
            description: "Simple counting exercises to redirect anxious thoughts",
            duration: "2-3 min",
            difficulty: "Easy",
            destinationView: { AnyView(CountingGameView()) }
        ),
        CalmingTool(
            name: "Color Hunt",
            category: .distraction,
            icon: "paintpalette.fill",
            description: "Find objects of specific colors in your environment",
            duration: "3-5 min",
            difficulty: "Easy",
            destinationView: { AnyView(ColorHuntView()) }
        ),
        CalmingTool(
            name: "Tapper",
            category: .distraction,
            icon: "hand.tap.fill",
            description: "Tap the targets quickly in this Whack-a-Mole style game",
            duration: "1-2 min",
            difficulty: "Easy",
            destinationView: { AnyView(TapperView()) }
        ),
        CalmingTool(
            name: "Positive Affirmations",
            category: .affirmation,
            icon: "heart.text.square.fill",
            description: "Read and repeat calming, empowering statements",
            duration: "2-4 min",
            difficulty: "Easy",
            destinationView: { AnyView(AffirmationsView()) }
        )
    ]
    
    var recommendedTools: [CalmingTool] {
        // Recommend easier tools for higher anxiety
        if anxietyLevel >= 7 {
            return tools.filter { $0.difficulty == "Easy" }.prefix(3).map { $0 }
        } else if anxietyLevel >= 4 {
            return tools.prefix(4).map { $0 }
        } else {
            return tools.filter { $0.category == .relaxation || $0.category == .affirmation }.prefix(3).map { $0 }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header Section with Quote
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hi \(firstName)")
                                    .font(.system(size: 38, weight: .bold, design: .serif))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                
                                Text("Tools to help you manage anxiety and panic")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                            
                            // Daily Quote Card
                            HStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text(dailyQuote)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                                    .italic()
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.purple.opacity(0.08),
                                        Color.pink.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple.opacity(0.2), .pink.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Quick Stats
                        if journeyCount > 0 {
                            HStack(spacing: 12) {
                                QuickStatCard(
                                    icon: "map.fill",
                                    value: "\(journeyCount)",
                                    label: journeyCount == 1 ? "Journey" : "Journeys",
                                    color: AppConstants.primaryColor
                                )
                                
                                QuickStatCard(
                                    icon: "heart.fill",
                                    value: "\(Int(10 - anxietyLevel))/10",
                                    label: "Wellness",
                                    color: anxietyColorForLevel(anxietyLevel)
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                    
                    // Journey Tracker CTA
                    NavigationLink(destination: LocationTrackerView(isTabBarVisible: $isTabBarVisible)) {
                        ZStack(alignment: .leading) {
                            // Background gradient
                            LinearGradient(
                                colors: [
                                    AppConstants.primaryColor,
                                    AppConstants.primaryColor.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "map.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                // Content
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Location Tracker")
                                        .font(.system(size: 22, weight: .bold))
                                        .fontDesign(.serif)
                                        .foregroundColor(.white)
                                        .minimumScaleFactor(0.7)
                                        .lineLimit(1)
                                    
                                    Text("Record your location and feelings as you explore.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                
                                // Arrow
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                        }
                        .frame(height: 120)
                        .cornerRadius(20)
                        .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 12, y: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    
                    
                    // Panic Scale Tracker CTA
                    NavigationLink(destination: PanicScaleView()) {
                        ZStack(alignment: .leading) {
                            // Background gradient
                            LinearGradient(
                                colors: [
                                    Color.purple,
                                    Color.purple.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            HStack(spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                    
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 28, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                // Content
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Panic Scale Tracker")
                                        .font(.system(size: 20, weight: .bold))
                                        .fontDesign(.serif)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Text("Track episodes and understand your patterns.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                // Arrow
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                        }
                        .frame(height: 120)
                        .cornerRadius(20)
                        .shadow(color: Color.purple.opacity(0.3), radius: 12, y: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // Current State Card - Enhanced Glass Morphism
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "心.fill")
                                .font(.system(size: 22))
                                .foregroundColor(anxietyColorForLevel(anxietyLevel))

                            Text("How are you feeling right now?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Calm")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                                Spacer()

                                Text("Panicked")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }

                            ZStack(alignment: .leading) {
                                // Track background gradient
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.green.opacity(0.15),
                                                Color.yellow.opacity(0.15),
                                                Color.orange.opacity(0.15),
                                                Color.red.opacity(0.15)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 8)

                                Slider(value: $anxietyLevel, in: 0...10, step: 1)
                                    .tint(anxietyColorForLevel(anxietyLevel))
                            }

                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(anxietyColorForLevel(anxietyLevel).opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Circle()
                                        .fill(anxietyColorForLevel(anxietyLevel))
                                        .frame(width: 16, height: 16)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Level \(Int(anxietyLevel))/10")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                                    Text(anxietyLabelForLevel(anxietyLevel))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(anxietyColorForLevel(anxietyLevel))
                                }

                                Spacer()
                            }
                        }

                        // Message card
                        HStack(spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(anxietyColorForLevel(anxietyLevel))

                            Text(anxietyMessageForLevel(anxietyLevel))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(anxietyColorForLevel(anxietyLevel).opacity(0.08))
                        .cornerRadius(12)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppConstants.cardBackgroundColor(for: colorScheme))
                            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 16, y: 4)
                    )
                    .padding(.horizontal, 20)
                    
                    // Recommended Tools
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Text("Recommended for You")
                                .font(.system(size: 22, weight: .bold, design: .serif))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                            // Smart recommendation indicator
                            HStack(spacing: 4) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.purple)

                                Text("Smart")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)

                        // Recommendation context
                        if anxietyLevel >= 7 {
                            Text("Quick, easy tools for high anxiety")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .padding(.horizontal, 20)
                        } else if anxietyLevel >= 4 {
                            Text("Balanced techniques for moderate anxiety")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .padding(.horizontal, 20)
                        } else {
                            Text("Deep relaxation for calm moments")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .padding(.horizontal, 20)
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recommendedTools) { tool in
                                    Button(action: {
                                        selectedToolForSheet = tool
                                    }) {
                                        ToolCard(tool: tool, isCompact: true, isRecommended: true)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // All Tools by Category
                    VStack(alignment: .leading, spacing: 16) {
                        Text("All Tools")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 20)

                        ForEach(ToolCategory.allCases, id: \.self) { category in
                            let categoryTools = tools.filter { $0.category == category }

                            if !categoryTools.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Category Header
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(category.color)
                                            .frame(width: 8, height: 8)

                                        Text(category.rawValue)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Horizontal scrolling tools
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(categoryTools) { tool in
                                                Button(action: {
                                                    selectedToolForSheet = tool
                                                }) {
                                                    ToolCard(tool: tool, isCompact: false, isRecommended: false)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100) // Extra padding for floating button
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
            .onAppear {
                // Ensure tab bar is visible when returning to this view
                loadJourneyCount()
            }
            .toolbar(.visible, for: .tabBar)
            .onChange(of: selectedToolForSheet) { oldValue, newValue in
                showToolSheet = newValue != nil
            }
            .fullScreenCover(isPresented: $showToolSheet) {
                if let tool = selectedToolForSheet {
                    destinationForTool(tool)
                        .onDisappear {
                            selectedToolForSheet = nil
                        }
                }
            }
            
            // Floating Emergency Tools Button
            if anxietyLevel >= 8 {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        showEmergencyTools = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Need Help Now")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Tap for quick relief")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: Color.red.opacity(0.5), radius: 30, y: 10)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100) // Above tab bar
                    
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: anxietyLevel)
            }
            }
            .fullScreenCover(isPresented: $showEmergencyTools) {
                EmergencyToolsSheet(anxietyLevel: anxietyLevel)
            }
        }
    }
    
    @ViewBuilder
    private func destinationForTool(_ tool: CalmingTool) -> some View {
        if let viewBuilder = tool.destinationView {
            viewBuilder()
        } else {
            AnyView(PlaceholderToolView(tool: tool))
        }
    }
    
    private func loadJourneyCount() {
        guard let realm = try? Realm() else { return }
        journeyCount = realm.objects(JourneyRealm.self).count
    }
}

// MARK: - Supporting Views

struct ToolCard: View {
    @Environment(\.colorScheme) var colorScheme
    let tool: CalmingTool
    let isCompact: Bool
    let isRecommended: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recommended ribbon
            if isRecommended {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.yellow)
                    
                    Text("RECOMMENDED")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    LinearGradient(
                        colors: [.purple, .purple.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(6, corners: [.topLeft, .topRight])
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: isRecommended ? 0 : 16, padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    // Icon and Category
                    HStack {
                        ZStack {
                            Circle()
                                .fill(tool.category.color.opacity(0.15))
                                .frame(width: 50, height: 50)

                            Image(systemName: tool.icon)
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(tool.category.color)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(tool.duration)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                            DifficultyBadge(difficulty: tool.difficulty)
                        }
                    }

                    // Title
                    Text(tool.name)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Description
                    Text(tool.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Start button
                    HStack {
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("Start")
                                .font(.system(size: 14, weight: .semibold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(tool.category.color)
                    }
                }
                .frame(width: isCompact ? 260 : 300)
            }
        }
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: isRecommended ? 12 : 8, y: 4)
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct DifficultyBadge: View {
    let difficulty: String
    
    var color: Color {
        switch difficulty {
        case "Easy": return .green
        case "Medium": return .orange
        case "Advanced": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(difficulty)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }
}

// MARK: - Helper Functions

func anxietyColorForLevel(_ level: Double) -> Color {
    return colorForValue(Int(level))
}

func anxietyMessageForLevel(_ level: Double) -> String {
    switch Int(level) {
    case 0...3:
        return "You're doing great! Try some relaxation techniques to maintain your calm state."
    case 4...6:
        return "You're experiencing moderate anxiety. Breathing exercises can help you stay grounded."
    case 7...8:
        return "Your anxiety is elevated. Focus on simple grounding techniques to help you feel safer."
    case 9...10:
        return "You're in a high anxiety state. Try quick, easy tools like box breathing or the focus exercise."
    default:
        return ""
    }
}

func anxietyLabelForLevel(_ level: Double) -> String {
    switch Int(level) {
    case 0:
        return "Calm"
    case 1...2:
        return "Very Calm"
    case 3...4:
        return "Calm"
    case 5...6:
        return "Moderate"
    case 7...8:
        return "Elevated"
    case 9...10:
        return "High"
    default:
        return "Unknown"
    }
}

// MARK: - Placeholder Tool Views

struct PlaceholderToolView: View {
    @Environment(\.colorScheme) var colorScheme
    let tool: CalmingTool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                    .frame(height: 60)

                // Icon
                ZStack {
                    Circle()
                        .fill(tool.category.color.opacity(0.15))
                        .frame(width: 120, height: 120)

                    Image(systemName: tool.icon)
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(tool.category.color)
                }

                VStack(spacing: 12) {
                    Text(tool.name)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Label(tool.duration, systemImage: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                        DifficultyBadge(difficulty: tool.difficulty)
                    }
                }

                Text(tool.description)
                    .font(.system(size: 16))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Divider()
                    .padding(.vertical, 12)

                VStack(spacing: 16) {
                    HStack(spacing: 8) {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.orange)

                        Text("Coming Soon")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    }

                    Text("This tool is currently under development and will be available in a future update.")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
            }
            .padding()
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PMRView: View {
    var body: some View {
        PlaceholderToolView(tool: CalmingTool(
            name: "Progressive Muscle Relaxation",
            category: .relaxation,
            icon: "figure.walk",
            description: "",
            duration: "",
            difficulty: "",
            destinationView: nil
        ))
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppConstants.cardBackgroundColor(for: colorScheme))
                .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
        )
    }
}

// MARK: - Emergency Tools Sheet

struct EmergencyToolsSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let anxietyLevel: Double
    @State private var selectedTool: CalmingTool?
    @State private var showTool = false
    @State private var showCrisisHotlines = false
    
    let emergencyTools = [
        CalmingTool(
            name: "Box Breathing",
            category: .breathing,
            icon: "square.fill",
            description: "4-4-4-4 breathing pattern to calm your nervous system",
            duration: "2-3 min",
            difficulty: "Easy",
            destinationView: { AnyView(BoxBreathingView()) }
        ),
        CalmingTool(
            name: "5-4-3-2-1 Grounding",
            category: .grounding,
            icon: "hand.raised.fill",
            description: "Connect with your senses to anchor yourself in the present",
            duration: "3-5 min",
            difficulty: "Easy",
            destinationView: { AnyView(GroundingView()) }
        ),
        CalmingTool(
            name: "Object Hunt",
            category: .focus,
            icon: "viewfinder",
            description: "Find objects around you using AI detection - a grounding game",
            duration: "5-10 min",
            difficulty: "Easy",
            destinationView: { AnyView(FocusView()) }
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                        // Header Message
                        VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red.opacity(0.2), Color.red.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "bolt.heart.fill")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.red, .red.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                        .padding(.top, 20)
                        
                        Text("Quick Relief Tools")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text("These tools can help you right now")
                            .font(.system(size: 15))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)

                    // Crisis Hotlines Button
                    Button(action: {
                        showCrisisHotlines = true
                    }) {
                        VStack(spacing: 0) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 56, height: 56)
                                    
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Crisis Hotlines")
                                        .font(.system(size: 20, weight: .bold, design: .serif))
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    
                                    Text("24/7 support lines for immediate help")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.1),
                                        Color.blue.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                            )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    .shadow(color: Color.blue.opacity(0.2), radius: 12, y: 4)
                    
                    // Quick Tools
                    VStack(spacing: 16) {
                        ForEach(emergencyTools) { tool in
                            Button(action: {
                                selectedTool = tool
                            }) {
                                EmergencyToolCard(tool: tool)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                }
            }
            .onChange(of: selectedTool) { oldValue, newValue in
                showTool = newValue != nil
            }
            .fullScreenCover(isPresented: $showTool) {
                if let tool = selectedTool, let viewBuilder = tool.destinationView {
                    viewBuilder()
                        .onDisappear {
                            selectedTool = nil
                        }
                }
            }
            .sheet(isPresented: $showCrisisHotlines) {
                CrisisHotlinesView()
            }
        }
        }
    }

struct EmergencyToolCard: View {
    @Environment(\.colorScheme) var colorScheme
    let tool: CalmingTool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(tool.category.color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: tool.icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(tool.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tool.name)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(tool.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(tool.duration)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                    DifficultyBadge(difficulty: tool.difficulty)
                }
            }

            Spacer()

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(tool.category.color)
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isTabBarVisible = true
    let mockAuthManager = AuthManager()
    let mockJournalSyncService = JournalSyncService()

    JourneyAgorahobiaView(isTabBarVisible: $isTabBarVisible)
        .environmentObject(mockAuthManager)
        .environmentObject(mockJournalSyncService)
}
