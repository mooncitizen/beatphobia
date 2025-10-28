//
//  ThemeManager.swift
//  beatphobia
//
//  Created by Paul Gardiner on 27/10/2025.
//

import SwiftUI
import Combine

enum ThemeOption: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Use system default
        }
    }
}

final class ThemeManager: ObservableObject {
    @Published var selectedTheme: ThemeOption {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "app_theme")
        }
    }
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "app_theme") ?? ThemeOption.system.rawValue
        self.selectedTheme = ThemeOption(rawValue: savedTheme) ?? .system
    }
}

// MARK: - Adaptive Colors Extension

extension AppConstants {
    
    // MARK: - Adaptive Background Colors
    
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 18/255, green: 18/255, blue: 20/255)
            : Color(red: 252/255, green: 245/255, blue: 238/255)
    }
    
    static func cardBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 28/255, green: 28/255, blue: 30/255)
            : Color.white
    }
    
    static func secondaryBackgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 44/255, green: 44/255, blue: 46/255)
            : Color(red: 242/255, green: 242/255, blue: 247/255)
    }
    
    // MARK: - Adaptive Text Colors
    
    static func primaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.95)
            : Color.black
    }
    
    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.6)
            : Color.black.opacity(0.6)
    }
    
    static func tertiaryTextColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.4)
            : Color.black.opacity(0.4)
    }
    
    // MARK: - Adaptive Accent Colors
    
    /// The primary accent color adjusts slightly for dark mode
    static func adaptivePrimaryColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 100/255, green: 130/255, blue: 200/255) // Lighter blue for dark mode
            : Color(red: 51/255, green: 77/255, blue: 128/255)
    }
    
    // MARK: - Adaptive Border/Divider Colors
    
    static func dividerColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.1)
            : Color.black.opacity(0.1)
    }
    
    static func borderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.white.opacity(0.15)
            : Color.black.opacity(0.15)
    }
    
    // MARK: - Shadow Colors
    
    static func shadowColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color.black.opacity(0.5)
            : Color.black.opacity(0.1)
    }
}

