import SwiftUI
import Supabase

// NOTE: PostCategory and Post models are now in CommunityModels.swift

// MARK: - Community Section Model

struct CommunitySection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: Int?
    let destination: CommunityDestination
}

enum CommunityDestination {
    case forum
    case yourPosts
    case friends
    case chats
    case trending
    case guidelines
}

// MARK: - Main View

struct CommunityOverview: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showNotifications = false
    @State private var unreadMessages = 3
    @State private var newForumPosts = 12
    @State private var hasUsername: Bool? = nil // nil = checking, true = has username, false = needs username
    @State private var showUsernameSetup = false
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var communitySections: [CommunitySection] {
        [
            CommunitySection(
                title: "Forum",
                subtitle: "Browse discussions & posts",
                icon: "bubble.left.and.bubble.right.fill",
                color: .purple,
                badge: newForumPosts,
                destination: .forum
            ),
            CommunitySection(
                title: "Your Posts",
                subtitle: "View your contributions",
                icon: "doc.text.fill",
                color: .blue,
                badge: nil,
                destination: .yourPosts
            ),
            CommunitySection(
                title: "Your Friends",
                subtitle: "Connect with supporters",
                icon: "person.2.fill",
                color: .pink,
                badge: nil,
                destination: .friends
            ),
            CommunitySection(
                title: "Your Chats",
                subtitle: "Private conversations",
                icon: "message.fill",
                color: .green,
                badge: unreadMessages > 0 ? unreadMessages : nil,
                destination: .chats
            ),
            CommunitySection(
                title: "Trending Topics",
                subtitle: "Popular discussions now",
                icon: "flame.fill",
                color: .orange,
                badge: nil,
                destination: .trending
            ),
            CommunitySection(
                title: "Guidelines & Help",
                subtitle: "Community rules & support",
                icon: "info.circle.fill",
                color: .cyan,
                badge: nil,
                destination: .guidelines
            )
        ]
    }
    
    var body: some View {
        Group {
            if hasUsername == nil {
                // Checking username status
                FullScreenLoading(text: "Loading Community")
            } else if hasUsername == false || showUsernameSetup {
                // Show username setup
                UsernameSetupView(existingUsername: nil) {
                    hasUsername = true
                    showUsernameSetup = false
                }
            } else {
                // Has username - show community
                communityContent
            }
        }
        .task {
            await checkUsername()
        }
    }
    
    private var communityContent: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Community")
                                    .font(.system(size: 40, weight: .bold, design: .serif))
                                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                                Text("Connect, share, and grow together")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            }
                            
                            Spacer()
                            
                            // Notifications Button
                            // Button(action: {
                            //     lightHaptic.impactOccurred(intensity: 0.5)
                            //     showNotifications = true
                            // }) {
                            //     ZStack(alignment: .topTrailing) {
                            //         Image(systemName: "bell.fill")
                            //             .font(.system(size: 20, weight: .semibold))
                            //             .foregroundColor(.white)
                            //             .frame(width: 44, height: 44)
                            //             .background(AppConstants.primaryColor)
                            //             .clipShape(Circle())
                                    
                            //         if unreadMessages > 0 {
                            //             Circle()
                            //                 .fill(Color.red)
                            //                 .frame(width: 18, height: 18)
                            //                 .overlay(
                            //                     Text("\(unreadMessages)")
                            //                         .font(.system(size: 10, weight: .bold))
                            //                         .foregroundColor(.white)
                            //                 )
                            //                 .offset(x: 4, y: -4)
                            //         }
                            //     }
                            // }
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Welcome Card
                    // Card(backgroundColor: AppConstants.primaryColor.opacity(0.1), cornerRadius: 16, padding: 0) {
                    //     HStack(spacing: 16) {
                    //         Image(systemName: "heart.circle.fill")
                    //             .font(.system(size: 48))
                    //             .foregroundColor(AppConstants.primaryColor)
                            
                    //         VStack(alignment: .leading, spacing: 4) {
                    //             Text("You're not alone")
                    //                 .font(.system(size: 20, weight: .bold, design: .serif))
                    //                 .foregroundColor(.black)
                                
                    //             Text("2.3K members supporting each other")
                    //                 .font(.system(size: 14))
                    //                 .foregroundColor(.black.opacity(0.7))
                    //         }
                            
                    //         Spacer()
                    //     }
                    //     .padding(20)
                    // }
                    
                    // Community Stats - TODO: Re-enable later
