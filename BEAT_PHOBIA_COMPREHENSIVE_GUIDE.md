# Still Step - Comprehensive App Documentation

## 🎯 **Application Overview**

**Still Step** is a comprehensive iOS mental health application designed to help users manage anxiety disorders, particularly agoraphobia and panic attacks. The app provides evidence-based coping tools, location tracking for exposure therapy, journaling capabilities, and a supportive community forum.

### **Core Mission**
"Tools to help you manage anxiety and panic" - Empowering users with practical, accessible mental health tools and community support.

---

## 🏗️ **Architecture & Technology Stack**

### **Frontend Framework**
- **SwiftUI** - Modern, declarative UI framework
- **Swift 5.9+** - Latest Swift language features
- **iOS 17+** - Target platform
- **MVVM Pattern** - Clean architecture with EnvironmentObjects

### **State Management**
```swift
// Core Environment Objects (Singletons)
@EnvironmentObject var authManager: AuthManager           // User authentication & profile
@EnvironmentObject var subscriptionManager: SubscriptionManager // Pro subscription handling
@EnvironmentObject var journalSyncService: JournalSyncService   // Cloud sync for journals
@EnvironmentObject var themeManager: ThemeManager         // Light/Dark mode management
```

### **Local Database**
- **Realm Database** - Fast, offline-first storage
- **SwiftData** - Modern data persistence (journals)
- **File System** - Image storage and caching

### **Cloud Services**
- **Supabase** - PostgreSQL database, authentication, real-time subscriptions
- **CloudKit** - iCloud integration (backup/sync)
- **StoreKit** - In-app purchases and subscriptions

### **External APIs**
- **RevenueCat** - Subscription management
- **MapKit** - Location services and mapping
- **Core Location** - GPS tracking for journeys

---

## 🎨 **Design System & Theming**

### **Adaptive Color Scheme**

The app features a comprehensive adaptive color system that responds to system light/dark mode preferences.

#### **Primary Colors**
```swift
// Light Mode (Default)
backgroundColor: rgb(252, 245, 238)     // Warm cream
primaryColor: rgb(51, 77, 128)         // Deep blue
cardBackground: rgb(255, 255, 255)     // Pure white
primaryText: rgb(0, 0, 0)             // Black
secondaryText: rgb(0, 0, 0, 0.6)     // 60% black

// Dark Mode
backgroundColor: rgb(18, 18, 20)       // Deep dark gray
primaryColor: rgb(100, 130, 200)      // Lighter blue for contrast
cardBackground: rgb(28, 28, 30)       // Dark gray cards
primaryText: rgb(255, 255, 255, 0.95) // Near-white
secondaryText: rgb(255, 255, 255, 0.6) // 60% white
```

#### **Color Functions**
```swift
AppConstants.backgroundColor(for: colorScheme)        // Main app background
AppConstants.cardBackgroundColor(for: colorScheme)   // Card backgrounds
AppConstants.primaryTextColor(for: colorScheme)      // Main text
AppConstants.secondaryTextColor(for: colorScheme)    // Secondary/muted text
AppConstants.adaptivePrimaryColor(for: colorScheme)  // Accent color (adaptive)
AppConstants.shadowColor(for: colorScheme)           // Drop shadows
AppConstants.dividerColor(for: colorScheme)          // Separators
```

### **Typography**
- **Primary Font**: Source Code Pro (monospace, technical feel)
- **Design Font**: Serif system font (elegant, calming)
- **Responsive sizing** with `minimumScaleFactor` for accessibility

### **Component Library**
- **Card**: Reusable container with adaptive background and shadow
- **ToolCard**: Specialized card for anxiety tools
- **QuickStatCard**: Statistics display cards
- **EmergencyToolCard**: High-contrast cards for crisis situations

---

## 📱 **User Interface Structure**

### **Main Navigation (Tab Bar)**
```
1. 🧠 Journeys     - Core anxiety management tools
2. 💬 Community    - Social support and forums
3. 📖 Journal      - Mood tracking and reflection
4. 👤 Profile      - User settings and preferences
```

