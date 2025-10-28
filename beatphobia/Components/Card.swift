// Card.swift

import SwiftUI

/// A configurable, reusable card component that serves as a base container
/// for widgets, applying background, clipping, and shadow.
///
/// You can initialize this card with a custom background color, corner radius,
/// and padding. To create a card with edge-to-edge content (like an image),
/// initialize it with `padding: 0` and apply padding manually to any
/// other content inside.
struct Card<Content: View>: View {

    let backgroundColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    /// Creates a new card component.
    ///
    /// - Parameters:
    ///   - backgroundColor: The card's background color (e.g., `Color(.systemBackground)`).
    ///   - cornerRadius: The corner radius for the card. Defaults to `24.0`.
    ///   - padding: The internal padding for the content. Defaults to `16.0`.
    ///   - content: The view content to display inside the card.
    init(
        backgroundColor: Color,
        cornerRadius: CGFloat = 24.0,
        padding: CGFloat = 16.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    // Create a ZStack with a light gray background to see the cards clearly
    ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        VStack(spacing: 20) {
            
            // Example 1: Standard Card (like "Statistics")
            Card(backgroundColor: .white) {
                VStack(alignment: .leading) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.title.weight(.bold))
                    Text("Hello Daniel")
                        .font(.largeTitle.bold())
                    Text("Your score is above average.")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Example 2: Colored Card (like "Current tasks")
            Card(backgroundColor: .green.opacity(0.2)) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current tasks")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("You have 3 tasks for today")
                        .font(.title2.bold())
                    Text("#shopping #planning")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Example 3: Edge-to-Edge Card (like "Community")
            Card(backgroundColor: .white, padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // 1. Top text content with its own padding
                    VStack(alignment: .leading) {
                        Text("by John Smith")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Productive routine.")
                            .font(.headline.bold())
                    }
                    .padding() // Manual padding

                    // 2. Image content with no padding
                    // (Using a system color as a placeholder)
                    Color.secondary
                        .frame(height: 180)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                        }
                }
            }
        }
        .padding()
    }
}
