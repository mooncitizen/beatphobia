//
//  CrisisHotlinesView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 29/10/2025.
//

import SwiftUI

struct HelplineInfo: Identifiable {
    let id = UUID()
    let name: String
    let phone: String?
    let phoneDescription: String?
    let email: String?
    let text: String?
    let textDescription: String?
    let webchat: String?
    let about: String
}

enum Country: String, CaseIterable {
    case uk = "🇬🇧 United Kingdom"
    case us = "🇺🇸 United States"
}

struct CrisisHotlinesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedCountry: Country = .uk
    
    let ukHelplines: [HelplineInfo] = [
        HelplineInfo(
            name: "Samaritans",
            phone: "116 123",
            phoneDescription: "24/7, free",
            email: "jo@samaritans.org",
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "For anyone struggling to cope or who needs someone to listen. They provide confidential, non-judgemental support."
        ),
        HelplineInfo(
            name: "NHS 111 (Urgent Mental Health)",
            phone: "111",
            phoneDescription: "24/7, free",
            email: nil,
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "For urgent mental health help. You can call 111 to get connected to a local NHS mental health crisis team."
        ),
        HelplineInfo(
            name: "Mind Infoline",
            phone: "0300 123 3393",
            phoneDescription: "Mon-Fri, 9am-6pm",
            email: "info@mind.org.uk",
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "Provides information and signposting for mental health problems, including where to get help. This is not a crisis line."
        ),
        HelplineInfo(
            name: "CALM (Campaign Against Living Miserably)",
            phone: "0800 58 58 58",
            phoneDescription: "5pm–Midnight, daily",
            email: nil,
            text: nil,
            textDescription: nil,
            webchat: "Available on their website",
            about: "A leading movement against suicide, providing a helpline and webchat for anyone who is down or has hit a wall."
        ),
        HelplineInfo(
            name: "Breathing Space (Scotland)",
            phone: "0800 83 85 87",
            phoneDescription: "Weekdays: 6pm–2am, Weekends: Fri 6pm–Mon 6am",
            email: nil,
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "A free, confidential phone service for anyone in Scotland over 16 feeling low, anxious, or depressed."
        ),
        HelplineInfo(
            name: "Childline",
            phone: "0800 1111",
            phoneDescription: "24/7, free",
            email: nil,
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "Confidential support for anyone under the age of 19."
        ),
        HelplineInfo(
            name: "YoungMinds",
            phone: nil,
            phoneDescription: nil,
            email: nil,
            text: "Text YM to 85258",
            textDescription: "24/7, free",
            webchat: nil,
            about: "Provides free, 24/7 text support for young people across the UK experiencing a mental health crisis."
        )
    ]
    
    let usHelplines: [HelplineInfo] = [
        HelplineInfo(
            name: "988 Suicide & Crisis Lifeline",
            phone: "988",
            phoneDescription: "Call or text 24/7, free",
            email: nil,
            text: "Text 988",
            textDescription: "24/7, free",
            webchat: "988lifeline.org/chat",
            about: "The primary national network for anyone in suicidal crisis or emotional distress. It's free, confidential, and available 24/7."
        ),
        HelplineInfo(
            name: "Crisis Text Line",
            phone: nil,
            phoneDescription: nil,
            email: nil,
            text: "Text MHA or HOME to 741741",
            textDescription: "24/7, free",
            webchat: nil,
            about: "Connects you with a trained crisis counselor via text message."
        ),
        HelplineInfo(
            name: "SAMHSA National Helpline",
            phone: "1-800-662-HELP (4357)",
            phoneDescription: "24/7, free",
            email: nil,
            text: nil,
            textDescription: nil,
            webchat: nil,
            about: "A confidential, 24/7 information service for individuals and families facing mental and/or substance use disorders. It provides referrals to local treatment facilities, support groups, and community-based organizations."
        ),
        HelplineInfo(
            name: "The Trevor Project (for LGBTQ+ Youth)",
            phone: "1-866-488-7386",
            phoneDescription: "24/7, free",
            email: nil,
            text: "Text START to 678-678",
            textDescription: "24/7, free",
            webchat: "Available on their website",
            about: "The leading national organization providing crisis intervention and suicide prevention services to lesbian, gay, bisexual, transgender, queer & questioning (LGBTQ) young people under 25."
        ),
        HelplineInfo(
            name: "Veterans Crisis Line",
            phone: "Dial 988 then press 1",
            phoneDescription: "24/7, free",
            email: nil,
            text: "Text 838255",
            textDescription: "24/7, free",
            webchat: nil,
            about: "A free, confidential resource for all Veterans, service members, and their families, even if they are not registered with the VA."
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Country Tabs
                HStack(spacing: 0) {
                    ForEach(Country.allCases, id: \.self) { country in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCountry = country
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text(country.rawValue)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedCountry == country ? AppConstants.primaryTextColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme))
                                
                                Rectangle()
                                    .fill(selectedCountry == country ? Color.blue : Color.clear)
                                    .frame(height: 3)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .background(AppConstants.backgroundColor(for: colorScheme))
                
                Divider()
                    .padding(.bottom, 8)
                
                // Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Emergency notice
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.red)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("In an Emergency")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                    
                                    Text(selectedCountry == .uk ? "Call 999 for immediate emergency help" : "Call 911 for immediate emergency help")
                                        .font(.system(size: 13))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        
                        // Request for additional hotlines
                        VStack(spacing: 6) {
                            Text("If you want to have any other crisis hotlines added to this list please email us")
                                .font(.system(size: 13))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                if let url = URL(string: "mailto:support@stillstep.com") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("support@stillstep.com")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .underline()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)
                        
                        // Helplines
                        ForEach(selectedCountry == .uk ? ukHelplines : usHelplines) { helpline in
                            HelplineCard(helpline: helpline)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Crisis Hotlines")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
}

struct HelplineCard: View {
    @Environment(\.colorScheme) var colorScheme
    let helpline: HelplineInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text(helpline.name)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
            
            // Contact methods
            VStack(alignment: .leading, spacing: 10) {
                if let phone = helpline.phone, let phoneDesc = helpline.phoneDescription {
                    ContactMethodRow(
                        icon: "phone.fill",
                        iconColor: .green,
                        label: "Phone",
                        value: phone,
                        description: phoneDesc,
                        action: {
                            if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let email = helpline.email {
                    ContactMethodRow(
                        icon: "envelope.fill",
                        iconColor: .blue,
                        label: "Email",
                        value: email,
                        description: nil,
                        action: {
                            if let url = URL(string: "mailto:\(email)") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
                
                if let text = helpline.text, let textDesc = helpline.textDescription {
                    ContactMethodRow(
                        icon: "message.fill",
                        iconColor: .purple,
                        label: "Text",
                        value: text,
                        description: textDesc,
                        action: nil
                    )
                }
                
                if let webchat = helpline.webchat {
                    ContactMethodRow(
                        icon: "bubble.left.and.bubble.right.fill",
                        iconColor: .orange,
                        label: "Webchat",
                        value: webchat,
                        description: nil,
                        action: nil
                    )
                }
            }
            
            // About
            VStack(alignment: .leading, spacing: 6) {
                Text("About")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                
                Text(helpline.about)
                    .font(.system(size: 14))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(16)
        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 8, y: 2)
    }
}

struct ContactMethodRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let description: String?
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    
                    Text(value)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    if let description = description {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
            }
        }
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview {
    CrisisHotlinesView()
}

