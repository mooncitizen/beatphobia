//
//  MinimalLoadingView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 30/10/2025.
//

import SwiftUI

struct MinimalLoadingView: View {
    @Environment(\.colorScheme) var colorScheme
    let text: String?
    
    init(text: String? = nil) {
        self.text = text
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppConstants.primaryColor)
                .scaleEffect(1.0)
            
            if let text = text {
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview("With Text") {
    MinimalLoadingView(text: "Loading...")
}

#Preview("Without Text") {
    MinimalLoadingView()
}

