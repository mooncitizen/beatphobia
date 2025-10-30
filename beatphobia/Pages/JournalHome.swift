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
    @Environment(\.colorScheme) var colorScheme
    
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
                    .foregroundStyle(AppConstants.primaryTextColor(for: colorScheme))
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

enum JournalTimePeriod: String, CaseIterable {
    case week = "7D"
    case month = "1M"
    case sixMonths = "6M"
    case year = "1Y"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .sixMonths: return 180
        case .year: return 365
        }
    }
}

struct JournalHome: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedMood: Mood?
    @State private var moodChartPage: Int? = 0
    @State private var selectedTimePeriod: JournalTimePeriod = .week
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
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                        }
                        .padding(.top, 60)
                        
                        // Main question
                        Text("How are you\nfeeling today?")
                            .font(.system(size: 40, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .lineSpacing(4)
                        
                        Text("Take a moment to check in with yourself")
                            .font(.system(size: 15))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
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
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(24)
                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 12, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Stats Section (Pro only)
                    if !journalEntries.isEmpty && subscriptionManager.isPro {
                        statsSection
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                        
                        // Mood Insights & Chart - Horizontal scroll with paging
                        if !moodDistribution.filter({ $0.count > 0 }).isEmpty && journalEntries.count > 3 {
                            VStack(spacing: 12) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    LazyHStack(spacing: 0) {
                                        // Page 1: Mood Insights (First)
                                        moodInsightsSection
                                            .containerRelativeFrame(.horizontal)
                                            .id(0)
                                        
                                        // Page 2: Mood Chart (Second)
                                        moodChartView
                                            .containerRelativeFrame(.horizontal)
                                            .id(1)
                                    }
                                    .scrollTargetLayout()
                                }
                                .scrollTargetBehavior(.paging)
                                .scrollPosition(id: $moodChartPage)
                                .frame(height: 280)
                                
                                // Page indicators
                                HStack(spacing: 8) {
                                    ForEach(0..<2, id: \.self) { index in
                                        Circle()
                                            .fill((moodChartPage ?? 0) == index ? AppConstants.primaryColor : AppConstants.borderColor(for: colorScheme).opacity(0.4))
                                            .frame(width: 8, height: 8)
                                            .animation(.easeInOut(duration: 0.2), value: moodChartPage)
                                    }
                                }
                            }
                            .padding(.top, 1)
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
            .background(AppConstants.backgroundColor(for: colorScheme))
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            }
            
            Text(journalPrompts.randomElement() ?? journalPrompts[0])
                .font(.system(size: 16, weight: .medium))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
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
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
    }
    
    // MARK: - Mood Insights Section
    private var moodInsightsCompact: some View {
        moodInsightsSection
    }
    
    private var moodInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mood Insights")
                .font(.system(size: 20, weight: .bold))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            VStack(spacing: 12) {
                ForEach(moodDistribution.filter { $0.count > 0 }.prefix(3), id: \.mood) { item in
                    moodInsightRow(mood: item.mood, count: item.count, total: journalEntries.count)
                }
            }
        }
        .padding(20)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(20)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
        .padding(.horizontal, 20)
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 15, weight: .bold))
                    .fontDesign(.monospaced)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("(\(Int(percentage * 100))%)")
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
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
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("Select a mood above to create your first entry and start tracking your emotional journey")
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            }
        }
        .padding(.vertical, 40)
    }
    
    // Group entries by day
    private var entriesByDay: [(date: Date, entries: [JournalEntryModel])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: Array(journalEntries)) { entry in
            calendar.startOfDay(for: entry.date)
        }
        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    // MARK: - Entries Section
    private var entriesSection: some View {
        VStack(spacing: 16) {
            // Section Header
            HStack {
                Text("Journal Entries")
                    .font(.system(size: 24, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
            }
            
            // Entries grouped by day
            VStack(spacing: 20) {
                ForEach(entriesByDay.prefix(10), id: \.date) { dayGroup in
                    VStack(alignment: .leading, spacing: 12) {
                        // Day header
                        Text(dayHeaderText(for: dayGroup.date))
                            .font(.system(size: 16, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.leading, 4)
                        
                        // Entries for this day
                        VStack(spacing: 12) {
                            ForEach(dayGroup.entries) { entry in
                                NavigationLink(destination: JournalEntryDetailView(entry: entry)) {
                                    entryCard(entry: entry)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func dayHeaderText(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else {
            // Use same format as journey list
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    // MARK: - Mood Chart (Pro Feature)
    private var moodChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.purple)
                
                Text("Mood Over Time")
                    .font(.system(size: 18, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Spacer()
            }
            
            // Time period selector
            HStack(spacing: 8) {
                ForEach(JournalTimePeriod.allCases, id: \.self) { period in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTimePeriod = period
                        }
                    }) {
                        Text(period.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedTimePeriod == period ? .white : AppConstants.primaryTextColor(for: colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedTimePeriod == period ? 
                                Color.purple : Color.gray.opacity(0.1)
                            )
                            .cornerRadius(8)
                    }
                }
            }
            
            // Bar chart based on selected period
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(moodDataForPeriod(selectedTimePeriod), id: \.date) { dayData in
                        VStack(spacing: 4) {
                            // Bar
                            if let mood = dayData.mood {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [mood.color, mood.color.opacity(0.6)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 35, height: CGFloat(dayData.entries) * 20 + 30)
                                    .overlay(
                                        Text("\(dayData.entries)")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.bottom, 4),
                                        alignment: .bottom
                                    )
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 35, height: 30)
                            }
                            
                            // Day label
                            Text(dayData.label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 140)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.08),
                    Color.purple.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
    
    private func moodDataForPeriod(_ period: JournalTimePeriod) -> [(date: Date, mood: Mood?, entries: Int, label: String)] {
        let calendar = Calendar.current
        var result: [(date: Date, mood: Mood?, entries: Int, label: String)] = []
        let days = period.days
        
        // Adjust bar count based on period
        let barCount = min(days, period == .week ? 7 : (period == .month ? 30 : 12))
        let interval = days / barCount // Group days if showing longer periods
        
        for i in (0..<barCount).reversed() {
            let daysBack = i * interval
            guard let date = calendar.date(byAdding: .day, value: -daysBack, to: Date()) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            
            // For longer periods, aggregate multiple days
            var dayEntries: [JournalEntryModel] = []
            if interval > 1 {
                // Aggregate entries over the interval
                for j in 0..<interval {
                    guard let checkDate = calendar.date(byAdding: .day, value: -j, to: startOfDay) else { continue }
                    dayEntries.append(contentsOf: journalEntries.filter { entry in
                        calendar.isDate(entry.date, inSameDayAs: checkDate)
                    })
                }
            } else {
                dayEntries = journalEntries.filter { entry in
                    calendar.isDate(entry.date, inSameDayAs: startOfDay)
                }
            }
            
            let dominantMood = dayEntries.max(by: { e1, e2 in
                dayEntries.filter { $0.mood == e1.mood }.count < dayEntries.filter { $0.mood == e2.mood }.count
            })?.mood
            
            let label: String
            if period == .week {
                if calendar.isDateInToday(startOfDay) {
                    label = "Today"
                } else if calendar.isDateInYesterday(startOfDay) {
                    label = "Yest"
                } else {
                    label = startOfDay.formatted(.dateTime.weekday(.abbreviated))
                }
            } else if period == .month {
                label = startOfDay.formatted(.dateTime.day())
            } else {
                label = startOfDay.formatted(.dateTime.month(.abbreviated))
            }
            
            result.append((date: startOfDay, mood: dominantMood, entries: dayEntries.count, label: label))
        }
        
        return result
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
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                    
                    Text(entry.date.formatted(.relative(presentation: .named)))
                        .font(.system(size: 11))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            
            // Entry text preview
            Text(entry.text)
                .font(.system(size: 15))
                .fontDesign(.serif)
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(entry.mood.color.opacity(0.2), lineWidth: 1)
        )
    }
    
}

// MARK: - Journal Entry Detail View

struct JournalEntryDetailView: View {
    let entry: JournalEntryModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    var body: some View {
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
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            
                            Text(entry.date.formatted(.dateTime.month().day().year().hour().minute()))
                                .font(.system(size: 14))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Entry content
                Text(entry.text)
                    .font(.system(size: 17))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    .lineSpacing(6)
                
                Spacer()
            }
            .padding(20)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditSheet = true }) {
                        Label("Edit Entry", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete Entry", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(AppConstants.primaryColor)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditJournalEntryView(entry: entry)
        }
        .alert("Delete Entry", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
        } message: {
            Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
        }
    }
    
    private func deleteEntry() {
        guard let realm = try? Realm() else { return }
        
        if let entryToDelete = realm.object(ofType: JournalEntryModel.self, forPrimaryKey: entry.id) {
            try? realm.write {
                realm.delete(entryToDelete)
            }
            dismiss()
        }
    }
}

// MARK: - Edit Journal Entry View

struct EditJournalEntryView: View {
    let entry: JournalEntryModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var editedText: String
    @State private var selectedMood: Mood
    @FocusState private var isTextFieldFocused: Bool
    
    private let allMoods: [Mood] = [.happy, .excited, .angry, .stressed, .sad]
    
    init(entry: JournalEntryModel) {
        self.entry = entry
        self._editedText = State(initialValue: entry.text)
        self._selectedMood = State(initialValue: entry.mood)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Mood selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        HStack(spacing: 12) {
                            ForEach(allMoods) { mood in
                                Button(action: {
                                    selectedMood = mood
                                }) {
                                    VStack(spacing: 8) {
                                        ZStack {
                                            Circle()
                                                .fill(mood.color.opacity(selectedMood == mood ? 0.2 : 0.1))
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: mood.iconName)
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(mood.color)
                                        }
                                        .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                                        
                                        Text(mood.text)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // Text editor
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's on your mind?")
                            .font(.system(size: 18, weight: .bold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        TextEditor(text: $editedText)
                            .font(.system(size: 17))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            .frame(minHeight: 200)
                            .padding(12)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                            .focused($isTextFieldFocused)
                    }
                }
                .padding(20)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(AppConstants.primaryColor)
                    .disabled(editedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextFieldFocused = true
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let realm = try? Realm() else { return }
        
        if let entryToEdit = realm.object(ofType: JournalEntryModel.self, forPrimaryKey: entry.id) {
            try? realm.write {
                entryToEdit.text = editedText.trimmingCharacters(in: .whitespacesAndNewlines)
                entryToEdit.mood = selectedMood
            }
            dismiss()
        }
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
