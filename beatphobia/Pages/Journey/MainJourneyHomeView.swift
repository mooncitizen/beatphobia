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

struct CalmingTool: Identifiable {
    let id = UUID()
    let name: String
    let category: ToolCategory
    let icon: String
    let description: String
    let duration: String
    let difficulty: String // "Easy", "Medium", "Advanced"
    let destinationView: (() -> AnyView)?
}

// MARK: - Main View

struct JourneyAgorahobiaView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("anxietyLevel") private var anxietyLevel: Double = 5
    @Binding var isTabBarVisible: Bool
    
    private var firstName: String {
        let name: String? = authManager.currentUserProfile?.name
        return name?.split(separator: " ").first.map(String.init) ?? "there"
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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hi \(firstName)")
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                        
                        Text("Tools to help you manage anxiety and panic")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.top, 8)
                    
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
                                    Text("Tracker")
                                        .font(.system(size: 22, weight: .bold))
                                        .fontDesign(.serif)
                                        .foregroundColor(.white)
                                    
                                    Text("Record your location and feelings as you explore.")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .lineLimit(2)
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
                        .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 12, y: 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 20)
                    
                    // View Past Journeys Button
                    NavigationLink(destination: PastJourneysView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor)
                            
                            Text("View Past Journeys")
                                .font(.system(size: 15, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryColor)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppConstants.primaryColor.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
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
                    
                    // Current State Card
                    Card(backgroundColor: .white, cornerRadius: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "心.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(anxietyColorForLevel(anxietyLevel))
                                
                                Text("How are you feeling right now?")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Calm")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.black.opacity(0.5))
                                    
                                    Spacer()
                                    
                                    Text("Panicked")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.black.opacity(0.5))
                                }
                                
                                Slider(value: $anxietyLevel, in: 1...10, step: 1)
                                    .tint(anxietyColorForLevel(anxietyLevel))
                                
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(anxietyColorForLevel(anxietyLevel))
                                        .frame(width: 12, height: 12)
                                    
                                    Text("Level: \(Int(anxietyLevel))/10")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Text(anxietyMessageForLevel(anxietyLevel))
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Recommended Tools
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended for You")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recommendedTools) { tool in
                                    NavigationLink(destination: destinationForTool(tool)) {
                                        ToolCard(tool: tool, isCompact: true)
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
                            .foregroundColor(.black)
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
                                            .foregroundColor(.black)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Horizontal scrolling tools
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(categoryTools) { tool in
                                                NavigationLink(destination: destinationForTool(tool)) {
                                                    ToolCard(tool: tool, isCompact: false)
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
                .padding(.bottom, 24)
            }
            .background(AppConstants.defaultBackgroundColor)
            .navigationBarHidden(true)
            .onAppear {
                // Ensure tab bar is visible when returning to this view
            }
            .toolbar(.visible, for: .tabBar)
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
}

// MARK: - Supporting Views

struct ToolCard: View {
    let tool: CalmingTool
    let isCompact: Bool
    
    var body: some View {
        Card(backgroundColor: .white, cornerRadius: 16, padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon and Category
                HStack {
                    ZStack {
                        Circle()
                            .fill(tool.category.color.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: tool.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(tool.category.color)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(tool.duration)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                        
                        DifficultyBadge(difficulty: tool.difficulty)
                    }
                }
                
                // Title
                Text(tool.name)
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Description
                Text(tool.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.black.opacity(0.7))
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
    case 1...3:
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

// MARK: - Placeholder Tool Views

struct PlaceholderToolView: View {
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
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Label(tool.duration, systemImage: "clock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                        
                        DifficultyBadge(difficulty: tool.difficulty)
                    }
                }
                
                Text(tool.description)
                    .font(.system(size: 16))
                    .foregroundColor(.black.opacity(0.7))
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
                            .foregroundColor(.black)
                    }
                    
                    Text("This tool is currently under development and will be available in a future update.")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(AppConstants.defaultBackgroundColor)
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

// MARK: - Preview

#Preview {
    @Previewable @State var isTabBarVisible = true
    let mockAuthManager = AuthManager()
    
    JourneyAgorahobiaView(isTabBarVisible: $isTabBarVisible)
        .environmentObject(mockAuthManager)
}