//                    HStack(spacing: 12) {
//                        CommunityStatCard(icon: "bubble.left.and.bubble.right.fill", value: "1.2K", label: "Posts", color: .purple)
//                        CommunityStatCard(icon: "heart.fill", value: "8.4K", label: "Support", color: .pink)
//                        CommunityStatCard(icon: "person.2.fill", value: "2.3K", label: "Members", color: .blue)
//                    }
                    
                    // Main Navigation Sections
                    VStack(spacing: 16) {
                        ForEach(communitySections) { section in
                            NavigationLink(destination: destinationView(for: section.destination)) {
                                CommunityNavigationCard(section: section)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationBarHidden(true)
        }
        .onAppear {
            lightHaptic.prepare()
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
    }
    
    // MARK: - Username Check
    
    private func checkUsername() async {
        do {
            let userId = try await supabase.auth.session.user.id
            
            let profile: Profile = try await supabase
                .from("profile")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            await MainActor.run {
                // Check if username exists and is not empty
                hasUsername = profile.username != nil && !profile.username!.isEmpty
            }
        } catch {
            await MainActor.run {
                // If there's an error, assume no username to be safe
                hasUsername = false
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: CommunityDestination) -> some View {
        switch destination {
        case .forum:
            CommunityForumView()
        case .yourPosts:
            YourPostsView()
        case .friends:
            FriendsListView()
        case .chats:
            ChatsListView()
        case .trending:
            TrendingTopicsView()
        case .guidelines:
            GuidelinesView()
        }
    }
}

// MARK: - Supporting Views

struct CommunityNavigationCard: View {
    @Environment(\.colorScheme) var colorScheme
    let section: CommunitySection

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 16, padding: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(section.color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: section.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(section.color)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(section.title)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(section.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                
                Spacer()
                
                // Badge and Arrow
                // HStack(spacing: 12) {
                //     if let badge = section.badge {
                //         Text("\(badge)")
                //             .font(.system(size: 12, weight: .bold))
                //             .foregroundColor(.white)
                //             .padding(.horizontal, 8)
                //             .padding(.vertical, 4)
                //             .background(Color.red)
                //             .clipShape(Capsule())
                //     }
                    
                //     Image(systemName: "chevron.right")
                //         .font(.system(size: 14, weight: .semibold))
                //         .foregroundColor(.black.opacity(0.3))
                // }
            }
            .padding(16)
        }
    }
}

struct CommunityStatCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 12, padding: 0) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Destination Views

struct CommunityForumView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    @State private var topics: [CommunityTopic] = []
    @State private var searchText = ""

    var filteredTopics: [CommunityTopic] {
        if searchText.isEmpty {
            return topics
        } else {
            return topics.filter { topic in
                topic.name.localizedCaseInsensitiveContains(searchText) ||
                topic.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose a Topic")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("Join discussions and share your experiences")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .padding(.top, 8)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                    TextField("Search topics...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                .padding(12)
                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                )
                
                // Topics Grid
                if communityService.isLoading {
                    FullScreenLoading(text: "Loading Community")
                } else if let error = communityService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Topics")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Try Again") {
                            Task {
                                await loadTopics()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 40)
                } else if filteredTopics.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No topics found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        Text("Try a different search term")
                            .font(.system(size: 14))
                            .foregroundColor(.black.opacity(0.5))
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTopics) { topic in
                            NavigationLink(destination: TopicDetailView(topic: topic)) {
                                TopicCard(topic: topic)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Forum")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTopics()
        }
        .refreshable {
            await loadTopics()
        }
    }
    
    private func loadTopics() async {
        do {
            topics = try await communityService.fetchTopics()
            communityService.error = nil
        } catch is CancellationError {
            return
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return
        } catch {
            print("❌ Error loading topics: \(error)")
            communityService.error = error.localizedDescription
        }
    }
}

struct YourPostsView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    @State private var posts: [PostDisplayModel] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.blue)
                    }

                    Text("Your Posts")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("View and manage all your community contributions")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Posts List
                if communityService.isLoading && posts.isEmpty {
                    FullScreenLoading(text: "Loading Your Posts")
                } else if let error = communityService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Posts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Try Again") {
                            Task {
                                await loadUserPosts()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 40)
                } else if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))

                        Text("No posts yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                        Text("Start sharing your thoughts with the community!")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostCard(post: post, communityService: communityService)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await loadUserPosts()
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Your Posts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadUserPosts()
        }
    }
    
    private func loadUserPosts() async {
        do {
            posts = try await communityService.fetchUserPosts()
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // Ignore cancellation errors (e.g., when pulling to refresh)
            return
        } catch {
            communityService.error = "Failed to load your posts. Please try again."
            print("❌ Error loading user posts: \(error)")
        }
    }
}

// MARK: - Topic Detail View

struct TopicDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    let topic: CommunityTopic
    @StateObject private var communityService = CommunityService()
    @State private var selectedCategory: PostCategory = .all
    @State private var searchText = ""
    @State private var showNewPostSheet = false
    @State private var posts: [PostDisplayModel] = []

    var filteredPosts: [PostDisplayModel] {
        posts.filter { post in
            (selectedCategory == .all || post.category == selectedCategory) &&
            (searchText.isEmpty ||
             post.title.localizedCaseInsensitiveContains(searchText) ||
             post.content.localizedCaseInsensitiveContains(searchText) ||
             post.tags.contains { $0.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Topic Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(topic.swiftUIColor.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: topic.icon)
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(topic.swiftUIColor)
                    }

                    Text(topic.name)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(topic.description)
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                    TextField("Search posts...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                }
                .padding(12)
                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                )
                
                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(PostCategory.allCases) { category in
                            CategoryPill(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                
                // Posts List
                if communityService.isLoading {
                    FullScreenLoading(text: "Loading Posts")
                } else if let error = communityService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Posts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Try Again") {
                            Task {
                                await loadPosts()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 40)
                } else if filteredPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: searchText.isEmpty ? "doc.text" : "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))

                        Text(searchText.isEmpty ? "No posts yet" : "No results found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                        Text(searchText.isEmpty ? "Be the first to start a discussion!" : "Try a different search term")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredPosts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostCard(post: post, communityService: communityService)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showNewPostSheet = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                }
            }
        }
        .task {
            await loadPosts()
        }
        .refreshable {
            await loadPosts()
        }
        .sheet(isPresented: $showNewPostSheet) {
            CreatePostView(topic: topic, communityService: communityService) {
                Task {
                    await loadPosts()
                }
            }
        }
    }
    
    private func loadPosts() async {
        do {
            let category = selectedCategory == .all ? nil : selectedCategory
            posts = try await communityService.fetchPosts(topicId: topic.id, category: category, searchText: searchText)
            communityService.error = nil
        } catch is CancellationError {
            return
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            return
        } catch {
            print("❌ Error loading posts: \(error)")
            communityService.error = error.localizedDescription
        }
    }
}

struct FriendsListView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon Header
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.pink)
                }
                .padding(.top, 40)

                // Title and Description
                VStack(spacing: 12) {
                    Text("Your Friends")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("Connect with supporters on your journey")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Coming Soon Badge
                Text("COMING SOON")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.pink)
                    .clipShape(Capsule())
                
                // Feature Cards
                VStack(spacing: 16) {
                    FeatureInfoCard(
                        icon: "person.badge.plus",
                        title: "Add Friends",
                        description: "Connect with other community members who understand your journey",
                        color: .pink
                    )
                    
                    FeatureInfoCard(
                        icon: "bell.badge",
                        title: "Stay Updated",
                        description: "Get notified when your friends share new posts or achievements",
                        color: .purple
                    )
                    
                    FeatureInfoCard(
                        icon: "heart.circle",
                        title: "Support Network",
                        description: "Build a supportive network of people facing similar challenges",
                        color: .blue
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Info Text
                VStack(spacing: 8) {
                    Text("We're working hard to bring you this feature")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Text("Check back soon!")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Feature Info Card

struct FeatureInfoCard: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 16, padding: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(16)
        }
    }
}

