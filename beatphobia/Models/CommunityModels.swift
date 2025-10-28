//
//  CommunityModels.swift
//  beatphobia
//
//  Community forum data models
//

import Foundation
import SwiftUI

// MARK: - Community Topic

struct CommunityTopic: Codable, Identifiable {
    let id: UUID
    let name: String
    let slug: String
    let description: String
    let icon: String
    let color: String
    let postCount: Int
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case slug
        case description
        case icon
        case color
        case postCount = "post_count"
        case createdAt = "created_at"
    }
    
    var swiftUIColor: Color {
        // Convert hex string to Color
        let hex = color.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Post Category

enum PostCategory: String, Codable, CaseIterable, Identifiable {
    case all = "All"
    case support = "Support"
    case success = "Success Story"
    case question = "Question"
    case discussion = "Discussion"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "rectangle.grid.2x2"
        case .support: return "heart.fill"
        case .success: return "star.fill"
        case .question: return "questionmark.circle.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .support: return .pink
        case .success: return .green
        case .question: return .blue
        case .discussion: return .purple
        }
    }
    
    var databaseValue: String {
        switch self {
        case .all: return "all"
        case .support: return "support"
        case .success: return "success"
        case .question: return "question"
        case .discussion: return "discussion"
        }
    }
}

// MARK: - Community Post

struct CommunityPostDB: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let topicId: UUID
    let title: String
    let content: String
    let category: String
    let likesCount: Int
    let commentsCount: Int
    let viewsCount: Int
    let tags: [String]
    let isDeleted: Bool
    let isFlagged: Bool
    let trending: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // User profile info (joined from profiles table)
    var authorUsername: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case topicId = "topic_id"
        case title
        case content
        case category
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case viewsCount = "views_count"
        case tags
        case isDeleted = "is_deleted"
        case isFlagged = "is_flagged"
        case trending
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case authorUsername = "author_username"
    }
    
    init(id: UUID, userId: UUID, topicId: UUID, title: String, content: String, category: String, 
         likesCount: Int, commentsCount: Int, viewsCount: Int, tags: [String], 
         isDeleted: Bool, isFlagged: Bool, trending: Bool, createdAt: Date, updatedAt: Date, 
         authorUsername: String? = nil) {
        self.id = id
        self.userId = userId
        self.topicId = topicId
        self.title = title
        self.content = content
        self.category = category
        self.likesCount = likesCount
        self.commentsCount = commentsCount
        self.viewsCount = viewsCount
        self.tags = tags
        self.isDeleted = isDeleted
        self.isFlagged = isFlagged
        self.trending = trending
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.authorUsername = authorUsername
    }
}

// MARK: - Display Model for Posts

struct PostDisplayModel: Identifiable {
    let id: UUID
    let userId: UUID
    let author: String // This is the username
    let authorInitials: String
    let category: PostCategory
    let title: String
    let content: String
    let preview: String
    let timestamp: Date
    let likesCount: Int
    let commentsCount: Int
    let viewsCount: Int
    let tags: [String]
    var isLiked: Bool
    var isBookmarked: Bool
    
    init(from post: CommunityPostDB, isLiked: Bool = false, isBookmarked: Bool = false) {
        self.id = post.id
        self.userId = post.userId
        self.author = post.authorUsername ?? "anonymous"
        
        // Create initials from username (first 2 chars uppercased)
        let username = post.authorUsername ?? "??"
        self.authorInitials = String(username.prefix(2)).uppercased()
        
        // Map category string to enum
        switch post.category {
        case "support": self.category = .support
        case "success": self.category = .success
        case "question": self.category = .question
        case "discussion": self.category = .discussion
        default: self.category = .discussion
        }
        
        self.title = post.title
        self.content = post.content
        
        // Create preview (first 150 characters)
        if post.content.count > 150 {
            self.preview = String(post.content.prefix(150)) + "..."
        } else {
            self.preview = post.content
        }
        
        self.timestamp = post.createdAt
        self.likesCount = post.likesCount
        self.commentsCount = post.commentsCount
        self.viewsCount = post.viewsCount
        self.tags = post.tags
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
    }
}

// MARK: - Community Comment

struct CommunityCommentDB: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let content: String
    let parentCommentId: UUID?
    let likesCount: Int
    let isDeleted: Bool
    let isFlagged: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // User profile info (joined from profiles table)
    var authorUsername: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case content
        case parentCommentId = "parent_comment_id"
        case likesCount = "likes_count"
        case isDeleted = "is_deleted"
        case isFlagged = "is_flagged"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case authorUsername = "author_username"
    }
    
    init(id: UUID, postId: UUID, userId: UUID, content: String, 
         parentCommentId: UUID? = nil, likesCount: Int, isDeleted: Bool, 
         isFlagged: Bool, createdAt: Date, updatedAt: Date, 
         authorUsername: String? = nil) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.content = content
        self.parentCommentId = parentCommentId
        self.likesCount = likesCount
        self.isDeleted = isDeleted
        self.isFlagged = isFlagged
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.authorUsername = authorUsername
    }
}

// MARK: - Display Model for Comments

struct CommentDisplayModel: Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let author: String // This is the username
    let authorInitials: String
    let content: String
    let timestamp: Date
    let likesCount: Int
    let parentCommentId: UUID?
    var isLiked: Bool
    var replies: [CommentDisplayModel]
    
    init(from comment: CommunityCommentDB, isLiked: Bool = false, replies: [CommentDisplayModel] = []) {
        self.id = comment.id
        self.postId = comment.postId
        self.userId = comment.userId
        self.author = comment.authorUsername ?? "anonymous"
        
        // Create initials from username (first 2 chars uppercased)
        let username = comment.authorUsername ?? "??"
        self.authorInitials = String(username.prefix(2)).uppercased()
        
        self.content = comment.content
        self.timestamp = comment.createdAt
        self.likesCount = comment.likesCount
        self.parentCommentId = comment.parentCommentId
        self.isLiked = isLiked
        self.replies = replies
    }
}

// MARK: - Post Like

struct PostLike: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Comment Like

struct CommentLike: Codable, Identifiable {
    let id: UUID
    let commentId: UUID
    let userId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case commentId = "comment_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Post Bookmark

struct PostBookmark: Codable, Identifiable {
    let id: UUID
    let postId: UUID
    let userId: UUID
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case postId = "post_id"
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

// MARK: - Create Post Request

struct CreatePostRequest: Codable {
    let userId: UUID
    let topicId: UUID
    let title: String
    let content: String
    let category: String
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case topicId = "topic_id"
        case title
        case content
        case category
        case tags
    }
}

// MARK: - Create Comment Request

struct CreateCommentRequest: Codable {
    let postId: UUID
    let userId: UUID
    let content: String
    let parentCommentId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case postId = "post_id"
        case userId = "user_id"
        case content
        case parentCommentId = "parent_comment_id"
    }
}

