//
//  ImageCarouselView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 30/10/2025.
//
//  Carousel view for displaying post images with fullscreen capability

import SwiftUI

struct ImageCarouselView: View {
    let attachments: [Attachment]
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedImageIndex: Int = 0
    @State private var showFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !attachments.isEmpty {
                // Image carousel
                TabView(selection: $selectedImageIndex) {
                    ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                        CachedAsyncImage(urlString: attachment.fileUrl) { image in
                            Button(action: {
                                showFullScreen = true
                            }) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 300)
                                    .clipped()
                            }
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 300)
                                .overlay(
                                    ProgressView()
                                        .tint(AppConstants.primaryColor)
                                )
                        }
                        .tag(index)
                    }
                }
                .frame(height: 300)
                .tabViewStyle(.page(indexDisplayMode: attachments.count > 1 ? .always : .never))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Image counter if multiple
                if attachments.count > 1 {
                    HStack {
                        Spacer()
                        Text("\(selectedImageIndex + 1) of \(attachments.count)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(AppConstants.cardBackgroundColor(for: colorScheme))
                            )
                        Spacer()
                    }
                    .offset(y: -20)
                }
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenImageViewer(
                attachments: attachments,
                initialIndex: selectedImageIndex
            )
        }
    }
}

// MARK: - Full Screen Image Viewer

struct FullScreenImageViewer: View {
    let attachments: [Attachment]
    let initialIndex: Int
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    init(attachments: [Attachment], initialIndex: Int) {
        self.attachments = attachments
        self.initialIndex = initialIndex
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Close")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                        )
                    }
                    
                    Spacer()
                    
                    if attachments.count > 1 {
                        Text("\(currentIndex + 1) / \(attachments.count)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
                .padding()
                
                Spacer()
                
                // Image viewer with pinch-to-zoom
                ZStack {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                            CachedAsyncImage(urlString: attachment.fileUrl) { image in
                                ZoomableImageView(image: image)
                                    .tag(index)
                            } placeholder: {
                                VStack(spacing: 20) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .tint(.white)
                                    
                                    Text("Loading image...")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Zoomable Image View

struct ZoomableImageView: View {
    let image: UIImage
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { _ in
                // Limit zoom range
                if scale < 1.0 {
                    withAnimation {
                        scale = 1.0
                        offset = .zero
                    }
                } else if scale > 4.0 {
                    scale = 4.0
                }
                lastScale = scale
            }
    }
    
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: scale > 1.1 ? 0 : 50)
            .onChanged { value in
                if scale > 1.1 {
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                if scale > 1.1 {
                    lastOffset = offset
                }
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .scaleEffect(scale)
                .offset(offset)
                .onTapGesture(count: 2) {
                    // Double tap to reset zoom
                    withAnimation(.spring(response: 0.3)) {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                .gesture(magnificationGesture)
                .gesture(scale > 1.1 ? dragGesture : nil)
        }
    }
}

#Preview {
    ImageCarouselView(attachments: [])
}

