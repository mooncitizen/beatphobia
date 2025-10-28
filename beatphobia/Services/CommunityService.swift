//
//  CommunityService.swift
//  beatphobia
//
//  Service layer for community forum operations
//

import Foundation
import Supabase
import Combine

@MainActor
class CommunityService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Fetch Topics
    
    func fetchTopics() async throws -> [CommunityTopic] {
        let topics: [CommunityTopic] = try await supabase
            .from("community_topics")
            .select()
            .order("name", ascending: true)
            .execute()
            .value
        
        // Sort with "Notices" and "App Suggestions" at the top, then alphabetical
        return topics.sorted { topic1, topic2 in
            let topic1IsSpecial = topic1.name == "Notices" || topic1.name == "App Suggestions"
            let topic2IsSpecial = topic2.name == "Notices" || topic2.name == "App Suggestions"
            
            // Both special - "Notices" comes before "App Suggestions"
            if topic1IsSpecial && topic2IsSpecial {
                if topic1.name == "Notices" { return true }
                if topic2.name == "Notices" { return false }
                return topic1.name < topic2.name
            }
            
            // One is special - special ones go first
            if topic1IsSpecial { return true }
            if topic2IsSpecial { return false }
            
            // Neither is special - alphabetical order
            return topic1.name < topic2.name
        }
    }
    
    // MARK: - Fetch Posts
    
    func fetchPosts(topicId: UUID? = nil, category: PostCategory? = nil, searchText: String = "") async throws -> [PostDisplayModel] {
        isLoading = true
        defer { isLoading = false }
        
        let response: [CommunityPostDBResponse] = try await {
            var query = supabase
                .from("community_posts")
                .select("*, profile(username)")
                .eq("is_deleted", value: false)
                .eq("is_flagged", value: false)
            
            // Filter by topic if provided
            if let topicId = topicId {
                query = query.eq("topic_id", value: topicId.uuidString)
            }
            
            // Filter by category if not "all"
            if let category = category, category != .all {
                query = query.eq("category", value: category.databaseValue)
            }
            
            // Search filter
            if !searchText.isEmpty {
                query = query.or("title.ilike.%\(searchText)%,content.ilike.%\(searchText)%")
            }
            
            return try await query
                .order("created_at", ascending: false, nullsFirst: false)
                .execute()
                .value
        }()
        
        // Get current user's likes and bookmarks
        let userId = try await supabase.auth.session.user.id
        let likedPostIds = try await fetchUserLikedPosts(userId: userId)
        let bookmarkedPostIds = try await fetchUserBookmarks(userId: userId)
        
        return response.map { postResponse in
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            return PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked)
        }
    }
    
    // MARK: - Fetch Trending Posts
    
    func fetchTrendingPosts() async throws -> [PostDisplayModel] {
        isLoading = true
        defer { isLoading = false }
        
        let response: [CommunityPostDBResponse] = try await supabase
            .from("community_posts")
            .select("*, profile(username)")
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .eq("trending", value: true)
            .order("created_at", ascending: false, nullsFirst: false)
            .execute()
            .value
        
        // Get current user's likes and bookmarks
        let userId = try await supabase.auth.session.user.id
        let likedPostIds = try await fetchUserLikedPosts(userId: userId)
        let bookmarkedPostIds = try await fetchUserBookmarks(userId: userId)
        
        return response.map { postResponse in
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            return PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked)
        }
    }
    
    // MARK: - Fetch User's Posts
    
    func fetchUserPosts() async throws -> [PostDisplayModel] {
        isLoading = true
        defer { isLoading = false }
        
        let userId = try await supabase.auth.session.user.id
        
        let response: [CommunityPostDBResponse] = try await supabase
            .from("community_posts")
            .select("*, profile(username)")
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false, nullsFirst: false)
            .execute()
            .value
        
        // Get current user's likes and bookmarks
        let likedPostIds = try await fetchUserLikedPosts(userId: userId)
        let bookmarkedPostIds = try await fetchUserBookmarks(userId: userId)
        
        return response.map { postResponse in
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            return PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked)
        }
    }
    
    // MARK: - Fetch Single Post
    
    func fetchPost(id: UUID) async throws -> PostDisplayModel {
        let response: CommunityPostDBResponse = try await supabase
            .from("community_posts")
            .select("*, profile(username)")
            .eq("id", value: id.uuidString)
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .single()
            .execute()
            .value
        
        let userId = try await supabase.auth.session.user.id
        let likedPostIds = try await fetchUserLikedPosts(userId: userId)
        let bookmarkedPostIds = try await fetchUserBookmarks(userId: userId)
        
        var post = response.post
        post.authorUsername = response.profile?.username
        
        let isLiked = likedPostIds.contains(post.id)
        let isBookmarked = bookmarkedPostIds.contains(post.id)
        
        // Increment view count
        struct IncrementViewCountRequest: Encodable {
            let views_count: Int
        }
        
        _ = try? await supabase
            .from("community_posts")
            .update(IncrementViewCountRequest(views_count: post.viewsCount + 1))
            .eq("id", value: id.uuidString)
            .execute()
        
        return PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked)
    }
    
    // MARK: - Create Post
    
    func createPost(topicId: UUID, title: String, content: String, category: PostCategory, tags: [String]) async throws -> UUID {
        isLoading = true
        defer { isLoading = false }
        
        let userId = try await supabase.auth.session.user.id
        
        let request = CreatePostRequest(
            userId: userId,
            topicId: topicId,
            title: title,
            content: content,
            category: category.databaseValue,
            tags: tags
        )
        
        let response: CommunityPostDB = try await supabase
            .from("community_posts")
            .insert(request)
            .select()
            .single()
            .execute()
            .value
        
        return response.id
    }
    
    // MARK: - Update Post
    
    func updatePost(id: UUID, title: String, content: String, category: PostCategory, tags: [String]) async throws {
        isLoading = true
        defer { isLoading = false }
        
        struct UpdatePostRequest: Encodable {
            let title: String
            let content: String
            let category: String
            let tags: [String]
        }
        
        let updates = UpdatePostRequest(
            title: title,
            content: content,
            category: category.databaseValue,
            tags: tags
        )
        
        try await supabase
            .from("community_posts")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Delete Post
    
    func deletePost(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        struct DeletePostRequest: Encodable {
            let is_deleted: Bool
        }
        
        // Soft delete
        let _: EmptyResponse = try await supabase
            .from("community_posts")
            .update(DeletePostRequest(is_deleted: true))
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        print("✅ Successfully deleted post with id: \(id)")
    }
    
    // MARK: - Fetch Comments
    
    func fetchComments(postId: UUID) async throws -> [CommentDisplayModel] {
        let response: [CommunityCommentDBResponse] = try await supabase
            .from("community_comments")
            .select("*, profile(username)")
            .eq("post_id", value: postId.uuidString)
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        let userId = try await supabase.auth.session.user.id
        let likedCommentIds = try await fetchUserLikedComments(userId: userId)
        
        let comments: [CommentDisplayModel] = response.map { commentResponse in
            var comment = commentResponse.comment
            comment.authorUsername = commentResponse.profile?.username
            let isLiked = likedCommentIds.contains(comment.id)
            return CommentDisplayModel(from: comment, isLiked: isLiked)
        }
        
        // Organize into threaded structure
        return organizeComments(comments)
    }
    
    // MARK: - Create Comment
    
    func createComment(postId: UUID, content: String, parentCommentId: UUID? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        let userId = try await supabase.auth.session.user.id
        
        let request = CreateCommentRequest(
            postId: postId,
            userId: userId,
            content: content,
            parentCommentId: parentCommentId
        )
        
        try await supabase
            .from("community_comments")
            .insert(request)
            .execute()
    }
    
    // MARK: - Update Comment
    
    func updateComment(id: UUID, content: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        struct UpdateCommentRequest: Encodable {
            let content: String
        }
        
        let updates = UpdateCommentRequest(content: content)
        
        try await supabase
            .from("community_comments")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Delete Comment
    
    func deleteComment(id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        struct DeleteCommentRequest: Encodable {
            let is_deleted: Bool
        }
        
        // Soft delete
        let _: EmptyResponse = try await supabase
            .from("community_comments")
            .update(DeleteCommentRequest(is_deleted: true))
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        print("✅ Successfully deleted comment with id: \(id)")
    }
    
    // MARK: - Like/Unlike Post
    
    func togglePostLike(postId: UUID) async throws -> Bool {
        let userId = try await supabase.auth.session.user.id
        
        // Check if already liked
        let existing: [PostLike] = try await supabase
            .from("community_post_likes")
            .select()
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing.isEmpty {
            // Like the post
            struct CreatePostLikeRequest: Encodable {
                let post_id: String
                let user_id: String
            }
            
            let like = CreatePostLikeRequest(
                post_id: postId.uuidString,
                user_id: userId.uuidString
            )
            
            try await supabase
                .from("community_post_likes")
                .insert(like)
                .execute()
            return true
        } else {
            // Unlike the post
            try await supabase
                .from("community_post_likes")
                .delete()
                .eq("post_id", value: postId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }
    
    // MARK: - Like/Unlike Comment
    
    func toggleCommentLike(commentId: UUID) async throws -> Bool {
        let userId = try await supabase.auth.session.user.id
        
        // Check if already liked
        let existing: [CommentLike] = try await supabase
            .from("community_comment_likes")
            .select()
            .eq("comment_id", value: commentId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing.isEmpty {
            // Like the comment
            struct CreateCommentLikeRequest: Encodable {
                let comment_id: String
                let user_id: String
            }
            
            let like = CreateCommentLikeRequest(
                comment_id: commentId.uuidString,
                user_id: userId.uuidString
            )
            
            try await supabase
                .from("community_comment_likes")
                .insert(like)
                .execute()
            return true
        } else {
            // Unlike the comment
            try await supabase
                .from("community_comment_likes")
                .delete()
                .eq("comment_id", value: commentId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }
    
    // MARK: - Bookmark/Unbookmark Post
    
    func togglePostBookmark(postId: UUID) async throws -> Bool {
        let userId = try await supabase.auth.session.user.id
        
        // Check if already bookmarked
        let existing: [PostBookmark] = try await supabase
            .from("community_post_bookmarks")
            .select()
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existing.isEmpty {
            // Bookmark the post
            struct CreateBookmarkRequest: Encodable {
                let post_id: String
                let user_id: String
            }
            
            let bookmark = CreateBookmarkRequest(
                post_id: postId.uuidString,
                user_id: userId.uuidString
            )
            
            try await supabase
                .from("community_post_bookmarks")
                .insert(bookmark)
                .execute()
            return true
        } else {
            // Remove bookmark
            try await supabase
                .from("community_post_bookmarks")
                .delete()
                .eq("post_id", value: postId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchUserLikedPosts(userId: UUID) async throws -> Set<UUID> {
        let likes: [PostLike] = try await supabase
            .from("community_post_likes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return Set(likes.map { $0.postId })
    }
    
    private func fetchUserLikedComments(userId: UUID) async throws -> Set<UUID> {
        let likes: [CommentLike] = try await supabase
            .from("community_comment_likes")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return Set(likes.map { $0.commentId })
    }
    
    private func fetchUserBookmarks(userId: UUID) async throws -> Set<UUID> {
        let bookmarks: [PostBookmark] = try await supabase
            .from("community_post_bookmarks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        return Set(bookmarks.map { $0.postId })
    }
    
    private func organizeComments(_ comments: [CommentDisplayModel]) -> [CommentDisplayModel] {
        var commentDict: [UUID: CommentDisplayModel] = [:]
        
        // First pass: create dictionary of all comments
        for comment in comments {
            commentDict[comment.id] = comment
        }
        
        // Second pass: organize into threaded structure
        for comment in comments {
            if let parentId = comment.parentCommentId {
                if var parent = commentDict[parentId] {
                    parent.replies.append(comment)
                    commentDict[parentId] = parent
                }
            }
        }
        
        // Third pass: rebuild comments with their replies
        var finalComments: [UUID: CommentDisplayModel] = [:]
        for (id, var comment) in commentDict {
            if comment.parentCommentId != nil {
                // This is a reply, skip it (it's in parent's replies)
                continue
            } else {
                // This is a root comment, add replies recursively
                comment.replies = buildRepliesTree(for: id, from: commentDict)
                finalComments[id] = comment
            }
        }
        
        // Return root comments sorted by creation date
        return finalComments.values.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func buildRepliesTree(for commentId: UUID, from dict: [UUID: CommentDisplayModel]) -> [CommentDisplayModel] {
        var replies: [CommentDisplayModel] = []
        
        for (_, var comment) in dict {
            if comment.parentCommentId == commentId {
                // Recursively build replies for this comment
                comment.replies = buildRepliesTree(for: comment.id, from: dict)
                replies.append(comment)
            }
        }
        
        return replies.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Response Models for Supabase Joins

struct CommunityPostDBResponse: Codable {
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
    let trending: Bool?
    let createdAt: Date
    let updatedAt: Date
    let profile: ProfileInfo?
    
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
        case profile
    }
    
    var post: CommunityPostDB {
        CommunityPostDB(
            id: id,
            userId: userId,
            topicId: topicId,
            title: title,
            content: content,
            category: category,
            likesCount: likesCount,
            commentsCount: commentsCount,
            viewsCount: viewsCount,
            tags: tags,
            isDeleted: isDeleted,
            isFlagged: isFlagged,
            trending: trending ?? false,
            createdAt: createdAt,
            updatedAt: updatedAt,
            authorUsername: profile?.username
        )
    }
}

struct CommunityCommentDBResponse: Codable {
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
    let profile: ProfileInfo?
    
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
        case profile
    }
    
    var comment: CommunityCommentDB {
        CommunityCommentDB(
            id: id,
            postId: postId,
            userId: userId,
            content: content,
            parentCommentId: parentCommentId,
            likesCount: likesCount,
            isDeleted: isDeleted,
            isFlagged: isFlagged,
            createdAt: createdAt,
            updatedAt: updatedAt,
            authorUsername: profile?.username
        )
    }
}

struct ProfileInfo: Codable {
    let username: String?
}

struct EmptyResponse: Codable {}