struct ChatsListView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Icon Header
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "message.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.top, 40)

                // Title and Description
                VStack(spacing: 12) {
                    Text("Your Chats")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("Private conversations with community members")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Coming Soon Badge
                Text("COMING SOON")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(Capsule())
                
                // Feature Cards
                VStack(spacing: 16) {
                    FeatureInfoCard(
                        icon: "bubble.left.and.bubble.right.fill",
                        title: "Private Messaging",
                        description: "Have one-on-one conversations with friends in a safe, private space",
                        color: .green
                    )
                    
                    FeatureInfoCard(
                        icon: "lock.shield",
                        title: "Secure & Private",
                        description: "Your conversations are private and only visible to you and your friend",
                        color: .blue
                    )
                    
                    FeatureInfoCard(
                        icon: "paperplane.fill",
                        title: "Real-Time Chat",
                        description: "Send messages, share experiences, and support each other instantly",
                        color: .purple
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Info Text
                VStack(spacing: 8) {
                    Text("We're working hard to bring you this feature")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Text("Check back soon!")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.5))
                }
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrendingTopicsView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var communityService = CommunityService()
    @State private var posts: [PostDisplayModel] = []
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    Text("Trending Topics")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("Popular discussions and hot topics right now")
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                
                // Posts List
                if communityService.isLoading && posts.isEmpty {
                    FullScreenLoading(text: "Loading Trending Posts")
                } else if let error = communityService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)

                        Text("Error Loading Posts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button("Try Again") {
                            Task {
                                await loadTrendingPosts()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppConstants.adaptivePrimaryColor(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.top, 40)
                } else if posts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "flame")
                            .font(.system(size: 48))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))

                        Text("No trending posts")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

                        Text("Check back later for hot topics!")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(posts) { post in
                            NavigationLink(destination: PostDetailView(post: post)) {
                                PostCard(post: post, communityService: communityService)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await loadTrendingPosts()
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Trending")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadTrendingPosts()
        }
    }
    
    private func loadTrendingPosts() async {
        do {
            posts = try await communityService.fetchTrendingPosts()
        } catch let error as NSError where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            // Ignore cancellation errors (e.g., when pulling to refresh)
            return
        } catch {
            communityService.error = "Failed to load trending posts. Please try again."
            print("❌ Error loading trending posts: \(error)")
        }
    }
}

struct GuidelinesView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Community Guidelines")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("Creating a safe and supportive space for everyone")
                        .font(.system(size: 16))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                
                GuidelineSection(
                    icon: "heart.fill",
                    title: "Be Kind and Supportive",
                    description: "Remember that everyone is on their own journey. Offer encouragement and understanding."
                )
                
                GuidelineSection(
                    icon: "shield.fill",
                    title: "Respect Privacy",
                    description: "Never share personal information of others. Keep conversations confidential."
                )
                
                GuidelineSection(
                    icon: "exclamationmark.triangle.fill",
                    title: "No Medical Advice",
                    description: "Share personal experiences, but never provide medical or professional advice."
                )
                
                GuidelineSection(
                    icon: "hand.raised.fill",
                    title: "No Harassment or Bullying",
                    description: "Treat all members with respect. Harassment of any kind will not be tolerated."
                )
                
                GuidelineSection(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Stay on Topic",
                    description: "Keep discussions relevant to anxiety, panic, and mental health support."
                )
                
                Card(backgroundColor: AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.1), cornerRadius: 16, padding: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))

                            Text("Need Help?")
                                .font(.system(size: 18, weight: .bold, design: .serif))
                                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        }

                        Text("If you see content that violates these guidelines, please report it to our moderation team.")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                    .padding(20)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuidelineSection: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let title: String
    let description: String

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 12, padding: 0) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
            }
            .padding(16)
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 64))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    
                    Text("No new notifications")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text("We'll notify you when there's activity")
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.primaryColor)
                }
            }
        }
    }
}

