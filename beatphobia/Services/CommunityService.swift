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
    
    // MARK: - Caching
    private var cachedPosts: [String: [PostDisplayModel]] = [:] // In-memory cache
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes cache (300 seconds)
    
    // Local persistent storage keys
    private let userDefaults = UserDefaults.standard
    private let cachePrefix = "community_cache_"
    
    // MARK: - Cache Helpers
    
    private func getCacheKey(topicId: UUID? = nil, category: PostCategory? = nil, type: String = "posts") -> String {
        if type == "trending" { return "trending" }
        if type == "user" { return "user" }
        
        var key = topicId?.uuidString ?? "all"
        if let category = category, category != .all {
            key += "_\(category.rawValue)"
        }
        return key
    }
    
    private func isCacheValid(for key: String) -> Bool {
        guard let timestamp = cacheTimestamps[key] else { return false }
        return Date().timeIntervalSince(timestamp) < cacheValidityDuration
    }
    
    func invalidateCache() {
        cachedPosts.removeAll()
        cacheTimestamps.removeAll()
        
        // Clear ALL persistent cache entries (not just common keys)
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys where key.hasPrefix(cachePrefix) {
            userDefaults.removeObject(forKey: key)
        }
        
        print("🗑️ Cleared all caches (memory + persistent)")
    }
    
    func invalidateCache(for key: String) {
        cachedPosts.removeValue(forKey: key)
        cacheTimestamps.removeValue(forKey: key)
        
        // Clear persistent cache too
        userDefaults.removeObject(forKey: cachePrefix + key)
        userDefaults.removeObject(forKey: cachePrefix + key + "_timestamp")
    }
    
    // Update a specific post's like state in all caches
    func updatePostLikeState(postId: UUID, isLiked: Bool) {
        var cacheUpdated = false
        
        for (key, posts) in cachedPosts {
            if let index = posts.firstIndex(where: { $0.id == postId }) {
                var updatedPosts = posts
                
                // Create a mutable copy and update it
                var updatedPost = updatedPosts[index]
                let oldLikeState = updatedPost.isLiked
                updatedPost.isLiked = isLiked
                updatedPosts[index] = updatedPost
                
                // Update the cache
                cachedPosts[key] = updatedPosts
                
                // Update persistent cache too
                saveToPersistentCache(posts: updatedPosts, key: key)
                
                print("✅ Updated post \(postId) in cache '\(key)': isLiked \(oldLikeState) → \(isLiked)")
                cacheUpdated = true
            }
        }
        
        if !cacheUpdated {
            print("⚠️ Post \(postId) not found in any cache (cache might be empty)")
        }
    }
    
    // MARK: - Persistent Cache (UserDefaults)
    
    private func saveToPersistentCache(posts: [PostDisplayModel], key: String) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(posts)
            userDefaults.set(data, forKey: cachePrefix + key)
            userDefaults.set(Date(), forKey: cachePrefix + key + "_timestamp")
            print("💾 Saved \(posts.count) posts to persistent cache: \(key)")
        } catch {
            print("❌ Failed to save to persistent cache: \(error)")
        }
    }
    
    private func loadFromPersistentCache(key: String) -> [PostDisplayModel]? {
        guard let data = userDefaults.data(forKey: cachePrefix + key) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let posts = try decoder.decode([PostDisplayModel].self, from: data)
            
            if let timestamp = userDefaults.object(forKey: cachePrefix + key + "_timestamp") as? Date {
                let age = Date().timeIntervalSince(timestamp)
                print("📂 Loaded \(posts.count) posts from persistent cache: \(key) (age: \(Int(age))s)")
            }
            
            return posts
        } catch {
            print("❌ Failed to load from persistent cache: \(error)")
            // Clear corrupted cache
            userDefaults.removeObject(forKey: cachePrefix + key)
            userDefaults.removeObject(forKey: cachePrefix + key + "_timestamp")
            return nil
        }
    }
    
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
    
    func fetchPosts(topicId: UUID? = nil, category: PostCategory? = nil, searchText: String = "", forceRefresh: Bool = false) async throws -> [PostDisplayModel] {
        let cacheKey = getCacheKey(topicId: topicId, category: category)
        
        // Check in-memory cache first (skip if searching or force refresh)
        if !forceRefresh && searchText.isEmpty && isCacheValid(for: cacheKey), let cached = cachedPosts[cacheKey] {
            print("⚡️ Using in-memory cache for: \(cacheKey)")
            return cached
        }
        
        // Check persistent cache and return immediately if available
        if !forceRefresh && searchText.isEmpty, let persistentCached = loadFromPersistentCache(key: cacheKey) {
            // Return cached data immediately (don't set isLoading)
            // Store in memory cache too
            cachedPosts[cacheKey] = persistentCached
            cacheTimestamps[cacheKey] = Date()
            
            // Fetch fresh data in background without blocking
            Task {
                do {
                    let freshPosts = try await fetchPostsFromDatabase(topicId: topicId, category: category, searchText: searchText)
                    await MainActor.run {
                        cachedPosts[cacheKey] = freshPosts
                        cacheTimestamps[cacheKey] = Date()
                        saveToPersistentCache(posts: freshPosts, key: cacheKey)
                    }
                } catch {
                    print("❌ Background refresh failed: \(error)")
                }
            }
            
            return persistentCached
        }
        
        // No cache available, fetch from database
        isLoading = true
        defer { isLoading = false }
        
        let posts = try await fetchPostsFromDatabase(topicId: topicId, category: category, searchText: searchText)
        
        // Cache the results (only if not searching)
        if searchText.isEmpty {
            cachedPosts[cacheKey] = posts
            cacheTimestamps[cacheKey] = Date()
            saveToPersistentCache(posts: posts, key: cacheKey)
        }
        
        return posts
    }
    
    // MARK: - Fetch Posts from Database (Internal)
    
    private func fetchPostsFromDatabase(topicId: UUID? = nil, category: PostCategory? = nil, searchText: String = "") async throws -> [PostDisplayModel] {
        let response: [CommunityPostDBResponse] = try await {
            var query = supabase
                .from("community_posts")
                .select("*, profile(username, profile_image_url, role)")
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
        
        // Fetch attachments for each post
        var posts: [PostDisplayModel] = []
        for postResponse in response {
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            // Fetch attachments (don't fail the whole query if attachments fail)
            let attachments = (try? await fetchAttachments(postId: post.id)) ?? []
            
            // Debug logging for profile images
            if let profileImageUrl = postResponse.profile?.profileImageUrl {
                print("✅ Post \(post.id) has profile image: \(profileImageUrl)")
            } else {
                print("⚠️ Post \(post.id) by @\(post.authorUsername ?? "unknown") has no profile image")
            }
            
            posts.append(PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked, attachments: attachments, authorProfileImageUrl: postResponse.profile?.profileImageUrl, authorRole: postResponse.profile?.role))
        }
        
        return posts
    }
    
    // MARK: - Fetch Trending Posts
    
    func fetchTrendingPosts(forceRefresh: Bool = false) async throws -> [PostDisplayModel] {
        let cacheKey = getCacheKey(type: "trending")
        
        // Check in-memory cache first
        if !forceRefresh && isCacheValid(for: cacheKey), let cached = cachedPosts[cacheKey] {
            print("⚡️ Using in-memory cache for trending")
            return cached
        }
        
        // Check persistent cache and return immediately if available
        if !forceRefresh, let persistentCached = loadFromPersistentCache(key: cacheKey) {
            cachedPosts[cacheKey] = persistentCached
            cacheTimestamps[cacheKey] = Date()
            
            // Fetch fresh data in background
            Task {
                do {
                    let freshPosts = try await fetchTrendingFromDatabase()
                    await MainActor.run {
                        cachedPosts[cacheKey] = freshPosts
                        cacheTimestamps[cacheKey] = Date()
                        saveToPersistentCache(posts: freshPosts, key: cacheKey)
                    }
                } catch {
                    print("❌ Background trending refresh failed: \(error)")
                }
            }
            
            return persistentCached
        }
        
        // No cache available, fetch from database
        isLoading = true
        defer { isLoading = false }
        
        let posts = try await fetchTrendingFromDatabase()
        
        // Cache the results
        cachedPosts[cacheKey] = posts
        cacheTimestamps[cacheKey] = Date()
        saveToPersistentCache(posts: posts, key: cacheKey)
        
        return posts
    }
    
    // MARK: - Fetch Trending from Database (Internal)
    
    private func fetchTrendingFromDatabase() async throws -> [PostDisplayModel] {
        let response: [CommunityPostDBResponse] = try await supabase
            .from("community_posts")
            .select("*, profile(username, role)")
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
        
        // Fetch attachments for each post
        var posts: [PostDisplayModel] = []
        for postResponse in response {
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            // Fetch attachments (don't fail if attachments fail)
            let attachments = (try? await fetchAttachments(postId: post.id)) ?? []
            
            posts.append(PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked, attachments: attachments, authorRole: postResponse.profile?.role))
        }
        
        return posts
    }
    
    // MARK: - Fetch User's Posts
    
    func fetchUserPosts(forceRefresh: Bool = false) async throws -> [PostDisplayModel] {
        let cacheKey = getCacheKey(type: "user")
        
        // Check in-memory cache first
        if !forceRefresh && isCacheValid(for: cacheKey), let cached = cachedPosts[cacheKey] {
            print("⚡️ Using in-memory cache for user posts")
            return cached
        }
        
        // Check persistent cache and return immediately if available
        if !forceRefresh, let persistentCached = loadFromPersistentCache(key: cacheKey) {
            cachedPosts[cacheKey] = persistentCached
            cacheTimestamps[cacheKey] = Date()
            
            // Fetch fresh data in background
            Task {
                do {
                    let freshPosts = try await fetchUserPostsFromDatabase()
                    await MainActor.run {
                        cachedPosts[cacheKey] = freshPosts
                        cacheTimestamps[cacheKey] = Date()
                        saveToPersistentCache(posts: freshPosts, key: cacheKey)
                    }
                } catch {
                    print("❌ Background user posts refresh failed: \(error)")
                }
            }
            
            return persistentCached
        }
        
        // No cache available, fetch from database
        isLoading = true
        defer { isLoading = false }
        
        let posts = try await fetchUserPostsFromDatabase()
        
        // Cache the results
        cachedPosts[cacheKey] = posts
        cacheTimestamps[cacheKey] = Date()
        saveToPersistentCache(posts: posts, key: cacheKey)
        
        return posts
    }
    
    // MARK: - Fetch User Posts from Database (Internal)
    
    private func fetchUserPostsFromDatabase() async throws -> [PostDisplayModel] {
        let userId = try await supabase.auth.session.user.id
        
        let response: [CommunityPostDBResponse] = try await supabase
            .from("community_posts")
            .select("*, profile(username, profile_image_url, role)")
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false, nullsFirst: false)
            .execute()
            .value
        
        // Get current user's likes and bookmarks
        let likedPostIds = try await fetchUserLikedPosts(userId: userId)
        let bookmarkedPostIds = try await fetchUserBookmarks(userId: userId)
        
        // Fetch attachments for each post
        var posts: [PostDisplayModel] = []
        for postResponse in response {
            var post = postResponse.post
            post.authorUsername = postResponse.profile?.username
            
            let isLiked = likedPostIds.contains(post.id)
            let isBookmarked = bookmarkedPostIds.contains(post.id)
            
            // Fetch attachments (don't fail if attachments fail)
            let attachments = (try? await fetchAttachments(postId: post.id)) ?? []
            
            posts.append(PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked, attachments: attachments, authorProfileImageUrl: postResponse.profile?.profileImageUrl, authorRole: postResponse.profile?.role))
        }
        
        return posts
    }
    
    // MARK: - Fetch Single Post
    
    func fetchPost(id: UUID) async throws -> PostDisplayModel {
        let response: CommunityPostDBResponse = try await supabase
            .from("community_posts")
            .select("*, profile(username, role)")
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
        
        // Fetch attachments
        let attachments = (try? await fetchAttachments(postId: post.id)) ?? []
        
        // Increment view count
        struct IncrementViewCountRequest: Encodable {
            let views_count: Int
        }
        
        _ = try? await supabase
            .from("community_posts")
            .update(IncrementViewCountRequest(views_count: post.viewsCount + 1))
            .eq("id", value: id.uuidString)
            .execute()
        
        return PostDisplayModel(from: post, isLiked: isLiked, isBookmarked: isBookmarked, attachments: attachments, authorProfileImageUrl: response.profile?.profileImageUrl, authorRole: response.profile?.role)
    }
    
    // MARK: - Create Post
    
    func createPost(topicId: UUID, title: String, content: String, category: PostCategory, tags: [String], attachmentUrls: [String] = []) async throws -> UUID {
        isLoading = true
        defer { 
            isLoading = false
            // Invalidate cache after post is created
            invalidateCache()
        }
        
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
        
        print("✅ Post created with ID: \(response.id)")
        
        // Create attachments if any
        if !attachmentUrls.isEmpty {
            print("📎 Creating \(attachmentUrls.count) attachments...")
            try await createAttachments(postId: response.id, userId: userId, fileUrls: attachmentUrls)
        }
        
        print("🔄 Invalidating cache after post creation")
        
        return response.id
    }
    
    // MARK: - Create Attachments
    
    func createAttachments(postId: UUID? = nil, commentId: UUID? = nil, userId: UUID, fileUrls: [String]) async throws {
        // Limit to 3 attachments
        let limitedUrls = Array(fileUrls.prefix(3))
        
        let attachmentRequests = limitedUrls.map { url in
            CreateAttachmentRequest(
                postId: postId,
                commentId: commentId,
                userId: userId,
                fileUrl: url,
                fileType: "image",
                fileSize: nil,
                mimeType: "image/jpeg",
                width: nil,
                height: nil
            )
        }
        
        // Insert attachments without requiring a response
        // (We don't need the returned data, just successful creation)
        if !attachmentRequests.isEmpty {
            do {
                try await supabase
                    .from("community_attachments")
                    .insert(attachmentRequests)
                    .execute()
                
                print("✅ Created \(attachmentRequests.count) attachments")
            } catch {
                print("❌ Error creating attachments: \(error)")
                // Don't throw - post was already created, attachments failing shouldn't break the post
            }
        }
    }
    
    // MARK: - Fetch Attachments
    
    func fetchAttachments(postId: UUID) async throws -> [Attachment] {
        let attachments: [Attachment] = try await supabase
            .from("community_attachments")
            .select()
            .eq("post_id", value: postId.uuidString)
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return attachments
    }
    
    func fetchCommentAttachments(commentId: UUID) async throws -> [Attachment] {
        let attachments: [Attachment] = try await supabase
            .from("community_attachments")
            .select()
            .eq("comment_id", value: commentId.uuidString)
            .eq("is_deleted", value: false)
            .eq("is_flagged", value: false)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return attachments
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
            .select("*, profile(username, profile_image_url, role)")
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
            return CommentDisplayModel(from: comment, isLiked: isLiked, replies: [], attachments: [], authorProfileImageUrl: commentResponse.profile?.profileImageUrl, authorRole: commentResponse.profile?.role)
        }
        
        // Organize into threaded structure
        return organizeComments(comments)
    }
    
    // MARK: - Create Comment
    
    func createComment(postId: UUID, content: String, parentCommentId: UUID? = nil) async throws {
        isLoading = true
        defer { 
            isLoading = false
            // Invalidate cache after comment is created
            invalidateCache()
        }
        
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
        
        print("🔍 Checking if post \(postId) is liked by user \(userId)")
        
        // Check if already liked
        let existing: [PostLike] = try await supabase
            .from("community_post_likes")
            .select()
            .eq("post_id", value: postId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        print("📊 Found \(existing.count) existing likes")
        
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
            
            print("✅ Post liked successfully")
            
            // Update cache to reflect new like state
            updatePostLikeState(postId: postId, isLiked: true)
            
            return true
        } else {
            // Unlike the post
            try await supabase
                .from("community_post_likes")
                .delete()
                .eq("post_id", value: postId.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            print("✅ Post unliked successfully")
            
            // Update cache to reflect new like state
            updatePostLikeState(postId: postId, isLiked: false)
            
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
    
    // MARK: - Report Content
    
    func reportContent(postId: UUID?, commentId: UUID?, reason: String, details: String?) async throws {
        let userId = try await supabase.auth.session.user.id
        
        let report = CreateReportRequest(
            reporterId: userId,
            postId: postId,
            commentId: commentId,
            reason: reason,
            details: details
        )
        
        try await supabase
            .from("content_reports")
            .insert(report)
            .execute()
        
        print("✅ Successfully reported content")
    }
    
    // MARK: - Block User
    
    func blockUser(blockedUserId: UUID, reason: String?) async throws {
        let userId = try await supabase.auth.session.user.id
        
        let block = CreateBlockRequest(
            blockerId: userId,
            blockedId: blockedUserId,
            reason: reason
        )
        
        try await supabase
            .from("user_blocks")
            .insert(block)
            .execute()
        
        print("✅ Successfully blocked user")
    }
    
    // MARK: - Unblock User
    
    func unblockUser(blockedUserId: UUID) async throws {
        let userId = try await supabase.auth.session.user.id
        
        try await supabase
            .from("user_blocks")
            .delete()
            .eq("blocker_id", value: userId.uuidString)
            .eq("blocked_id", value: blockedUserId.uuidString)
            .execute()
        
        print("✅ Successfully unblocked user")
    }
    
    // MARK: - Check if User is Blocked
    
    func isUserBlocked(userId: UUID) async throws -> Bool {
        let currentUserId = try await supabase.auth.session.user.id
        
        let blocks: [UserBlock] = try await supabase
            .from("user_blocks")
            .select()
            .eq("blocker_id", value: currentUserId.uuidString)
            .eq("blocked_id", value: userId.uuidString)
            .execute()
            .value
        
        return !blocks.isEmpty
    }
    
    // MARK: - Get Blocked Users
    
    func getBlockedUsers() async throws -> [UUID] {
        let userId = try await supabase.auth.session.user.id
        
        let blocks: [UserBlock] = try await supabase
            .from("user_blocks")
            .select()
            .eq("blocker_id", value: userId.uuidString)
            .execute()
            .value
        
        return blocks.map { $0.blockedId }
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
    let profileImageUrl: String?
    let role: String?
    
    enum CodingKeys: String, CodingKey {
        case username
        case profileImageUrl = "profile_image_url"
        case role
    }
}

struct EmptyResponse: Codable {}
