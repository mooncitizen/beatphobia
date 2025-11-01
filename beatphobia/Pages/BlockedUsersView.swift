//
//  BlockedUsersView.swift
//  beatphobia
//
//  Created by Assistant
//
//  View for managing blocked users

import SwiftUI
import Supabase

struct BlockedUsersView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    
    @State private var blockedUsers: [BlockedUserInfo] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    
                    Text("Blocked Users")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    
                    Text("Users you've blocked won't see your posts and you won't see theirs")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.vertical, 20)
                
                // Blocked Users List
                if isLoading {
                    MinimalLoadingView(text: "Loading Blocked Users")
                        .padding(.top, 40)
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading Blocked Users")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Try Again") {
                            Task {
                                await loadBlockedUsers()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 40)
                } else if blockedUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "hand.raised")
                            .font(.system(size: 48))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                        
                        Text("No blocked users")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        
                        Text("You haven't blocked any users yet")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(blockedUsers) { blockedUser in
                            BlockedUserRow(
                                blockedUser: blockedUser,
                                onUnblock: {
                                    Task {
                                        await unblockUser(blockedUser.userId)
                                    }
                                },
                                colorScheme: colorScheme
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 40)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
            }
        }
        .task {
            await loadBlockedUsers()
        }
        .refreshable {
            await loadBlockedUsers()
        }
    }
    
    private func loadBlockedUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            blockedUsers = try await communityService.getBlockedUsersWithProfiles()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ Error loading blocked users: \(error)")
        }
    }
    
    private func unblockUser(_ userId: UUID) async {
        do {
            try await communityService.unblockUser(blockedUserId: userId)
            // Remove from local list
            await MainActor.run {
                blockedUsers.removeAll { $0.userId == userId }
            }
            print("✅ Successfully unblocked user")
        } catch {
            print("❌ Error unblocking user: \(error)")
        }
    }
}

// MARK: - Blocked User Row

struct BlockedUserRow: View {
    let blockedUser: BlockedUserInfo
    let onUnblock: () -> Void
    let colorScheme: ColorScheme
    @State private var showUnblockAlert = false
    
    var body: some View {
        HStack(spacing: 16) {
            // User Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.3),
                                AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(String(blockedUser.username.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .fontDesign(.serif)
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text("@\(blockedUser.username)")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                
                Text("Blocked \(blockedUser.blockedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 13))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            
            Spacer()
            
            // Unblock Button
            Button(action: {
                showUnblockAlert = true
            }) {
                Text("Unblock")
                    .font(.system(size: 15, weight: .semibold))
                    .fontDesign(.rounded)
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppConstants.adaptivePrimaryColor(for: colorScheme), lineWidth: 1)
                    )
            }
        }
        .padding(16)
        .background(AppConstants.cardBackgroundColor(for: colorScheme))
        .cornerRadius(12)
        .alert("Unblock User", isPresented: $showUnblockAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unblock", role: .destructive) {
                onUnblock()
            }
        } message: {
            Text("Are you sure you want to unblock @\(blockedUser.username)? You will see their posts again.")
        }
    }
}