struct CategoryPill: View {
    @Environment(\.colorScheme) var colorScheme
    let category: PostCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))

                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? category.color : AppConstants.cardBackgroundColor(for: colorScheme))
            .foregroundColor(isSelected ? .white : AppConstants.secondaryTextColor(for: colorScheme))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppConstants.borderColor(for: colorScheme), lineWidth: 1.5)
            )
            .shadow(color: isSelected ? category.color.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Topic Card

struct TopicCard: View {
    @Environment(\.colorScheme) var colorScheme
    let topic: CommunityTopic

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 16, padding: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(topic.swiftUIColor.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: topic.icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(topic.swiftUIColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic.name)
                        .font(.system(size: 18, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(topic.description)
                        .font(.system(size: 14))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .lineLimit(2)
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
            }
            .padding(16)
        }
    }
}

// MARK: - Post Card

struct PostCard: View {
    @Environment(\.colorScheme) var colorScheme
    let post: PostDisplayModel
    let communityService: CommunityService
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool

    init(post: PostDisplayModel, communityService: CommunityService) {
        self.post = post
        self.communityService = communityService
        self._isLiked = State(initialValue: post.isLiked)
        self._isBookmarked = State(initialValue: post.isBookmarked)
    }

    var body: some View {
        Card(backgroundColor: AppConstants.cardBackgroundColor(for: colorScheme), cornerRadius: 16, padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header: Author Info
                HStack(spacing: 12) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(post.category.color.opacity(0.2))

                        Text(post.authorInitials)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(post.category.color)
                    }
                    .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.author)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                        Text(timeAgoString(from: post.timestamp))
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Category Badge
                    HStack(spacing: 4) {
                        Image(systemName: post.category.icon)
                            .font(.system(size: 10))
                        
                        Text(post.category.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(post.category.color.opacity(0.15))
                    .foregroundColor(post.category.color)
                    .clipShape(Capsule())
                }
                .padding(16)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.system(size: 17, weight: .bold, design: .serif))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .lineLimit(2)

                    Text(post.preview)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Tags
                if !post.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(post.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.08))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 12)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Engagement Bar
                HStack(spacing: 24) {
                    Button(action: {
                        Task {
                            do {
                                withAnimation(.spring(response: 0.3)) {
                                    isLiked.toggle()
                                }
                                _ = try await communityService.togglePostLike(postId: post.id)
                            } catch {
                                // Revert on error
                                withAnimation(.spring(response: 0.3)) {
                                    isLiked.toggle()
                                }
                                print("❌ Error toggling like: \(error)")
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isLiked ? .pink : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))

                            Text("\(post.likesCount + (isLiked != post.isLiked ? (isLiked ? 1 : -1) : 0))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                        }
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))

                        Text("\(post.commentsCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            do {
                                withAnimation(.spring(response: 0.3)) {
                                    isBookmarked.toggle()
                                }
                                _ = try await communityService.togglePostBookmark(postId: post.id)
                            } catch {
                                // Revert on error
                                withAnimation(.spring(response: 0.3)) {
                                    isBookmarked.toggle()
                                }
                                print("❌ Error toggling bookmark: \(error)")
                            }
                        }
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isBookmarked ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))
                    }
                }
                .padding(16)
            }
        }
    }
}

struct EmptyStateView: View {
    @Environment(\.colorScheme) var colorScheme
    let category: PostCategory
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: searchText.isEmpty ? category.icon : "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))

            Text(searchText.isEmpty ? "No \(category.rawValue) posts yet" : "No results found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))

            Text(searchText.isEmpty ? "Be the first to share!" : "Try a different search term")
                .font(.system(size: 14))
                .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Edit Comment View

struct EditCommentView: View {
    let comment: CommentDisplayModel
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let onCommentUpdated: () -> Void
    
    @State private var content: String
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isContentFocused: Bool
    
    init(comment: CommentDisplayModel, communityService: CommunityService, onCommentUpdated: @escaping () -> Void) {
        self.comment = comment
        self.communityService = communityService
        self.onCommentUpdated = onCommentUpdated
        self._content = State(initialValue: comment.content)
    }
    
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    var canUpdate: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Comment")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    
                    TextEditor(text: $content)
                        .font(.system(size: 16))
                        .frame(minHeight: 150)
                        .focused($isContentFocused)
                        .padding(12)
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isContentFocused ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                        )
                }
                .padding(20)
                
                Spacer()
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Edit Comment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: updateComment) {
                        if isSubmitting {
                            FullScreenLoading(text: "Updating Comment")
                        } else {
                            Text("Update")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canUpdate || isSubmitting)
                    .foregroundColor(canUpdate ? AppConstants.primaryColor : .gray)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                isContentFocused = true
            }
        }
    }
    
    private func updateComment() {
        guard canUpdate else { return }
        
        mediumHaptic.impactOccurred(intensity: 0.7)
        isSubmitting = true
        
        Task {
            do {
                try await communityService.updateComment(
                    id: comment.id,
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onCommentUpdated()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to update comment. Please try again."
                    showError = true
                }
                print("❌ Error updating comment: \(error)")
            }
        }
    }
}

// MARK: - Comment View

struct CommentView: View {
    @Environment(\.colorScheme) var colorScheme
    let comment: CommentDisplayModel
    let communityService: CommunityService
    let onReply: () -> Void
    let onDelete: (() -> Void)?
    let isReply: Bool

