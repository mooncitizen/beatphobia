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
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case username
        case biography
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
