//
//  Constants.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//
import Foundation
import SwiftUI

struct AppConstants {
    
    static let appName = "Still Step"
    
    // MARK: - Typography
    static let defaultFontName: String = "SourceCodePro-Regular"
    static let headerFontName: String = ""
    
    // MARK: - Colors (Core)
    
    /// Light background color for light mode
    static let lightBackgroundColor: Color = Color(red: 252/255, green: 245/255, blue: 238/255)
    
    /// Dark background color for dark mode
    static let darkBackgroundColor: Color = Color(red: 18/255, green: 18/255, blue: 20/255)
    
    /// The primary accent color for prominent elements like the header (51, 77, 128).
    static let primaryColor: Color = Color(red: 51/255, green: 77/255, blue: 128/255)
    
    /// The color used for content/premium cards to contrast with the background (38, 64, 105).
    static let cardColor: Color = Color(red: 38/255, green: 64/255, blue: 105/255)
    
    /// Standard white text color for high contrast on dark backgrounds.
    static let contentTextColor: Color = Color.white.opacity(0.85)
    
    /// Secondary, muted text color for descriptions and minor labels.
    static let secondaryTextColor: Color = Color.white.opacity(0.6)
}


func colorForValue(_ value: Int) -> Color {
    // 1. Clamp the value to the expected 1-10 range
    let clampedValue = max(1, min(10, value))
    
    // 2. Normalize the 1-10 value to a 0.0-1.0 "percentage"
    // (clampedValue - 1) gives a 0-9 range.
    // Dividing by 9.0 scales it to 0.0-1.0.
    let normalizedValue = Double(clampedValue - 1) / 9.0
    
    // 3. Map the percentage to the hue range
    // We want to go from Green (0.333) to Red (0.0).
    // So, we *subtract* the normalized value from the starting hue.
    let hue = 0.333 - (normalizedValue * 0.333)
    
    // 4. Create the color
    return Color(
        hue: hue,
        saturation: 1.0, // Full saturation
        brightness: 1.0  // Full brightness
    )
}