    @State private var isLiked: Bool
    @State private var currentUserId: UUID?
    @State private var showEditComment = false
    @State private var showDeleteAlert = false
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var isCommentAuthor: Bool {
        guard let currentUserId = currentUserId else { return false }
        return comment.userId == currentUserId
    }
    
    init(comment: CommentDisplayModel, communityService: CommunityService, onReply: @escaping () -> Void, onDelete: (() -> Void)? = nil, isReply: Bool = false) {
        self.comment = comment
        self.communityService = communityService
        self.onReply = onReply
        self.onDelete = onDelete
        self.isReply = isReply
        self._isLiked = State(initialValue: comment.isLiked)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.2))

                    Text(comment.authorInitials)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 8) {
                    // Author and time
                    HStack(spacing: 8) {
                        Text(comment.author)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        
                        Text("•")
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))

                        Text(timeAgoString(from: comment.timestamp))
                            .font(.system(size: 13))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }

                    // Comment content
                    Text(comment.content)
                        .font(.system(size: 15))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                        .lineSpacing(2)

                    // Actions
                    HStack(spacing: 20) {
                        Button(action: {
                            Task {
                                do {
                                    lightHaptic.impactOccurred(intensity: 0.5)
                                    withAnimation(.spring(response: 0.3)) {
                                        isLiked.toggle()
                                    }
                                    _ = try await communityService.toggleCommentLike(commentId: comment.id)
                                } catch {
                                    withAnimation(.spring(response: 0.3)) {
                                        isLiked.toggle()
                                    }
                                    print("❌ Error toggling comment like: \(error)")
                                }
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(isLiked ? .pink : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))

                                if comment.likesCount > 0 || isLiked {
                                    Text("\(comment.likesCount + (isLiked != comment.isLiked ? (isLiked ? 1 : -1) : 0))")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                                }
                            }
                        }
                        
                        Button(action: {
                            lightHaptic.impactOccurred(intensity: 0.5)
                            onReply()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrowshape.turn.up.left")
                                    .font(.system(size: 13))

                                Text("Reply")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                        }
                    }
                    .padding(.top, 4)
                }

                Spacer()

                // Edit/Delete Menu (only for comment author)
                if isCommentAuthor {
                    Menu {
                        Button(action: { showEditComment = true }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))
                            .padding(8)
                    }
                }
            }
            .padding(16)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .padding(.leading, isReply ? 40 : 0)
            
            // Nested replies
            if !comment.replies.isEmpty {
                ForEach(comment.replies) { reply in
                    CommentView(
                        comment: reply,
                        communityService: communityService,
                        onReply: onReply,
                        onDelete: onDelete,
                        isReply: true
                    )
                }
            }
        }
        .task {
            await loadCurrentUser()
        }
        .sheet(isPresented: $showEditComment) {
            EditCommentView(comment: comment, communityService: communityService) {
                onDelete?()
            }
        }
        .alert("Delete Comment", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteComment()
                }
            }
        } message: {
            Text("Are you sure you want to delete this comment? This action cannot be undone.")
        }
    }
    
    private func loadCurrentUser() async {
        do {
            let user = try await supabase.auth.session.user
            currentUserId = user.id
        } catch {
            print("❌ Error loading current user: \(error)")
        }
    }
    
    private func deleteComment() async {
        do {
            try await communityService.deleteComment(id: comment.id)
            onDelete?()
        } catch {
            print("❌ Error deleting comment: \(error)")
        }
    }
}

struct PostDetailView: View {
    let post: PostDisplayModel
    @StateObject private var communityService = CommunityService()
    @Environment(\.colorScheme) var colorScheme
    @State private var comments: [CommentDisplayModel] = []
    @State private var commentText = ""
    @State private var replyingTo: CommentDisplayModel?
    @State private var isSubmittingComment = false
    @FocusState private var isCommentFieldFocused: Bool
    @State private var currentUserId: UUID?
    @State private var showEditPost = false
    @State private var showDeletePostAlert = false
    @Environment(\.dismiss) var dismiss
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var isPostAuthor: Bool {
        guard let currentUserId = currentUserId else { return false }
        return post.userId == currentUserId
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Post Content - WITH padding
                    postContentView
                        .padding(20)
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Comments Section - NO horizontal padding
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Comments List - flush left
                        if communityService.isLoading && comments.isEmpty {
                            FullScreenLoading(text: "Loading Comments")
                        } else if comments.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                
                                Text("No comments yet")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
                                
                                Text("Be the first to share your thoughts!")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 1) {
                                ForEach(comments) { comment in
                                    CommentView(
                                        comment: comment,
                                        communityService: communityService,
                                        onReply: { replyingTo = comment },
                                        onDelete: {
                                            Task {
                                                await loadComments()
                                            }
                                        },
                                        isReply: false
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 80) // Space for fixed comment input
                }
            }
            