### **Journeys Tab (Main Feature)**
#### **Overview Screen**
- **Personalized Greeting**: "Hi [Name]" with adaptive text
- **Daily Quote**: Rotating inspirational messages
- **Quick Stats**: Journey count and wellness score
- **Current Anxiety Level**: Interactive slider (1-10 scale)
- **Recommended Tools**: AI-curated based on anxiety level
- **All Tools by Category**: Organized tool library

#### **Tool Categories**
1. **🫁 Breathing** (Blue) - Box breathing, 4-7-8, deep breathing
2. **🌱 Grounding** (Green) - 5-4-3-2-1 technique, sensory awareness
3. **🧘 Relaxation** (Purple) - Progressive muscle relaxation, body scan
4. **🎯 Focus** (Orange) - Object hunt, concentration games
5. **🎮 Distraction** (Pink) - Color hunt, counting games
6. **💝 Affirmation** (Teal) - Positive self-talk, encouragement

### **Community Tab**
#### **Features**
- **Forum**: Browse and create posts by category
- **Your Posts**: View personal contributions
- **Friends**: Connect with other users
- **Direct Messages**: Private 1-on-1 conversations
- **Trending**: Popular topics and discussions
- **Guidelines**: Community rules and support

#### **Forum Categories**
- General Discussion
- Success Stories
- Coping Strategies
- Crisis Support
- Questions & Advice

### **Journal Tab**
- **Mood Tracking**: Visual mood indicators
- **Entry Creation**: Rich text with image support
- **Cloud Sync**: Backup to Supabase (Pro feature)
- **Search & Filter**: Find entries by mood/date
- **Insights**: Mood patterns and trends (Pro feature)

### **Profile Tab**
- **User Settings**: Name, preferences, notifications
- **Subscription Management**: Pro upgrade and billing
- **Data Export**: Download personal data
- **Account Management**: Sign out, delete account

---

## 🛠️ **Core Features & Tools**

### **1. Location-Based Journey Tracking**
- **GPS Monitoring**: Track exposure therapy progress
- **Checkpoint System**: Mark safe/unsafe locations
- **Distance Calculation**: Measure progress over time
- **Map Visualization**: Interactive journey maps
- **Pro Feature**: Unlimited history (vs 3 journeys for free)

### **2. Panic Scale Tracker**
- **Real-time Monitoring**: Track panic episodes
- **Symptom Recording**: Physical and mental symptoms
- **Duration Tracking**: Episode length measurement
- **Trigger Identification**: Pattern recognition
- **Analytics Dashboard**: Trends and insights (Pro feature)

### **3. Breathing Exercises**
- **Box Breathing**: 4-4-4-4 technique with visual guide
- **4-7-8 Breathing**: Calming breath pattern
- **Deep Breathing**: Guided respiratory exercises
- **Haptic Feedback**: Gentle vibrations for rhythm

### **4. Grounding Techniques**
- **5-4-3-2-1**: Classic sensory grounding method
- **Object Hunt**: AI-powered object detection game
- **Color Hunt**: Find objects by color
- **Counting Games**: Numerical distraction exercises

### **5. Relaxation Methods**
- **Progressive Muscle Relaxation**: Systematic tension release
- **Body Scan Meditation**: Mindfulness body awareness
- **Safe Space Visualization**: Mental imagery techniques
- **Positive Affirmations**: Curated encouraging statements

### **6. Community Features**
- **Anonymous Posting**: Privacy-focused discussions
- **Like & Comment System**: Engagement features
- **Bookmarking**: Save important posts
- **Direct Messaging**: Private peer support
- **Moderation Tools**: Community guidelines enforcement

---

## 💰 **Subscription System (Freemium Model)**

