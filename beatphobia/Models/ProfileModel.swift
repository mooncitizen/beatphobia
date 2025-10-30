//
//  Profile.swift
//  beatphobia
//
//  Created by Paul Gardiner on 19/10/2025.
//

import Foundation

struct Profile: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String?
    var username: String?
    var biography: String?
    var role: String?
    var profileImageUrl: String?
    var markedForDeletion: Bool?
    var deletionScheduledAt: Date?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case biography
        case role
        case profileImageUrl = "profile_image_url"
        case markedForDeletion = "marked_for_deletion"
        case deletionScheduledAt = "deletion_scheduled_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