            // Fixed Comment Input at Bottom
            VStack(spacing: 0) {
                Divider()
                
                commentInputView
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
            }
        }
        .background(AppConstants.backgroundColor(for: colorScheme))
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPostAuthor {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEditPost = true }) {
                            Label("Edit Post", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive, action: { showDeletePostAlert = true }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppConstants.primaryColor)
                    }
                }
            }
        }
        .task {
            await loadCurrentUser()
            await loadComments()
        }
        .refreshable {
            await loadComments()
        }
        .sheet(isPresented: $showEditPost) {
            EditPostView(post: post, communityService: communityService) {
                // Refresh after edit
                Task {
                    await loadComments()
                }
            }
        }
        .alert("Delete Post", isPresented: $showDeletePostAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deletePost()
                }
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    private var postContentView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Author Info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(post.category.color.opacity(0.2))
                    
                    Text(post.authorInitials)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(post.category.color)
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

                    Text(timeAgoString(from: post.timestamp))
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                }
                
                Spacer()
                
                // Category Badge
                HStack(spacing: 4) {
                    Image(systemName: post.category.icon)
                        .font(.system(size: 10))
                    
                    Text(post.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(post.category.color.opacity(0.15))
                .foregroundColor(post.category.color)
                .clipShape(Capsule())
            }
            
            // Title
            Text(post.title)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))

            // Full Content
            Text(post.content)
                .font(.system(size: 16))
                .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                .lineSpacing(4)
            
            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Engagement Stats
            HStack(spacing: 24) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.pink)
                    Text("\(post.likesCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text("\(post.commentsCount)")
                        .font(.system(size: 14, weight: .medium))
                }
                
                // View count hidden
                // HStack(spacing: 6) {
                //     Image(systemName: "eye.fill")
                //         .font(.system(size: 14))
                //         .foregroundColor(.gray)
                //     Text("\(post.viewsCount)")
                //         .font(.system(size: 14, weight: .medium))
                // }
            }
            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme))
            .padding(.top, 8)
        }
    }
    
    private var commentInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let replyingTo = replyingTo {
                HStack {
                    Text("Replying to @\(replyingTo.author)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))

                    Spacer()

                    Button(action: {
                        self.replyingTo = nil
                        commentText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.6))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppConstants.adaptivePrimaryColor(for: colorScheme).opacity(0.08))
                .cornerRadius(8)
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField(replyingTo == nil ? "Add a comment..." : "Write your reply...", text: $commentText, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(AppConstants.primaryTextColor(for: colorScheme))
                    .padding(12)
                    .background(AppConstants.cardBackgroundColor(for: colorScheme))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppConstants.borderColor(for: colorScheme), lineWidth: 1)
                    )
                    .focused($isCommentFieldFocused)
                    .lineLimit(1...6)

                Button(action: submitComment) {
                    if isSubmittingComment {
                        FullScreenLoading(text: "Submitting Comment")
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5) : AppConstants.adaptivePrimaryColor(for: colorScheme))
                    }
                }
                .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmittingComment)
            }
        }
    }
    
    private func loadComments() async {
        do {
            comments = try await communityService.fetchComments(postId: post.id)
        } catch {
            print("❌ Error loading comments: \(error)")
        }
    }
    
    private func submitComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        lightHaptic.impactOccurred(intensity: 0.5)
        isSubmittingComment = true
        
        Task {
            do {
                try await communityService.createComment(
                    postId: post.id,
                    content: commentText.trimmingCharacters(in: .whitespacesAndNewlines),
                    parentCommentId: replyingTo?.id
                )
                
                await MainActor.run {
                    commentText = ""
                    replyingTo = nil
                    isSubmittingComment = false
                    isCommentFieldFocused = false
                }
                
                await loadComments()
            } catch {
                await MainActor.run {
                    isSubmittingComment = false
                }
                print("❌ Error submitting comment: \(error)")
            }
        }
    }
    
    private func loadCurrentUser() async {
        do {
            let user = try await supabase.auth.session.user
            currentUserId = user.id
        } catch {
            print("❌ Error loading current user: \(error)")
        }
    }
    
    private func deletePost() async {
        do {
            try await communityService.deletePost(id: post.id)
            await MainActor.run {
                dismiss()
            }
        } catch {
            print("❌ Error deleting post: \(error)")
        }
    }
}

// MARK: - Edit Post View

struct EditPostView: View {
    let post: PostDisplayModel
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let onPostUpdated: () -> Void
    
    @State private var title: String
    @State private var content: String
    @State private var selectedCategory: PostCategory
    @State private var tagsText: String
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: PostField?
    
    init(post: PostDisplayModel, communityService: CommunityService, onPostUpdated: @escaping () -> Void) {
        self.post = post
        self.communityService = communityService
        self.onPostUpdated = onPostUpdated
        self._title = State(initialValue: post.title)
        self._content = State(initialValue: post.content)
        self._selectedCategory = State(initialValue: post.category)
        self._tagsText = State(initialValue: post.tags.joined(separator: ", "))
    }
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    enum PostField: Hashable {
        case title
        case content
        case tags
    }
    
