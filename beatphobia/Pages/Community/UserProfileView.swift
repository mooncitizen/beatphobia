//
//  UserProfileView.swift
//  beatphobia
//
//  Created by Paul Gardiner on 30/10/2025.
//
//  Public user profile view shown when tapping on users in community

import SwiftUI
import Supabase

struct UserProfileView: View {
    let userId: UUID
    let username: String
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    
    @State private var profile: Profile?
    @State private var userPosts: [PostDisplayModel] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                if isLoading {
                    MinimalLoadingView(text: "Loading Profile")
                        .padding(.top, 100)
                } else if let profile = profile {
                    VStack(spacing: 0) {
                        // Profile Header
                        VStack(spacing: 20) {
                            // Profile Image
                            if let profileImageUrl = profile.profileImageUrl {
                                CachedAsyncImage(urlString: profileImageUrl) { image in
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(AppConstants.primaryColor, lineWidth: 4)
                                        )
                                        .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 12, y: 6)
                                } placeholder: {
                                    Circle()
                                        .fill(AppConstants.primaryColor.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            ProgressView()
                                                .tint(AppConstants.primaryColor)
                                        )
                                }
                            } else {
                                // Initials fallback
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppConstants.primaryColor.opacity(0.3),
                                                AppConstants.primaryColor.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)
                                    .overlay(
                                        Text(String(username.prefix(1)).uppercased())
                                            .font(.system(size: 48, weight: .bold))
                                            .fontDesign(.serif)
                                            .foregroundColor(AppConstants.primaryColor)
                                    )
                                    .shadow(color: AppConstants.shadowColor(for: colorScheme), radius: 12, y: 6)
                            }
                            
                            // Username Only (Privacy)
                            VStack(spacing: 6) {
                                Text("@\(username)")
                                    .font(.system(size: 28, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                            }
                            
                            // Bio
                            if let bio = profile.biography, !bio.isEmpty {
                                Text(bio)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme).opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 32)
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Posts Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Posts")
                                    .font(.system(size: 22, weight: .bold))
                                    .fontDesign(.serif)
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                                
                                Spacer()
                                
                                Text("\(userPosts.count)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            if userPosts.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                                    
                                    Text("No posts yet")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                VStack(spacing: 16) {
                                    ForEach(userPosts.prefix(10)) { post in
                                        NavigationLink(destination: PostDetailView(post: post)) {
                                            PostCard(post: post, communityService: communityService)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Profile")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 100)
                }
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
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
        .task {
            await loadUserProfile()
        }
    }
    
    private func loadUserProfile() async {
        do {
            // Fetch profile
            let profiles: [Profile] = try await supabase
                .from("profile")
                .select()
                .eq("id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value
            
            if let fetchedProfile = profiles.first {
                await MainActor.run {
                    profile = fetchedProfile
                }
            }
            
            // Fetch user's posts
            let posts = try await communityService.fetchPosts(topicId: nil, category: nil, searchText: "")
            let userPosts = posts.filter { $0.userId == userId }
            
            await MainActor.run {
                self.userPosts = userPosts
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
            print("❌ Error loading user profile: \(error)")
        }
    }
}

#Preview {
    UserProfileView(userId: UUID(), username: "testuser")
}