### **Free Tier**
✅ **All breathing exercises**
✅ **5-4-3-2-1 Grounding technique**
✅ **Box breathing & 4-7-8 breathing**
✅ **Progressive muscle relaxation**
✅ **Safe space visualization**
✅ **Body scan meditation**
✅ **Positive affirmations**
✅ **Color hunt & counting games**
✅ **Focus techniques & object hunt**
✅ **Panic scale tracking**
✅ **Local journal entries**
✅ **Community forum access**
📍 **Location tracking (last 3 journeys only)**

### **Pro Tier ($X/month or $X/year)**
✨ **Everything in Free**
📍 **Unlimited location tracking history**
☁️ **Cloud journal backup & sync**
📊 **Detailed metrics & analytics**
📈 **Journal entry insights over time**
📉 **Panic scale trend analysis**
🗺️ **Location pattern visualization**
🔐 **Secure cloud storage**

### **Subscription Management**
- **StoreKit Integration**: Native iOS purchase flow
- **RevenueCat Backend**: Subscription state management
- **Grace Periods**: Account for payment issues
- **Auto-renewal**: Seamless subscription management
- **Family Sharing**: Share Pro benefits

---

## 📊 **Data Models & Storage**

### **Local Storage (Realm)**
```swift
// Journey Tracking
JourneyRealm {
    id: UUID
    startTime: Date
    endTime: Date?
    distance: Double (meters)
    duration: Int (seconds)
    checkpoints: List<Checkpoint>
    feeling: String
    notes: String
}

// Panic Episodes
PanicEpisode {
    id: UUID
    timestamp: Date
    initialIntensity: Int (0-10)
    peakIntensity: Int (0-10)
    finalIntensity: Int (0-10)
    duration: TimeInterval
    symptoms: [physical, cognitive]
    location: String
    trigger: String
    copingStrategies: [String]
}
```

### **Cloud Storage (Supabase)**
```sql
-- Journal entries with sync
journal_entries {
    id: UUID
    user_id: UUID
    mood: String
    moodStrength: Int
    body: Text
    images: JSON
    created_at: Timestamp
    updated_at: Timestamp
}

-- Community forum
community_posts {
    id: UUID
    user_id: UUID
    title: String
    content: Text
    category: String
    tags: JSON
    likes_count: Int
    comments_count: Int
    created_at: Timestamp
    updated_at: Timestamp
}
```

### **Sync Architecture**
- **Offline-First**: Full functionality without internet
- **Conflict Resolution**: Merge strategies for data conflicts
- **Incremental Sync**: Only sync changes since last update
- **Background Sync**: Automatic sync when connection available

---

## 🔐 **Security & Privacy**

### **Data Protection**
- **End-to-End Encryption**: Sensitive data encrypted in transit
- **Local Storage Encryption**: Realm database encrypted
- **Biometric Authentication**: Optional Face ID/Touch ID
- **Privacy by Default**: No data collection without consent

### **User Consent**
- **GDPR Compliant**: European privacy regulation compliance
- **Data Export**: Users can download all their data
- **Account Deletion**: Complete data removal option
- **Transparent Policies**: Clear privacy and terms of service

### **Community Safety**
- **Content Moderation**: Automated and manual review
- **Reporting System**: Flag inappropriate content
- **Block/Mute Users**: Control social interactions
- **Crisis Detection**: Emergency contact integration

---

## 🚀 **Technical Implementation Details**

### **Navigation Architecture**
```swift
// Main app flow
ContentView → AuthManager.checkState()
├── SignedOut → SignInView
├── SignedIn → ProfileCheck
    ├── NoProfile → InitialProfileView
    └── HasProfile → HomeView (TabView)
        ├── Journeys → JourneyAgorahobiaView
        ├── Community → CommunityOverview
        ├── Journal → JournalHome
        └── Profile → ProfileView
```

### **State Management**
- **EnvironmentObjects**: Global app state
- **@AppStorage**: User preferences and settings
- **@State**: Local component state
- **@ObservedResults**: Real-time Realm queries

