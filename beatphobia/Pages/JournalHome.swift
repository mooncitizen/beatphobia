//
//  JournalHome.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//
import SwiftUI
import RealmSwift

struct MoodPill: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    mood.color.opacity(0.2),
                                    mood.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: mood.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(mood.color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                
                Text(mood.text)
                    .font(.system(size: 11, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundStyle(.black.opacity(0.8))
                    .lineLimit(1)
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mood.color.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct JournalHome: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @State private var selectedMood: Mood?
    private let allMoods: [Mood] = [.happy, .excited, .angry, .stressed, .sad]
    
    @ObservedResults(
        JournalEntryModel.self,
        sortDescriptor: SortDescriptor(keyPath: "date", ascending: false)
    ) var journalEntries
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from:Date())
        if hour >= 5 && hour < 12 {
            return "Good Morning"
        } else if hour >= 12 && hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }
    
    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        if hour >= 5 && hour < 12 {
            return "sun.max.fill"
        } else if hour >= 12 && hour < 17 {
            return "cloud.sun.fill"
        } else {
            return "moon.stars.fill"
        }
    }
    
    private var greetingColor: Color {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 12 {
            return .orange
        } else if hour >= 12 && hour < 17 {
            return .blue
        } else {
            return .purple
        }
    }
    
    private var journalStats: (total: Int, thisWeek: Int, streak: Int) {
        let total = journalEntries.count
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeek = journalEntries.filter { $0.date >= weekAgo }.count
        
        // Calculate streak
        var streak = 0
        let calendar = Calendar.current
        var currentDate = calendar.startOfDay(for: Date())
        
        for _ in 0..<30 { // Check last 30 days max
            let hasEntry = journalEntries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: currentDate)
            }
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return (total, thisWeek, streak)
    }
    
    private var moodDistribution: [(mood: Mood, count: Int)] {
        let moodCounts = Dictionary(grouping: journalEntries, by: { $0.mood })
            .mapValues { $0.count }
        
        return allMoods.map { mood in
            (mood: mood, count: moodCounts[mood] ?? 0)
        }
        .sorted { $0.count > $1.count }
    }
    
    private var journalPrompts: [String] = [
        "What made you smile today?",
        "Describe a challenge you overcame",
        "What are you grateful for?",
        "How did you show kindness today?",
        "What's on your mind right now?",
        "What progress did you make today?"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 16) {
                        // Greeting
                        HStack(spacing: 8) {
                            Image(systemName: greetingIcon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(greetingColor)
                            
                            Text(greeting)
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(.black.opacity(0.8))
                        }
                        .padding(.top, 60)
                        
                        // Main question
                        Text("How are you\nfeeling today?")
                            .font(.system(size: 40, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(.black)
                            .lineSpacing(4)
                        
                        Text("Take a moment to check in with yourself")
                            .font(.system(size: 15))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Mood Selection Card
                    VStack(spacing: 16) {
                        HStack(spacing: 4) {
                            ForEach(allMoods) { mood in
                                MoodPill(mood: mood, isSelected: selectedMood == mood) {
                                    selectedMood = mood
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Stats Section (Pro only)
                    if !journalEntries.isEmpty && subscriptionManager.isPro {
                        statsSection
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        // Mood Insights
                        if !moodDistribution.filter({ $0.count > 0 }).isEmpty {
                            moodInsightsSection
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                        }
                    }
                    
                    // Journal Prompt
                    if journalEntries.isEmpty || shouldShowPrompt {
                        journalPromptCard
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                    }
                    
                    // Entries Section
                    if journalEntries.isEmpty {
                        emptyStateView
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                    } else {
                        entriesSection
                            .padding(.horizontal, 20)
                            .padding(.top, 32)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.bottom, 80)
            }
            .background(AppConstants.defaultBackgroundColor)
            .navigationBarHidden(true)
            .sheet(item: $selectedMood) { mood in
                JournalEntryView(mood: mood)
            }
        }
    }
    
    private var shouldShowPrompt: Bool {
        // Show prompt if no entry today
        guard let lastEntry = journalEntries.first else { return true }
        return !Calendar.current.isDateInToday(lastEntry.date)
    }
    
    // MARK: - Journal Prompt Card
    private var journalPromptCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.yellow)
                
                Text("Journal Prompt")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
            }
            
            Text(journalPrompts.randomElement() ?? journalPrompts[0])
                .font(.system(size: 16, weight: .medium))
                .fontDesign(.serif)
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.1),
                    Color.orange.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                statCard(
                    title: "Total Entries",
                    value: "\(journalStats.total)",
                    icon: "book.fill",
                    color: .blue
                )
                
                statCard(
                    title: "This Week",
                    value: "\(journalStats.thisWeek)",
                    icon: "calendar.badge.clock",
                    color: .green
                )
            }
            
            // Streak Card - Removed
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.black.opacity(0.6))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
    
    // MARK: - Mood Insights Section
    private var moodInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Insights")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(moodDistribution.filter { $0.count > 0 }.prefix(3), id: \.mood) { item in
                    moodInsightRow(mood: item.mood, count: item.count, total: journalEntries.count)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
    
    private func moodInsightRow(mood: Mood, count: Int, total: Int) -> some View {
        let percentage = total > 0 ? Double(count) / Double(total) : 0
        
        return VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: mood.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(mood.color)
                    .frame(width: 24)
                
                Text(mood.text)
                    .font(.system(size: 15, weight: .medium))
                    .fontDesign(.rounded)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(.black)
                
                Text("(\(Int(percentage * 100))%)")
                    .font(.system(size: 13))
                    .foregroundColor(.black.opacity(0.5))
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mood.color.opacity(0.15))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mood.color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.primaryColor.opacity(0.15),
                                AppConstants.primaryColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(AppConstants.primaryColor)
            }
            
            VStack(spacing: 8) {
                Text("Start Your Journal")
                    .font(.system(size: 26, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Text("Select a mood above to create your first entry and start tracking your emotional journey")
                    .font(.system(size: 15))
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Entries Section
    private var entriesSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Recent Entries")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(.black)
                
                Spacer()
            }
            
            // Entry Cards
            VStack(spacing: 12) {
                ForEach(journalEntries.prefix(5)) { entry in
                    NavigationLink(destination: entryDetailView(entry: entry)) {
                        entryCard(entry: entry)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func entryCard(entry: JournalEntryModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with mood and date
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(entry.mood.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: entry.mood.iconName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(entry.mood.color)
                    }
                    
                    Text(entry.mood.text)
                        .font(.system(size: 15, weight: .bold))
                        .fontDesign(.rounded)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black.opacity(0.8))
                    
                    Text(entry.date.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11))
                        .foregroundColor(.black.opacity(0.5))
                }
            }
            
            // Entry text preview
            Text(entry.text)
                .font(.system(size: 15))
                .fontDesign(.serif)
                .foregroundColor(.black.opacity(0.8))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(entry.mood.color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func entryDetailView(entry: JournalEntryModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(entry.mood.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: entry.mood.iconName)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(entry.mood.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.mood.text)
                                .font(.system(size: 22, weight: .bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.black)
                            
                            Text(entry.date.formatted(.dateTime.month().day().year().hour().minute()))
                                .font(.system(size: 14))
                                .foregroundColor(.black.opacity(0.6))
                        }
                    }
                }
                
                Divider()
                
                // Entry content
                Text(entry.text)
                    .font(.system(size: 17))
                    .fontDesign(.serif)
                    .foregroundColor(.black.opacity(0.9))
                    .lineSpacing(6)
                
                Spacer()
            }
            .padding(20)
        }
        .background(AppConstants.defaultBackgroundColor)
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.offsets[index].x, y: bounds.minY + result.offsets[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var offsets: [CGPoint]
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var offsets: [CGPoint] = []
            var size = CGSize.zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                offsets.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, subviewSize.height)
                currentX += subviewSize.width + spacing
                size.width = max(size.width, currentX - spacing)
            }
            
            size.height = currentY + lineHeight
            self.size = size
            self.offsets = offsets
        }
    }
}

#Preview {
    JournalHome()
        .environmentObject(SubscriptionManager())
}