    var canUpdate: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var parsedTags: [String] {
        tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        TextField("What's on your mind?", text: $title)
                            .font(.system(size: 18, weight: .semibold))
                            .focused($focusedField, equals: .title)
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .title ? AppConstants.primaryColor : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach([PostCategory.discussion, PostCategory.support, PostCategory.question, PostCategory.success]) { category in
                                    CategoryPill(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                            lightHaptic.impactOccurred(intensity: 0.5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Content Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Content")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .frame(minHeight: 200)
                            .focused($focusedField, equals: .content)
                            .padding(12)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .content ? AppConstants.primaryColor : Color.black.opacity(0.1), lineWidth: 1)
                            )
                    }
                    
                    // Tags Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags (optional)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black.opacity(0.7))
                        
                        TextField("Separate tags with commas", text: $tagsText)
                            .font(.system(size: 15))
                            .focused($focusedField, equals: .tags)
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .tags ? AppConstants.primaryColor : Color.black.opacity(0.1), lineWidth: 1)
                            )
                        
                        if !parsedTags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(parsedTags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(AppConstants.primaryColor)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(AppConstants.primaryColor.opacity(0.08))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Edit Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppConstants.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: updatePost) {
                        if isSubmitting {
                            FullScreenLoading(text: "Updating Post")
                        } else {
                            Text("Update")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(!canUpdate || isSubmitting)
                    .foregroundColor(canUpdate ? AppConstants.primaryColor : .gray)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updatePost() {
        guard canUpdate else { return }
        
        mediumHaptic.impactOccurred(intensity: 0.7)
        isSubmitting = true
        
        Task {
            do {
                try await communityService.updatePost(
                    id: post.id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: selectedCategory,
                    tags: parsedTags
                )
                
                await MainActor.run {
                    isSubmitting = false
                    dismiss()
                    onPostUpdated()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to update post. Please try again."
                    showError = true
                }
                print("❌ Error updating post: \(error)")
            }
        }
    }
}

// MARK: - Create Post View

struct CreatePostView: View {
    let topic: CommunityTopic?
    @ObservedObject var communityService: CommunityService
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    let onPostCreated: () -> Void
    
    @State private var selectedTopic: CommunityTopic?
    @State private var topics: [CommunityTopic] = []
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: PostCategory = .discussion
    @State private var tagsText: String = ""
    @State private var isSubmitting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: PostField?
    
    init(topic: CommunityTopic? = nil, communityService: CommunityService, onPostCreated: @escaping () -> Void) {
        self.topic = topic
        self.communityService = communityService
        self.onPostCreated = onPostCreated
        self._selectedTopic = State(initialValue: topic)
    }
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    enum PostField: Hashable {
        case title
        case content
        case tags
    }
    
    var canPost: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedTopic != nil
    }
    
    var parsedTags: [String] {
        tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Topic display (if topic is provided)
                    if let selectedTopic = selectedTopic {
                        Card(backgroundColor: selectedTopic.swiftUIColor.opacity(0.1), cornerRadius: 12, padding: 0) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(selectedTopic.swiftUIColor.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: selectedTopic.icon)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(selectedTopic.swiftUIColor)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Posting to")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.black.opacity(0.5))
                                    
                                    Text(selectedTopic.name)
                                        .font(.system(size: 16, weight: .bold, design: .serif))
                                        .foregroundColor(selectedTopic.swiftUIColor)
                                }
                                
                                Spacer()
                            }
                            .padding(12)
                        }
                    }
                    
                    // Title field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        TextField("What's on your mind?", text: $title)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppConstants.primaryColor)
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .title)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .content
                            }
                    }
                    
                    // Content field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Share your story, ask a question, or start a discussion...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $content)
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.primaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minHeight: 200)
                                .focused($focusedField, equals: .content)
                                .scrollContentBackground(.hidden)
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(12)
                    }
                    
                    // Category selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PostCategory.allCases.filter { $0 != .all }) { category in
                                    Button(action: {
                                        lightHaptic.impactOccurred(intensity: 0.5)
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 14))
                                            
                                            Text(category.rawValue)
                                                .font(.system(size: 14, weight: .medium))
                                                .fontDesign(.serif)
                                        }
                                        .foregroundColor(selectedCategory == category ? .white : category.color)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedCategory == category ?
                                            category.color : category.color.opacity(0.15)
                                        )
                                        .cornerRadius(20)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Topic selector (if not provided)
                    if topic == nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Topic")
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryColor)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(topics) { topic in
                                        Button(action: {
                                            lightHaptic.impactOccurred(intensity: 0.5)
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedTopic = topic
                                            }
                                        }) {
                                            HStack(spacing: 8) {
                                                Image(systemName: topic.icon)
                                                    .font(.system(size: 14))
                                                
                                                Text(topic.name)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .fontDesign(.serif)
                                            }
                                            .foregroundColor(selectedTopic?.id == topic.id ? .white : topic.swiftUIColor)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedTopic?.id == topic.id ?
                                                topic.swiftUIColor : topic.swiftUIColor.opacity(0.15)
                                            )
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tags field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags (optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        TextField("e.g., anxiety, progress, therapy", text: $tagsText)
                            .font(.system(size: 16))
                            .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                            .padding(16)
                            .background(AppConstants.cardBackgroundColor(for: colorScheme))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .tags)
                            .submitLabel(.done)

                        Text("Separate tags with commas")
                            .font(.system(size: 12))
                            .foregroundColor(AppConstants.secondaryTextColor(for: colorScheme).opacity(0.8))
                    }
                }
                .padding(20)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        lightHaptic.impactOccurred(intensity: 0.5)
                        dismiss()
                    }
                    .foregroundColor(AppConstants.adaptivePrimaryColor(for: colorScheme))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: submitPost) {
                        if isSubmitting {
                            FullScreenLoading(text: "Submitting Post")
                        } else {
                            Text("Post")
                                .font(.system(size: 17, weight: .semibold))
                                .fontDesign(.serif)
                        }
                    }
                    .foregroundColor(canPost && !isSubmitting ? AppConstants.adaptivePrimaryColor(for: colorScheme) : AppConstants.secondaryTextColor(for: colorScheme).opacity(0.5))
                    .disabled(!canPost || isSubmitting)
                }
            }
            .task {
                if topic == nil {
                    do {
                        topics = try await communityService.fetchTopics()
                    } catch {
                        print("❌ Error loading topics: \(error)")
                    }
                }
            }
            .onAppear {
                lightHaptic.prepare()
                mediumHaptic.prepare()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .title
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func submitPost() {
        guard canPost, let selectedTopic = selectedTopic else { return }
        
        isSubmitting = true
        mediumHaptic.impactOccurred(intensity: 0.7)
        
        Task {
            do {
                _ = try await communityService.createPost(
                    topicId: selectedTopic.id,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    content: content.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: selectedCategory,
                    tags: parsedTags
                )
                
                await MainActor.run {
                    dismiss()
                    onPostCreated()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Post Entry View (Legacy)

enum PostEntryMode {
    case newPost
    case reply(to: PostDisplayModel)
}

struct PostEntryView: View {
    @Binding var isPresented: Bool
    let mode: PostEntryMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var selectedCategory: PostCategory = .discussion
    @State private var tags: String = ""
    @FocusState private var focusedField: PostField?
    
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    
    enum PostField: Hashable {
        case title
        case content
        case tags
    }
    
    var isReply: Bool {
        if case .reply = mode { return true }
        return false
    }
    
    var canPost: Bool {
        if isReply {
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Reply context (if replying)
                    if case .reply(let post) = mode {
                        replyContextView(post: post)
                    }
                    
                    // Title field (only for new posts)
                    if !isReply {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryColor)
                            
                            TextField("What's on your mind?", text: $title)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppConstants.primaryColor)
                                .padding(16)
                                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                                .cornerRadius(12)
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .content
                                }
                        }
                    }
                    
                    // Content field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isReply ? "Your reply" : "Details")
                            .font(.system(size: 16, weight: .semibold))
                            .fontDesign(.serif)
                            .foregroundColor(AppConstants.primaryColor)
                        
                        ZStack(alignment: .topLeading) {
                            if content.isEmpty {
                                Text(isReply ? "Share your thoughts..." : "Share your story, ask a question, or start a discussion...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray.opacity(0.6))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $content)
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.primaryColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(minHeight: isReply ? 120 : 200)
                                .focused($focusedField, equals: .content)
                                .scrollContentBackground(.hidden)
                        }
                        .background(AppConstants.cardBackgroundColor(for: colorScheme))
                        .cornerRadius(12)
                    }
                    
                    // Category selector (only for new posts)
                    if !isReply {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryColor)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(PostCategory.allCases.filter { $0 != .all }) { category in
                                        Button(action: {
                                            lightHaptic.impactOccurred(intensity: 0.5)
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedCategory = category
                                            }
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: category.icon)
                                                    .font(.system(size: 14))
                                                
                                                Text(category.rawValue)
                                                    .font(.system(size: 14, weight: .medium))
                                                    .fontDesign(.serif)
                                            }
                                            .foregroundColor(selectedCategory == category ? .white : category.color)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                selectedCategory == category ? 
                                                category.color : category.color.opacity(0.15)
                                            )
                                            .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Tags field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags (optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .fontDesign(.serif)
                                .foregroundColor(AppConstants.primaryColor)
                            
                            TextField("e.g., anxiety, progress, therapy", text: $tags)
                                .font(.system(size: 16))
                                .foregroundColor(AppConstants.primaryColor)
                                .padding(16)
                                .background(AppConstants.cardBackgroundColor(for: colorScheme))
                                .cornerRadius(12)
                                .focused($focusedField, equals: .tags)
                                .submitLabel(.done)
                            
                            Text("Separate tags with commas")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(20)
            }
            .background(AppConstants.backgroundColor(for: colorScheme))
            .navigationTitle(isReply ? "Write a Reply" : "Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        lightHaptic.impactOccurred(intensity: 0.5)
                        isPresented = false
                    }
                    .foregroundColor(AppConstants.primaryColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isReply ? "Reply" : "Post") {
                        mediumHaptic.impactOccurred(intensity: 0.7)
                        // Handle post/reply submission
                        isPresented = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .fontDesign(.serif)
                    .foregroundColor(canPost ? AppConstants.primaryColor : .gray)
                    .disabled(!canPost)
                }
            }
            .onAppear {
                lightHaptic.prepare()
                mediumHaptic.prepare()
                
                // Auto-focus appropriate field
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if isReply {
                        focusedField = .content
                    } else {
                        focusedField = .title
                    }
                }
            }
        }
    }
    
    // MARK: - Reply Context View
    private func replyContextView(post: PostDisplayModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Replying to")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
            
            HStack(alignment: .top, spacing: 12) {
                // Author initials
                Circle()
                    .fill(AppConstants.primaryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.authorInitials)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppConstants.primaryColor)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.author)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppConstants.primaryColor)
                    
                    Text(post.title)
                        .font(.system(size: 13))
                        .foregroundColor(AppConstants.primaryColor.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(12)
            .background(AppConstants.cardBackgroundColor(for: colorScheme))
            .cornerRadius(12)
        }
    }
}

// MARK: - Helper Functions

func timeAgoString(from date: Date) -> String {
    let seconds = Int(Date().timeIntervalSince(date))
    
    if seconds < 60 {
        return "Just now"
    } else if seconds < 3600 {
        let minutes = seconds / 60
        return "\(minutes)m ago"
    } else if seconds < 86400 {
        let hours = seconds / 3600
        return "\(hours)h ago"
    } else if seconds < 604800 {
        let days = seconds / 86400
        return "\(days)d ago"
    } else {
        let weeks = seconds / 604800
        return "\(weeks)w ago"
    }
}

// MARK: - Preview

#Preview {
    CommunityOverview()
}