### **Performance Optimizations**
- **Lazy Loading**: Tools and content loaded on demand
- **Image Caching**: Efficient image storage and retrieval
- **Background Tasks**: Non-blocking operations
- **Memory Management**: Proper cleanup and disposal

### **Accessibility Features**
- **Dynamic Type**: Responsive text sizing
- **VoiceOver Support**: Screen reader compatibility
- **High Contrast**: Enhanced visibility options
- **Reduced Motion**: Respect user motion preferences

---

## 📈 **Analytics & Insights**

### **Pro User Features**
- **Journey Analytics**: Distance, duration, frequency trends
- **Mood Patterns**: Journal entry sentiment analysis
- **Panic Episode Insights**: Trigger identification
- **Progress Tracking**: Visual improvement charts
- **Location Analysis**: Safe/unsafe area mapping

### **Data Visualization**
- **Charts**: Line graphs, bar charts, heat maps
- **Interactive Maps**: Journey path visualization
- **Progress Indicators**: Achievement tracking
- **Trend Analysis**: Long-term pattern recognition

---

## 🌐 **Community & Social Features**

### **Forum System**
- **Categories**: Organized discussion topics
- **Rich Text**: Formatted posts with markdown
- **Media Support**: Image and video sharing
- **Engagement**: Likes, comments, bookmarks
- **Search**: Find relevant discussions

### **Direct Messaging**
- **Real-time Chat**: Instant messaging between users
- **Message History**: Persistent conversation storage
- **Read Receipts**: Delivery confirmation
- **Media Sharing**: Photos and files

### **Social Connections**
- **Friend Requests**: Connect with other users
- **Privacy Controls**: Block/mute functionality
- **Activity Feeds**: See friend updates
- **Support Network**: Build personal support system

---

## 🔧 **Development & Deployment**

### **Build Configuration**
- **Xcode 15+**: Latest development environment
- **iOS 17+**: Target platform
- **Swift 5.9+**: Language version
- **Package Dependencies**: Supabase, Realm, RevenueCat

### **Testing Strategy**
- **Unit Tests**: Core functionality coverage
- **UI Tests**: User interface validation
- **Integration Tests**: Service interaction testing
- **Beta Testing**: TestFlight distribution

### **Deployment Pipeline**
- **App Store Connect**: Apple App Store distribution
- **Continuous Integration**: Automated build and test
- **Crash Reporting**: Real user monitoring
- **Performance Monitoring**: App Store metrics

---

## 🎯 **User Experience Design**

### **Onboarding Flow**
1. **Welcome Screen**: App introduction
2. **Authentication**: Sign up/sign in
3. **Profile Setup**: Personal information
4. **Anxiety Assessment**: Initial anxiety level
5. **Tool Introduction**: Guided tool selection
6. **Community Introduction**: Forum overview

### **Adaptive Interface**
- **Contextual Recommendations**: Tools based on current anxiety level
- **Progressive Disclosure**: Advanced features revealed gradually
- **Emergency Access**: Always-available crisis tools
- **Offline Support**: Full functionality without internet

### **Gamification Elements**
- **Achievement System**: Milestone celebrations
- **Progress Tracking**: Visual improvement indicators
- **Streak Counters**: Consistency motivation
- **Level Progression**: Unlock advanced features

---

## 📚 **Content & Educational Resources**

### **Built-in Tools**
- **12 Anxiety Management Techniques**: Evidence-based methods
- **Educational Content**: Explanations and instructions
- **Progress Tracking**: Personal improvement metrics
- **Safety Guidelines**: When to seek professional help

### **Professional Integration**
- **Therapist-Friendly**: Data export for healthcare providers
- **Crisis Resources**: Emergency contact information
- **Research-Backed**: Evidence-based techniques
- **Safety First**: Professional help recommendations

This comprehensive documentation provides complete context for understanding, developing, and maintaining the Still Step iOS application. The app represents a sophisticated mental health platform combining modern iOS development practices with evidence-based anxiety management techniques.
