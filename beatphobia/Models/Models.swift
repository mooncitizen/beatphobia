//
//  Models.swift
//  beatphobia
//
//  Created by Paul Gardiner on 20/10/2025.
//
import Foundation
import SwiftData

enum SyncStatus: String, Codable {
    case synced
    case localOnly
}

@MainActor
protocol SyncableModel: PersistentModel where ID == UUID {
    var updatedAt: Date { get set }
    var syncStatus: SyncStatus { get set }
    var userID: String? { get set }
}

@Model
final class JournalEntry: SyncableModel {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var syncStatus: SyncStatus
    var userID: String?
    
    var mood: String
    var moodStrength: Int
    var body: String
    var images: [String]
    
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .localOnly,
        userID: String? = nil,
        mood: String,
        moodStrength: Int,
        body: String,
        images: [String]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
        self.userID = userID
        self.mood = mood
        self.moodStrength = moodStrength
        self.body = body
        self.images = images
    }
}

struct SupabaseJournalEntry: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let user_id: UUID
    let mood: String
    let moodStrength: Int
    let body: String
    let images: [String]
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case user_id
        case mood
        case moodStrength = "mood_strength"
        case body
        case images
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(from local: JournalEntry, userID: UUID) {
        self.id = local.id
        self.user_id = userID
        self.mood = local.mood
        self.moodStrength = local.moodStrength
        self.body = local.body
        self.images = local.images
        self.createdAt = local.createdAt
        self.updatedAt = Date()
    }
}
