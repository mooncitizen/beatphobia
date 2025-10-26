//
//  TopicModel.swift
//  beatphobia
//
//  Created by Paul Gardiner on 21/10/2025.
//

import Foundation
import Supabase

struct TopicModel: Codable, Identifiable, Equatable {
    let id: UUID
    let title: String?
    let body: String?
    let author: UUID?
    let systemVisible: Bool?
    let tag: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case author
        case systemVisible = "system_visible" // Corrected typo
        case tag
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
    }
}

func getTopics() async throws -> [TopicModel] {
    let topics: [TopicModel] = try await supabase.from("topics")
        .select("*, author_profile:profiles(*)") // <-- FIX
        .eq("system_visible", value: true)
        .execute()
        .value
    
    return topics
}
