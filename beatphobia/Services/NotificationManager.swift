//
//  NotificationManager.swift
//  beatphobia
//
//  Handles notification permission, APNs registration, token updates, and Supabase upserts.
//

import Foundation
import UIKit
import UserNotifications
import Supabase
import Combine

final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let userDefaultsTokenKey = "apns_device_token"
    private let userDefaultsLastSentKey = "apns_token_last_sent_at"
    private let tokenResendInterval: TimeInterval = 60 * 60 * 24 // 24h safety resend
    private var authListenerTask: Task<Void, Never>?
    
    override private init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        // Listen for auth state changes to retry token sync after login
        authListenerTask?.cancel()
        authListenerTask = Task { [weak self] in
            guard let self else { return }
            for await state in supabase.auth.authStateChanges {
                await self.handleAuthEvent(state.event)
            }
        }
    }
    
    func setup() {
        Task { @MainActor in
            await requestAuthorizationIfNeeded()
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - Permission
    
    @MainActor
    func requestAuthorizationIfNeeded() async {
        let current = await NotificationManager.authorizationStatus()
        guard current == .notDetermined else { return }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            // Intentionally no-op; user can enable later in settings
        }
    }
    
    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }
    
    static func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - APNs Token Handling
    
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        storeAndSyncTokenIfNeeded(token)
    }
    
    private func storeAndSyncTokenIfNeeded(_ token: String) {
        let previous = UserDefaults.standard.string(forKey: userDefaultsTokenKey)
        let lastSent = UserDefaults.standard.object(forKey: userDefaultsLastSentKey) as? Date
        let shouldResend = lastSent.map { Date().timeIntervalSince($0) > tokenResendInterval } ?? true
        if previous != token || shouldResend {
            UserDefaults.standard.set(token, forKey: userDefaultsTokenKey)
            Task { await upsertTokenToServer(token: token) }
        }
    }
    
    private func syncStoredTokenAfterLogin() {
        if let token = UserDefaults.standard.string(forKey: userDefaultsTokenKey) {
            // Force a sync regardless of throttle when user just signed in
            Task { await upsertTokenToServer(token: token, force: true) }
        }
    }
    
    private func deviceIdentifier() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    private func platform() -> String { "ios" }
    
    @MainActor
    private func currentUserIdString() async -> String? {
        let session = try? await supabase.auth.session
        return session?.user.id.uuidString
    }
    
    private func appVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        return build.isEmpty ? version : "\(version) (\(build))"
    }
    
    private func upsertTokenToServer(token: String, force: Bool = false) async {
        // Try to upsert via RPC under RLS policies.
        // If not authenticated, skip but keep token in storage; we'll retry on login
        guard await currentUserIdString() != nil else { return }
        
        let params: [String: String?] = [
            "p_token": token,
            "p_device_id": deviceIdentifier(),
            "p_platform": platform(),
            "p_app_version": appVersion()
        ]
        
        do {
            let _: EmptyResponse = try await supabase
                .rpc("register_push_token", params: params)
                .execute()
                .value
            UserDefaults.standard.set(Date(), forKey: userDefaultsLastSentKey)
        } catch {
            // Silently ignore; will retry on next launch or token change
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .list, .sound, .badge]
    }
}

// MARK: - AppDelegate Bridge for APNs callbacks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // No-op; user can enable later
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear app badge when app becomes active
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: - Auth event handling

extension NotificationManager {
    @MainActor
    fileprivate func handleAuthEvent(_ event: AuthChangeEvent) async {
        switch event {
        case .signedIn, .tokenRefreshed, .userUpdated:
            syncStoredTokenAfterLogin()
        default:
            break
        }
    }
}


