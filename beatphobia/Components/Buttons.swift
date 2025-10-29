//
//  Buttons.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            //.font(.custom(AppConstants.defaultFontName, size: 18)) // Uncomment if you have this font
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

struct PillButtonStyle: ButtonStyle {
    
    enum Style {
        case success
        case destructive
        case info
        case warning
        case neutral
        
        struct StyleColors {
            let background: Color
            let foreground: Color
            let border: Color
            let shadow: Color
            let borderWidth: CGFloat
            let shadowRadius: CGFloat
            let shadowOffset: (x: CGFloat, y: CGFloat)
        }
        
        var colors: StyleColors {
            let commonBorderColor: Color = .black
            let commonShadowColor: Color = .black
            let commonBorderWidth: CGFloat = 2
            let commonShadowRadius: CGFloat = 0
            let commonShadowOffset: (x: CGFloat, y: CGFloat) = (x: 2, y: 2)
            
            switch self {
            case .success:
                return StyleColors(
                    background: .green,
                    foreground: .white,
                    border: commonBorderColor,
                    shadow: commonShadowColor,
                    borderWidth: commonBorderWidth,
                    shadowRadius: commonShadowRadius,
                    shadowOffset: commonShadowOffset
                )
            case .destructive:
                return StyleColors(
                    background: .red,
                    foreground: .white,
                    border: commonBorderColor,
                    shadow: commonShadowColor,
                    borderWidth: commonBorderWidth,
                    shadowRadius: commonShadowRadius,
                    shadowOffset: commonShadowOffset
                )
            case .info:
                return StyleColors(
                    background: .blue,
                    foreground: .white,
                    border: commonBorderColor,
                    shadow: commonShadowColor,
                    borderWidth: commonBorderWidth,
                    shadowRadius: commonShadowRadius,
                    shadowOffset: commonShadowOffset
                )
            case .warning:
                return StyleColors(
                    background: .orange,
                    foreground: .white,
                    border: commonBorderColor,
                    shadow: commonShadowColor,
                    borderWidth: commonBorderWidth,
                    shadowRadius: commonShadowRadius,
                    shadowOffset: commonShadowOffset
                )
            case .neutral:
                return StyleColors(
                    background: AppConstants.lightBackgroundColor,
                    foreground: .black,
                    border: commonBorderColor,
                    shadow: commonShadowColor,
                    borderWidth: commonBorderWidth,
                    shadowRadius: commonShadowRadius,
                    shadowOffset: commonShadowOffset
                )
            }
        }
    }
    
    let style: Style

    func makeBody(configuration: Configuration) -> some View {
        let styleColors = style.colors
        
        configuration.label
            .font(.default)
            .fontDesign(.serif)
            .foregroundColor(styleColors.foreground)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(styleColors.background)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(styleColors.border, lineWidth: styleColors.borderWidth)
            )
            .shadow(
                color: styleColors.shadow,
                radius: styleColors.shadowRadius,
                x: styleColors.shadowOffset.x,
                y: styleColors.shadowOffset.y
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

extension View {
    func pillButton(style: PillButtonStyle.Style) -> some View {
        self.buttonStyle(PillButtonStyle(style: style))
    }
}

#Preview {
    ZStack {
        Color(red: 0.96, green: 0.94, blue: 0.90)
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            
            Button("Sign in") { }
                .buttonStyle(PillButtonStyle(style: .neutral))
            
            Button("Confirm") { }
                .buttonStyle(PillButtonStyle(style: .success))
            
            Button("Delete") { }
                .buttonStyle(PillButtonStyle(style: .destructive))
            
            Button("More Info") { }
                .buttonStyle(PillButtonStyle(style: .info))

            Button("Warning") { }
                .pillButton(style: .warning)
            
            Button(action: {}) {
                Label("Upload", systemImage: "checkmark.circle.fill")
            }
            .pillButton(style: .success)
        }
    }
}
