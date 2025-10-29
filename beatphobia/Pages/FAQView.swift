//
//  FAQView.swift
//  beatphobia
//
//  Frequently Asked Questions
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let icon: String
}

struct FAQView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedItems: Set<UUID> = []
    
    private let faqs: [FAQItem] = [
        FAQItem(
            question: "What is Still Step?",
            answer: "Still Step is a comprehensive mental wellness app designed to help you manage anxiety and panic attacks. It provides various tools, tracking features, and journaling capabilities to support your mental health journey.",
            icon: "heart.circle.fill"
        ),
        FAQItem(
            question: "How do the breathing exercises work?",
            answer: "Our breathing exercises include techniques like Box Breathing and 4-7-8 Breathing, which are proven methods to calm your nervous system. Simply follow the visual guides and audio cues to practice these exercises anytime you need support.",
            icon: "wind"
        ),
        FAQItem(
            question: "What's the difference between Free and Pro?",
            answer: "The Free plan includes all core tools and features. Pro adds unlimited location tracking history, cloud journal backup & sync, and detailed metrics & analytics. Free users can access their last 3 journeys only.",
            icon: "crown.fill"
        ),
        FAQItem(
            question: "How does location tracking work?",
            answer: "When you start a journey, the app can track your location to help you identify patterns in where anxiety occurs. This data is stored locally on your device (or in the cloud with Pro) and is never shared. You can disable location tracking in your device settings anytime.",
            icon: "location.fill"
        ),
        FAQItem(
            question: "Is my journal data private?",
            answer: "Yes! Your journal entries are stored locally on your device by default. With a Pro subscription, you can optionally enable cloud backup, which encrypts and securely syncs your data. We never read or share your personal journal entries.",
            icon: "lock.shield.fill"
        ),
        FAQItem(
            question: "Can I use the app offline?",
            answer: "Yes! Most features work completely offline. The only features requiring internet are cloud sync (Pro) and community features. All tools, journal, and local tracking work without an internet connection.",
            icon: "wifi.slash"
        ),
        FAQItem(
            question: "How do I cancel my subscription?",
            answer: "You can manage or cancel your subscription anytime through the App Store. Go to Settings → [Your Name] → Subscriptions, select Still Step, and choose Cancel Subscription. You'll retain Pro features until the end of your billing period.",
            icon: "xmark.circle.fill"
        ),
        FAQItem(
            question: "Can I export my journal entries?",
            answer: "Currently, journal entries are stored in your device's local database. Export functionality is planned for a future update. Pro users with cloud sync can access their data from multiple devices.",
            icon: "square.and.arrow.up.fill"
        ),
        FAQItem(
            question: "What are Journeys?",
            answer: "Journeys are sessions where you track your anxiety or panic attack in real-time. You can record your panic scale, use coping tools, track your location, and add journal notes. This helps you understand patterns and what helps you most.",
            icon: "map.fill"
        ),
        FAQItem(
            question: "How can I contact support?",
            answer: "For support, feature requests, or feedback, email us at support@stillstep.com. We typically respond within 24-48 hours.",
            icon: "envelope.fill"
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Frequently Asked Questions")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                    
                    Text("Find answers to common questions")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                // FAQ Items
                VStack(spacing: 12) {
                    ForEach(faqs) { faq in
                        FAQCard(
                            item: faq,
                            isExpanded: expandedItems.contains(faq.id),
                            colorScheme: colorScheme
                        ) {
                            toggleExpanded(faq.id)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func toggleExpanded(_ id: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if expandedItems.contains(id) {
                expandedItems.remove(id)
            } else {
                expandedItems.insert(id)
            }
        }
    }
}

// MARK: - FAQ Card
struct FAQCard: View {
    let item: FAQItem
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: item.icon)
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 28)
                    
                    Text(item.question)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                
                if isExpanded {
                    Text(item.answer)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
            .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}

