//
//  AuthManager.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//

import Foundation
import SwiftUI
import Supabase
import Combine
import AuthenticationServices
import CryptoKit

typealias User = Supabase.User

enum AuthState {
    case signedIn
    case signedOut
}


@MainActor
final class AuthManager: ObservableObject {
    @Published var authState: AuthState = .signedOut
    @Published var isLoading: Bool = true
    
    @Published var currentUser: User?
    @Published var currentUserProfile: Profile?
    @Published var authError: Error?
    
    private var authListenerTask: Task<Void, Never>?

    init() {
        setupListener()
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await checkInitialSession()
        }
    }
    
    deinit {
        authListenerTask?.cancel()
    }
    
    private func setupListener() {
        authListenerTask?.cancel()
        
        authListenerTask = Task {
            for await state in supabase.auth.authStateChanges {
                await handleAuthEvent(state.event)
            }
        }
    }
    
    private func handleAuthEvent(_ event: AuthChangeEvent) async {
        await self.checkCurrentSession()
    }
    
    private func checkCurrentSession() async {
        do {
            let session = try await supabase.auth.session
            
            self.currentUser = session.user
            self.authState = .signedIn
            
        } catch {
            self.authState = .signedOut
            self.currentUser = nil
        }
    }
    
    private func checkInitialSession() async {
        defer { self.isLoading = false }
        await checkCurrentSession()
    }
    
    func signIn(email: String, password: String) async {
        self.isLoading = true
        self.authError = nil
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            self.authError = error
        }
        self.isLoading = false
    }
    
    func signUp(email: String, password: String) async {
        self.isLoading = true
        self.authError = nil
        do {
            _ = try await supabase.auth.signUp(email: email, password: password)
        } catch {
            self.authError = error
        }
        self.isLoading = false
    }
    
    func signOut() async {
        self.isLoading = true
        self.authError = nil
        
        do {
            try await supabase.auth.signOut()
        } catch {
            self.authError = error
        }
        
        self.isLoading = false
    }
    
    func signInWithApple(idToken: String, nonce: String) async {
        self.isLoading = true
        self.authError = nil
        
        print("🍎 Attempting Sign in with Apple...")
        print("   - Token length: \(idToken.count)")
        print("   - Nonce: \(nonce)")
        
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            print("✅ Sign in with Apple successful!")
            print("   - User ID: \(session.user.id)")
        } catch {
            self.authError = error
            print("❌ Sign in with Apple error: \(error.localizedDescription)")
            if let decodingError = error as? DecodingError {
                print("   Decoding error details: \(decodingError)")
            }
        }
        
        self.isLoading = false
    }
    
    func getProfile() async throws -> Profile? {
        let profiles: [Profile] = try await supabase.from("profile")
            .select()
            .eq("id", value: self.currentUser!.id.uuidString)
            .limit(1)
            .execute()
            .value
        
        let profile = profiles.first
        self.currentUserProfile = profile
        
        return profile
    }
    
    func setProfileName(name: String) async throws {
        guard let currentUserId = self.currentUser?.id else {
            return
        }
        
        let now = Date()
        let createdAt = self.currentUserProfile?.createdAt ?? now
        let updatedAt = now
        
        let biography = currentUserProfile?.biography ?? nil
        
        let profileToUpsert = Profile(
            id: currentUserId,
            name: name,
            biography: biography,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        
        
        try await supabase.from("profile").upsert(profileToUpsert).execute()
        
        await MainActor.run {
            self.currentUserProfile = profileToUpsert
        }
    }

}
