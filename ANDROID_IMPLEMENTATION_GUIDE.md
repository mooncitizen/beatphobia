# Still Step - Android Implementation Guide

**App Name:** Still Step (formerly beatphobia)  
**Bundle ID:** org.stillstep.stillstepapp  
**Description:** Mental wellness companion for managing anxiety and panic attacks

---

## Table of Contents
1. [App Overview](#app-overview)
2. [Design System](#design-system)
3. [Architecture & Tech Stack](#architecture--tech-stack)
4. [Data Models](#data-models)
5. [Features & Screens](#features--screens)
6. [Tools & Coping Mechanisms](#tools--coping-mechanisms)
7. [Subscription System](#subscription-system)
8. [Backend Services](#backend-services)
9. [User Flows](#user-flows)
10. [Technical Implementation Notes](#technical-implementation-notes)

---

## 1. App Overview

### Core Purpose
Still Step is a comprehensive mental wellness app designed to help users manage anxiety and panic attacks through:
- Real-time panic tracking with journeys
- Breathing exercises and coping tools
- Journal entries with mood tracking
- Location tracking to identify patterns
- Community features for support
- Cloud sync for Pro users

### Target Audience
Individuals experiencing:
- Agoraphobia
- General anxiety disorders
- Panic attacks
- Need for mental wellness tracking

---

## 2. Design System

### 2.1 Color Palette

#### Core Colors
```kotlin
// Light Mode
val lightBackgroundColor = Color(0xFCF5EE) // rgb(252, 245, 238) - Warm cream
val lightCardBackground = Color.White

// Dark Mode
val darkBackgroundColor = Color(0x121214) // rgb(18, 18, 20) - Deep black
val darkCardBackground = Color(0x1C1C1E) // rgb(28, 28, 30) - Dark gray

// Primary Colors
val primaryColor = Color(0x334D80) // rgb(51, 77, 128) - Deep blue
val cardColor = Color(0x264069) // rgb(38, 64, 105) - Medium blue

// Text Colors (Dark mode)
val contentTextColor = Color.White.copy(alpha = 0.85f)
val secondaryTextColor = Color.White.copy(alpha = 0.6f)

// Text Colors (Light mode)
val primaryTextColorLight = Color.Black
val secondaryTextColorLight = Color.Black.copy(alpha = 0.6f)
```

#### Accent & Gradient Colors
```kotlin
// Gradients used throughout the app
val blueGradient = listOf(Color.Blue, Color.Cyan)
val purpleGradient = listOf(Color.Purple, Color(0xFFFF1493)) // Purple to Pink
val greenGradient = listOf(Color.Green, Color(0xFF00CED1)) // Green to Mint
val orangeGradient = listOf(Color.Orange, Color.Red)
val yellowGradient = listOf(Color.Yellow, Color.Orange) // Crown icon
```

#### Mood Colors
```kotlin
enum class Mood(val color: Color, val icon: String) {
    HAPPY(Color.Green, "sentiment_satisfied"),
    ANGRY(Color.Red, "local_fire_department"),
    EXCITED(Color.Orange, "stars"),
    STRESSED(Color(0xFF9C27B0), "psychology"), // Purple
    SAD(Color.Blue, "cloud"),
    NONE(Color.Gray, "")
}
```

#### Panic Scale Colors
```kotlin
// Gradual color gradient from green (1) to red (10)
fun panicScaleColor(value: Int): Color {
    val clamped = value.coerceIn(1, 10)
    val normalized = (clamped - 1) / 9.0f
    val hue = 120f - (normalized * 120f) // 120° (green) to 0° (red)
    return Color.hsv(hue, 1f, 1f)
}
```

### 2.2 Typography

#### Font Family
- **Primary Font:** Source Code Pro (Variable Weight)
- **Alternative:** Use system fonts if custom font not available
  - Android: Roboto / Monospace
  - Rounded design for headers

#### Text Styles
```kotlin
// Headers
val headerLarge = TextStyle(
    fontSize = 34.sp,
    fontWeight = FontWeight.Bold,
    fontFamily = FontFamily.Rounded
)

val headerMedium = TextStyle(
    fontSize = 24.sp,
    fontWeight = FontWeight.Bold,
    fontFamily = FontFamily.Rounded
)

val title = TextStyle(
    fontSize = 20.sp,
    fontWeight = FontWeight.Bold,
    fontFamily = FontFamily.Rounded
)

// Body
val bodyLarge = TextStyle(
    fontSize = 17.sp,
    fontWeight = FontWeight.Normal
)

val bodyMedium = TextStyle(
    fontSize = 15.sp,
    fontWeight = FontWeight.Normal
)

val bodySmall = TextStyle(
    fontSize = 13.sp,
    fontWeight = FontWeight.Normal
)

val caption = TextStyle(
    fontSize = 11.sp,
    fontWeight = FontWeight.Normal
)
```

### 2.3 UI Components

#### Cards
```kotlin
// Standard card styling
modifier = Modifier
    .fillMaxWidth()
    .background(cardBackgroundColor, RoundedCornerShape(16.dp))
    .shadow(
        elevation = 8.dp,
        shape = RoundedCornerShape(16.dp),
        ambientColor = shadowColor.copy(alpha = 0.15f)
    )
    .padding(16.dp)
```

#### Buttons

**Primary Button:**
```kotlin
Button(
    modifier = Modifier
        .fillMaxWidth()
        .height(56.dp),
    colors = ButtonDefaults.buttonColors(
        containerColor = Brush.linearGradient(
            colors = listOf(Color.Blue, Color.Purple)
        )
    ),
    shape = RoundedCornerShape(16.dp)
) {
    Text("Button Text", fontSize = 18.sp, fontWeight = FontWeight.Bold)
}
```

**Pill Button (Capsule):**
```kotlin
// Success (green), Destructive (red), Info (blue), Warning (orange), Neutral
Button(
    shape = RoundedCornerShape(50),
    border = BorderStroke(2.dp, Color.Black),
    colors = ButtonDefaults.buttonColors(containerColor = buttonColor)
) {
    Text(text, fontSize = 14.sp)
}
```

#### Tab Bar
```kotlin
// Bottom navigation with glass morphism effect
BottomAppBar(
    containerColor = Color.Transparent, // Glass effect
    modifier = Modifier
        .padding(horizontal = 20.dp, vertical = 16.dp)
        .clip(RoundedCornerShape(24.dp))
        .blur(radius = 10.dp) // Blur effect
        .shadow(elevation = 10.dp)
) {
    NavigationBar {
        // 4 tabs: Journeys, Community, Journal, Profile
        // Icons scale 1.0 → 1.1 when selected
        // Active color: Primary blue, Inactive: Secondary gray
    }
}
```

#### Icons with Gradient Background
```kotlin
// Used throughout app for feature cards
Box(
    modifier = Modifier
        .size(60.dp)
        .background(
            Brush.linearGradient(gradient.map { it.copy(alpha = 0.15f) }),
            RoundedCornerShape(16.dp)
        ),
    contentAlignment = Alignment.Center
) {
    Icon(
        imageVector = icon,
        tint = Brush.linearGradient(gradient),
        modifier = Modifier.size(28.dp)
    )
}
```

---

## 3. Architecture & Tech Stack

### iOS Stack (Reference)
- **UI:** SwiftUI
- **Database:** Realm Swift (local storage)
- **Backend:** Supabase (PostgreSQL)
- **Auth:** Supabase Auth
- **Payments:** StoreKit 2
- **Location:** CoreLocation
- **Sound:** AVFoundation

### Recommended Android Stack

#### Core Framework
- **Language:** Kotlin
- **UI:** Jetpack Compose
- **Architecture:** MVVM with Clean Architecture
- **DI:** Hilt/Koin

#### Data & Storage
- **Local Database:** Room (SQLite) or Realm Kotlin
- **Preferences:** DataStore (replacement for SharedPreferences)
- **File Storage:** Local filesystem for images

#### Backend Services
- **Backend:** Supabase Android SDK
  ```kotlin
  implementation("io.github.jan-tennert.supabase:postgrest-kt:VERSION")
  implementation("io.github.jan-tennert.supabase:gotrue-kt:VERSION")
  implementation("io.github.jan-tennert.supabase:realtime-kt:VERSION")
  ```
- **Auth:** Supabase Auth
- **Database:** PostgreSQL via Supabase

#### Payment & Monetization
- **In-App Billing:** Google Play Billing Library v6
  ```kotlin
  implementation("com.android.billingclient:billing-ktx:6.1.0")
  ```
- **SKUs:**
  - `pro_monthly` - Pro Monthly Subscription
  - `pro_yearly` - Pro Yearly Subscription

#### Location Services
- **Location:** Google Play Services Location API
  ```kotlin
  implementation("com.google.android.gms:play-services-location:21.0.1")
  ```
- **Permissions:** ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION

#### Media & Audio
- **Audio Playback:** ExoPlayer or MediaPlayer
- **Haptics:** Vibrator API

#### Other Libraries
- **Image Loading:** Coil
- **Date/Time:** kotlinx-datetime
- **JSON:** Kotlinx Serialization
- **Network:** Ktor Client (built into Supabase SDK)

---

## 4. Data Models

### 4.1 Local Database Models (Room/Realm)

#### JournalEntry
```kotlin
@Entity(tableName = "journal_entries")
data class JournalEntry(
    @PrimaryKey val id: UUID = UUID.randomUUID(),
    val mood: Mood,
    val text: String,
    val date: Date,
    
    // Sync metadata
    val isSynced: Boolean = false,
    val needsSync: Boolean = false,
    val isDeleted: Boolean = false,
    val lastSyncedAt: Date? = null,
    val updatedAt: Date = Date()
)

enum class Mood {
    HAPPY, ANGRY, EXCITED, STRESSED, SAD, NONE
}
```

#### Journey
```kotlin
@Entity(tableName = "journeys")
data class Journey(
    @PrimaryKey val id: UUID = UUID.randomUUID(),
    val type: JourneyType,
    val startDate: Date,
    val endDate: Date? = null,
    val isCompleted: Boolean = false,
    val isCurrent: Boolean = true,
    
    // Journey tracking data
    val initialPanicScale: Int? = null,
    val finalPanicScale: Int? = null,
    val toolsUsed: List<String> = emptyList(),
    val notesText: String = "",
    
    // Location data (if Pro user)
    val locationData: List<LocationPoint> = emptyList()
)

enum class JourneyType {
    AGORAPHOBIA,    // "Agoraphobia"
    GENERAL_ANXIETY, // "General Anxiety"
    NONE            // "No Journey"
}
```

#### LocationPoint
```kotlin
@Entity(tableName = "location_points")
data class LocationPoint(
    @PrimaryKey val id: UUID = UUID.randomUUID(),
    val journeyId: UUID,
    val latitude: Double,
    val longitude: Double,
    val timestamp: Date,
    val panicScale: Int? = null
)
```

### 4.2 User Profile (Supabase)

#### Profile
```kotlin
@Serializable
data class Profile(
    val id: UUID,
    val name: String? = null,
    val username: String? = null,
    val biography: String? = null,
    val role: String? = null,
    @SerialName("created_at") val createdAt: Date,
    @SerialName("updated_at") val updatedAt: Date
)
```

### 4.3 Community Models (Supabase)

#### Topic
```kotlin
@Serializable
data class Topic(
    val id: UUID,
    @SerialName("user_id") val userId: UUID,
    val title: String,
    val content: String,
    @SerialName("created_at") val createdAt: Date,
    @SerialName("updated_at") val updatedAt: Date,
    @SerialName("comment_count") val commentCount: Int = 0,
    @SerialName("is_trending") val isTrending: Boolean = false,
    
    // Joined from profiles table
    val profile: Profile? = null
)
```

#### Comment
```kotlin
@Serializable
data class Comment(
    val id: UUID,
    @SerialName("topic_id") val topicId: UUID,
    @SerialName("user_id") val userId: UUID,
    val content: String,
    @SerialName("created_at") val createdAt: Date,
    @SerialName("updated_at") val updatedAt: Date,
    
    // Joined from profiles table
    val profile: Profile? = null
)
```

### 4.4 Subscription Models

#### SubscriptionTier
```kotlin
enum class SubscriptionTier(
    val displayName: String,
    val productId: String
) {
    FREE("Free", ""),
    PRO_MONTHLY("Pro Monthly", "pro_monthly"),
    PRO_YEARLY("Pro Yearly", "pro_yearly");
    
    val isPro: Boolean get() = this != FREE
    
    val features: List<String> get() = when (this) {
        FREE -> listOf(
            "✅ All breathing exercises",
            "✅ All coping tools",
            "✅ Panic scale tracking",
            "✅ Local journal entries",
            "✅ Community access",
            "📍 Location tracking (last 3 journeys only)"
        )
        PRO_MONTHLY, PRO_YEARLY -> listOf(
            "✨ Everything in Free",
            "📍 Unlimited location tracking history",
            "☁️ Cloud journal backup & sync",
            "📊 Detailed metrics & analytics",
            "🗺️ Location pattern visualization"
        )
    }
}
```

#### SubscriptionStatus
```kotlin
data class SubscriptionStatus(
    val tier: SubscriptionTier,
    val expirationDate: Date? = null,
    val renewalDate: Date? = null,
    val isInTrial: Boolean = false,
    val trialEndDate: Date? = null,
    val willAutoRenew: Boolean = false,
    val transactionId: String? = null
) {
    val isActive: Boolean get() =
        tier.isPro && (expirationDate?.after(Date()) == true)
    
    val statusDescription: String get() = when {
        !tier.isPro -> "Free Plan"
        isInTrial -> "Free Trial"
        willAutoRenew -> "Active (auto-renewing)"
        else -> "Active"
    }
}
```

---

## 5. Features & Screens

### 5.1 App Structure

#### Bottom Navigation (4 Tabs)
1. **Journeys** - Brain icon (`brain.head.profile` / `psychology`)
2. **Community** - Chat bubbles icon (`bubble.left.and.bubble.right` / `forum`)
3. **Journal** - Book icon (`book.pages` / `menu_book`)
4. **Profile** - Person icon (`person.crop.circle` / `account_circle`)

### 5.2 Main Screens

#### 1. Journeys Tab (`MainJourneyHomeView`)

**Purpose:** Track panic attacks and anxiety journeys in real-time

**Screen Layout:**
- **Header:** "Your Journey" with gradient background
- **Current Journey Card** (if active):
  - Journey type badge
  - Start time
  - Current panic scale (1-10 with color gradient)
  - "View Journey" button
  
- **Quick Actions Section:**
  - "Start New Journey" button (prominent, gradient)
  - Journey type selector (Agoraphobia, General Anxiety)

- **Past Journeys:**
  - Scrollable list of completed journeys
  - Shows: date, duration, initial/final panic scale
  - Tap to view details
  
- **Empty State:**
  - Illustration
  - "Start your first journey"
  - Explanation text

#### 2. Journey Detail View (`JourneyDetailView`)

**Active Journey:**
- Real-time panic scale slider (1-10)
- Color changes with scale value
- Tools section (quick access to all coping tools)
- Notes text field
- Location tracking indicator (if enabled and Pro)
- "End Journey" button

**Completed Journey:**
- Summary card:
  - Date & time
  - Duration
  - Initial → Final panic scale
  - Tools used (chips/tags)
  - Notes
  - Location map (if available and Pro)
- Statistics
- "Delete Journey" option

#### 3. Community Tab (`CommunityOverview`)

**Purpose:** Forum-style community support

**Screen Layout:**
- **Header:** "Community" with search icon
- **Create Topic Button:** Prominent floating action button
- **Topic List:**
  - Topic card shows:
    - User avatar (first letter of name in colored circle)
    - Username
    - Title (bold)
    - Content preview (truncated)
    - Timestamp (relative: "2h ago")
    - Comment count badge
    - "Trending" badge (if applicable)
  
- **Topic Detail Screen:**
  - Full topic content
  - Author info
  - Comment section
  - Add comment text field
  - Delete topic (if owner)

**Create/Edit Topic:**
- Title text field
- Content text area (multiline)
- Save button

#### 4. Journal Tab (`JournalHome`)

**Purpose:** Private journaling with mood tracking

**Screen Layout:**
- **Header:** "Journal" with add button (+)
- **Mood Filter:** Horizontal scrollable mood chips
  - All, Happy, Sad, Angry, Excited, Stressed
  - Color-coded, icon included
  
- **Journal Entries List:**
  - Card per entry:
    - Mood icon (colored)
    - Date
    - Content preview
    - Tap to expand/view full
  
- **Create/Edit Entry:**
  - Mood selector (horizontal scrollable)
  - Text area
  - Save button
  
- **Empty State:**
  - "No entries yet"
  - Encourage first entry

#### 5. Profile Tab (`ProfileView`)

**Screen Layout:**
- **Profile Header Card:**
  - Avatar (first letter, colored circle)
  - Name
  - Email
  - Background: Subtle card with opacity

- **About Section:**
  - Icon (info circle with blue/cyan gradient)
  - "About" button
  - Chevron right

- **Subscription Section:**
  - Icon (crown for upgrade, shield checkmark for Pro)
  - Title: "Upgrade to Pro" or "Pro Member"
  - Status description
  - Chevron right
  
- **Appearance Section:**
  - Theme selector (Light, Dark, System)
  - Radio buttons with icons

- **Settings Section:**
  - Username setting (tap to change)
  - Distance unit toggle (Miles/Kilometers)

- **Permissions Section:**
  - Location permission status
  - Tap to open system settings

- **Log Out Button** (red text)

#### 6. About View (`AboutView`)

**Screen Layout:**
- **Header:**
  - Large heart icon (blue/purple gradient)
  - App name
  - Tagline: "Mental wellness companion"

- **Navigation Cards:**
  - FAQ card (blue/cyan gradient icon)
  - This App card (purple/pink gradient icon)

#### 7. FAQ View (`FAQView`)

**Screen Layout:**
- Expandable FAQ cards (10 questions)
- Tap to expand/collapse
- Smooth animation
- Icons per question

**Questions:**
1. What is Still Step?
2. How do breathing exercises work?
3. Free vs Pro differences?
4. How does location tracking work?
5. Is my journal data private?
6. Can I use offline?
7. How to cancel subscription?
8. Can I export journal?
9. What are Journeys?
10. How to contact support?

#### 8. App Info View (`AppInfoView`)

**Screen Layout:**
- **App Header:**
  - Icon
  - Version number
  - Description

- **Open Source Libraries Section:**
  - Library cards showing:
    - Name
    - Description
    - License
    - Link to GitHub

**Libraries:**
- Realm/Room - Local database
- Supabase - Backend services
- Android crypto libraries
- Other dependencies

- **Links:**
  - Website
  - Contact Support (mailto:support@stillstep.com)
  - Privacy Policy
  - Terms of Service

- **Footer:**
  - "Made with ❤️ for mental wellness"
  - Copyright

#### 9. Subscription Views

**PaywallView (Non-Pro Users):**
- **Header:**
  - Crown icon (yellow/orange gradient)
  - "Upgrade to Pro"
  - Feature description

- **Feature Grid (2x2):**
  - Unlimited Tracking (blue/cyan)
  - Cloud Backup (purple/pink)
  - Detailed Metrics (orange/red)
  - Multi-Device Sync (green/mint)

- **Pricing Cards:**
  - Yearly plan (with "BEST VALUE • SAVE X%" badge)
    - Price per month
    - Total annual price
    - Selected indicator (checkmark in circle)
  - Monthly plan
    - Price per month
    - Selected indicator

- **Subscribe Button:**
  - Gradient blue/purple
  - "Continue with [Plan Name]"
  - Arrow icon

- **Restore Purchases** button
- **Terms & Privacy** links

**SubscriptionInfoView (Pro Users):**
- **Header:**
  - Shield checkmark icon (green/mint gradient)
  - "Pro Member"
  - Success message

- **Current Plan Card:**
  - Plan name
  - Status
  - Renewal/expiration date
  - Trial info (if applicable)

- **Features List:**
  - What Pro includes

- **Action Buttons:**
  - Manage Subscription (opens Play Store)
  - Restore Purchases
  
- **Footer:**
  - Support link
  - Terms link

---

## 6. Tools & Coping Mechanisms

### Available Tools (13 Total)

All tools are accessible during an active journey to help manage anxiety/panic.

#### 1. Box Breathing (`BoxBreathing.swift`)
**Purpose:** 4-4-4-4 breathing pattern
**UI:**
- Animated square that expands/contracts
- Text instructions: "Breathe In", "Hold", "Breathe Out", "Hold"
- 4-second intervals
- Haptic feedback on phase changes
- Sound: soft beep (optional)
- Color: Blue gradient
- Cycle counter

#### 2. 4-7-8 Breathing (`478Breathing.swift`)
**Purpose:** Calming breathing technique
**UI:**
- Circular animation
- Instructions: "Breathe In (4s)", "Hold (7s)", "Breathe Out (8s)"
- Visual timer/progress indicator
- Haptic feedback
- Sound cue (optional)
- Color: Purple gradient

#### 3. 5-4-3-2-1 Grounding (`54321Grounding.swift`)
**Purpose:** Sensory grounding technique
**UI:**
- Step-by-step checklist:
  - 5 things you can see
  - 4 things you can touch
  - 3 things you can hear
  - 2 things you can smell
  - 1 thing you can taste
- Text input for each
- Progress indicator (1/5, 2/5, etc.)
- Calming colors
- "Next" button per step

#### 4. Body Scan (`BodyScan.swift`)
**Purpose:** Progressive body awareness meditation
**UI:**
- Body illustration (simple outline)
- Highlighted areas as you progress
- Audio guide or text instructions
- Progress through body parts:
  - Head → Shoulders → Arms → Chest → Abdomen → Legs → Feet
- Duration: ~5-10 minutes
- Pause/resume option

#### 5. Progressive Muscle Relaxation (`ProgressiveMuscleRelaxation.swift`)
**Purpose:** Tense and release muscle groups
**UI:**
- Muscle group list with instructions
- Timer per muscle group
- "Tense (5s)" → "Release (10s)"
- Progress indicator
- Full body coverage

#### 6. Safe Space Visualization (`SafeSpaceVisualization.swift`)
**Purpose:** Guided imagery to calm place
**UI:**
- Calming background (gradient or image)
- Text prompts/guided script
- Audio narration (optional)
- Soft music/nature sounds (optional)
- Duration: 5-10 minutes

#### 7. Positive Affirmations (`PositiveAffirmations.swift`)
**Purpose:** Display encouraging statements
**UI:**
- Card-based interface
- Swipe to see next affirmation
- Beautiful typography
- Gradient backgrounds
- Examples:
  - "I am safe and in control"
  - "This feeling will pass"
  - "I have overcome this before"
  - "I am strong and capable"
- Save favorites option

#### 8. Color Hunt Game (`ColorHunt.swift`)
**Purpose:** Distraction through color finding
**UI:**
- Shows a target color
- User looks around and taps when they find it
- "Find something [COLOR] in your environment"
- Timer
- Points/score
- Next color button
- Gamification: streaks, achievements

#### 9. Counting Game (`CountingGame.swift`)
**Purpose:** Simple distraction through counting
**UI:**
- Large number display
- Tap to increment
- Count forward/backward options
- Count by: 1, 2, 3, 5, 7, etc.
- Visual feedback on tap
- Haptic feedback

#### 10. Focus Tool (`Focus.swift`)
**Purpose:** Focus on object/thought to regain control
**UI:**
- Instructions to focus on specific object
- Timer
- Gentle reminders to maintain focus
- Breathing reminders
- Minimalist design to reduce distractions

#### 11. Tapper (`Tapper.swift`)
**Purpose:** Bilateral stimulation / rhythmic tapping
**UI:**
- Two large tap zones (left/right of screen)
- Alternating visual cues
- Rhythm options: slow, medium, fast
- Haptic feedback with each tap
- Visual ripple effect
- Sound option (binaural tones)

#### 12. Panic Scale Tracker (`PanicScaleTracker.swift`)
**Purpose:** Track current panic level
**UI:**
- Large slider: 1 (calm) to 10 (extreme panic)
- Color gradient: green → yellow → orange → red
- Number display
- "Record" button
- History graph (shows changes over journey)
- Timestamps

#### 13. Location Tracker (`LocationTracker.swift`)
**Purpose:** Track location during journey (Pro feature)
**UI:**
- Map view with current location
- Breadcrumb trail of journey path
- Panic scale markers on map
- Address/place name display
- Privacy toggle
- "Free: Last 3 journeys only" banner (non-Pro)

---

## 7. Subscription System

### 7.1 Tiers

#### Free Tier
- All tools and breathing exercises
- Panic scale tracking
- Local journal entries
- Community access
- **Location tracking:** Last 3 journeys only
- No cloud sync

#### Pro Tier
**Monthly:** ~$4.99/month
**Yearly:** ~$49.99/year (17% savings)

**Pro Features:**
- ✅ Unlimited location tracking history
- ✅ Cloud journal backup & sync
- ✅ Detailed metrics & analytics
- ✅ Journal entry insights over time
- ✅ Panic scale trend analysis
- ✅ Location pattern visualization
- ✅ Multi-device sync

### 7.2 Trial & Pricing

**Trial:**
- 1 week free trial available for both plans
- Clearly shown during purchase flow

**Pricing Display:**
- Show savings percentage for yearly
- Show monthly equivalent for yearly plan
- Display total annual price
- Auto-renewal notice
- Cancellation policy

### 7.3 Implementation

#### Android In-App Billing
```kotlin
// Product IDs
const val PRODUCT_ID_MONTHLY = "pro_monthly"
const val PRODUCT_ID_YEARLY = "pro_yearly"

// Subscription setup
val billingClient = BillingClient.newBuilder(context)
    .setListener(purchasesUpdatedListener)
    .enablePendingPurchases()
    .build()

// Query products
val productList = listOf(
    QueryProductDetailsParams.Product.newBuilder()
        .setProductId(PRODUCT_ID_MONTHLY)
        .setProductType(BillingClient.ProductType.SUBS)
        .build(),
    QueryProductDetailsParams.Product.newBuilder()
        .setProductId(PRODUCT_ID_YEARLY)
        .setProductType(BillingClient.ProductType.SUBS)
        .build()
)

// Check subscription status
billingClient.queryPurchasesAsync(
    QueryPurchasesParams.newBuilder()
        .setProductType(BillingClient.ProductType.SUBS)
        .build()
) { billingResult, purchasesList ->
    // Verify and grant entitlement
}
```

### 7.4 Feature Gating

```kotlin
class SubscriptionManager {
    fun hasProAccess(): Boolean {
        // Check active subscription
    }
    
    fun canAccessLocationHistory(journeyCount: Int): Boolean {
        return hasProAccess() || journeyCount <= 3
    }
    
    fun canSyncToCloud(): Boolean {
        return hasProAccess()
    }
    
    fun canViewMetrics(): Boolean {
        return hasProAccess()
    }
}
```

---

## 8. Backend Services (Supabase)

### 8.1 Database Schema

#### Tables

**profiles**
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    name TEXT,
    username TEXT UNIQUE,
    biography TEXT,
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**journal_entries** (for Pro cloud sync)
```sql
CREATE TABLE journal_entries (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    mood TEXT NOT NULL,
    mood_strength INTEGER,
    body TEXT NOT NULL,
    images TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**topics** (community)
```sql
CREATE TABLE topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    comment_count INTEGER DEFAULT 0,
    is_trending BOOLEAN DEFAULT FALSE
);
```

**comments**
```sql
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES topics(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 8.2 Authentication

#### Supabase Auth Setup
```kotlin
val supabase = createSupabaseClient {
    supabaseUrl = "YOUR_SUPABASE_URL"
    supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    install(Auth)
    install(Postgrest)
    install(Realtime)
}

// Sign up
suspend fun signUp(email: String, password: String) {
    supabase.auth.signUpWith(Email) {
        this.email = email
        this.password = password
    }
}

// Sign in
suspend fun signIn(email: String, password: String) {
    supabase.auth.signInWith(Email) {
        this.email = email
        this.password = password
    }
}

// Get current user
val currentUser = supabase.auth.currentUserOrNull()
```

### 8.3 Data Sync Strategy

#### Journal Sync (Pro Users Only)
1. **Local-first:** All writes go to local DB immediately
2. **Background sync:** Sync to cloud when online
3. **Conflict resolution:** Last-write-wins (use `updated_at`)
4. **Soft delete:** Mark `isDeleted=true` locally, sync delete to cloud

```kotlin
class JournalSyncService {
    suspend fun syncJournalEntries() {
        if (!subscriptionManager.hasProAccess()) return
        
        // Get entries that need sync
        val entriesToSync = localDb.getUnsyncedEntries()
        
        for (entry in entriesToSync) {
            try {
                // Upload to Supabase
                supabase.from("journal_entries")
                    .upsert(entry.toSupabaseModel())
                
                // Mark as synced locally
                localDb.markAsSynced(entry.id)
            } catch (e: Exception) {
                // Handle error, retry later
            }
        }
        
        // Pull new entries from cloud
        val cloudEntries = supabase.from("journal_entries")
            .select()
            .execute()
            .decodeList<SupabaseJournalEntry>()
        
        // Merge with local
        mergeCloudEntries(cloudEntries)
    }
}
```

### 8.4 Community Features

#### Fetch Topics
```kotlin
suspend fun fetchTopics(): List<Topic> {
    return supabase.from("topics")
        .select("""
            *,
            profile:profiles(id, name, username)
        """)
        .order("created_at", ascending = false)
        .limit(50)
        .execute()
        .decodeList<Topic>()
}
```

#### Create Topic
```kotlin
suspend fun createTopic(title: String, content: String) {
    supabase.from("topics").insert(mapOf(
        "user_id" to currentUser.id,
        "title" to title,
        "content" to content
    ))
}
```

#### Fetch Comments
```kotlin
suspend fun fetchComments(topicId: UUID): List<Comment> {
    return supabase.from("comments")
        .select("""
            *,
            profile:profiles(id, name, username)
        """)
        .eq("topic_id", topicId)
        .order("created_at", ascending = true)
        .execute()
        .decodeList<Comment>()
}
```

---

## 9. User Flows

### 9.1 Onboarding Flow

**First Launch:**
1. Splash screen
2. Sign In / Sign Up screen
   - Email + Password fields
   - "Sign In" button
   - "Create Account" button
   - "Continue as Guest" option (limited features)
3. After sign in → Username setup (if not set)
4. Journey type selection onboarding
   - Welcome screen
   - Explanation of journey types
   - Select: Agoraphobia or General Anxiety
   - Data privacy information
   - Finish button → Main app
5. Paywall shown once on first home view (if not Pro)

### 9.2 Journey Flow

**Starting a Journey:**
1. Tap "Start New Journey" on Journeys tab
2. Select journey type (if not set)
3. Initial panic scale selection
4. Journey begins → Navigate to Journey Detail View
5. Live location tracking starts (if enabled & Pro)

**During Journey:**
1. Update panic scale anytime (slider)
2. Access any tool from "Tools" section
3. Add notes in text field
4. View real-time location on map (Pro)

**Ending Journey:**
1. Tap "End Journey" button
2. Confirm dialog
3. Journey marked complete
4. Final panic scale recorded
5. Summary shown
6. Option to add final notes

### 9.3 Journal Flow

**Creating Entry:**
1. Tap + button on Journal tab
2. Select mood from horizontal picker
3. Write journal text
4. Tap "Save"
5. Entry added to list

**Viewing/Editing:**
1. Tap entry card
2. View full content
3. Edit button → modify
4. Save changes

### 9.4 Community Flow

**Browsing Topics:**
1. Open Community tab
2. Scroll through topic list
3. Tap topic to view details
4. Read comments

**Creating Topic:**
1. Tap floating action button (+)
2. Enter title
3. Enter content
4. Tap "Post"
5. Topic appears in list

**Commenting:**
1. Open topic detail
2. Scroll to comment section
3. Tap comment text field
4. Enter comment
5. Tap "Post"
6. Comment appears in list

### 9.5 Subscription Flow

**Upgrading to Pro:**
1. Tap subscription card in Profile
2. PaywallView opens
3. Review features
4. Select plan (monthly/yearly)
5. Tap "Continue with [Plan]"
6. Google Play purchase flow
7. Complete purchase
8. Pro features unlocked
9. View returns to SubscriptionInfoView

**Managing Subscription:**
1. Tap subscription card (Pro users)
2. SubscriptionInfoView opens
3. View current plan details
4. Tap "Manage Subscription" → Opens Play Store
5. Can cancel/change plan in Play Store

---

## 10. Technical Implementation Notes

### 10.1 Location Tracking

#### Setup
```kotlin
// Request permissions
val locationPermissions = arrayOf(
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION
)

// For background tracking (if needed)
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
    requestPermissions += Manifest.permission.ACCESS_BACKGROUND_LOCATION
}

// Create location client
val fusedLocationClient = LocationServices
    .getFusedLocationProviderClient(context)
```

#### Tracking During Journey
```kotlin
val locationRequest = LocationRequest.Builder(
    Priority.PRIORITY_HIGH_ACCURACY,
    interval = 10000 // 10 seconds
).build()

locationCallback = object : LocationCallback() {
    override fun onLocationResult(result: LocationResult) {
        result.locations.forEach { location ->
            // Save to local DB with journey ID
            saveLocationPoint(
                journeyId = currentJourneyId,
                latitude = location.latitude,
                longitude = location.longitude,
                timestamp = Date()
            )
        }
    }
}

fusedLocationClient.requestLocationUpdates(
    locationRequest,
    locationCallback,
    Looper.getMainLooper()
)
```

#### Feature Gating
```kotlin
if (subscriptionManager.hasProAccess()) {
    // Show full location history
    showAllLocationData()
} else {
    // Show only last 3 journeys
    showLimitedLocationData(limit = 3)
}
```

### 10.2 Audio Playback (Breathing Sounds)

```kotlin
// Play soft beep for breathing exercises
val mediaPlayer = MediaPlayer.create(context, R.raw.soft_beep)
mediaPlayer.setVolume(0.5f, 0.5f)
mediaPlayer.start()

// Release when done
mediaPlayer.release()
```

### 10.3 Haptic Feedback

```kotlin
val vibrator = context.getSystemService(Vibrator::class.java)

// Simple vibration
vibrator.vibrate(
    VibrationEffect.createOneShot(50, VibrationEffect.DEFAULT_AMPLITUDE)
)

// Pattern for breathing (inhale, hold, exhale)
val pattern = longArrayOf(0, 200, 100, 200, 100, 200)
vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
```

### 10.4 Animations

#### Breathing Circle Animation
```kotlin
val infiniteTransition = rememberInfiniteTransition()
val scale by infiniteTransition.animateFloat(
    initialValue = 1f,
    targetValue = 1.3f,
    animationSpec = infiniteRepeatable(
        animation = tween(4000, easing = LinearEasing),
        repeatMode = RepeatMode.Reverse
    )
)

Box(
    modifier = Modifier
        .size(200.dp)
        .scale(scale)
        .background(Color.Blue, CircleShape)
)
```

### 10.5 Glass Morphism Effect (Tab Bar)

```kotlin
@Composable
fun GlassEffect(modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .background(
                color = Color.White.copy(alpha = 0.1f),
                shape = RoundedCornerShape(24.dp)
            )
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    colors = listOf(
                        Color.White.copy(alpha = 0.2f),
                        Color.White.copy(alpha = 0.1f)
                    )
                ),
                shape = RoundedCornerShape(24.dp)
            )
            .blur(radius = 10.dp) // Requires Android 12+
    )
}
```

### 10.6 Dark Mode Support

```kotlin
// Theme setup
@Composable
fun StillStepTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colors = if (darkTheme) DarkColors else LightColors
    
    MaterialTheme(
        colorScheme = colors,
        typography = Typography,
        content = content
    )
}

// Adaptive colors
@Composable
fun backgroundColor(): Color {
    return if (isSystemInDarkTheme()) {
        Color(0xFF121214)
    } else {
        Color(0xFFFCF5EE)
    }
}
```

### 10.7 Data Persistence

```kotlin
// Room Database setup
@Database(
    entities = [
        JournalEntry::class,
        Journey::class,
        LocationPoint::class
    ],
    version = 1
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun journalDao(): JournalDao
    abstract fun journeyDao(): JourneyDao
    abstract fun locationDao(): LocationDao
}

// DataStore for preferences
val Context.dataStore: DataStore<Preferences> by preferencesDataStore(
    name = "settings"
)

// Save settings
suspend fun saveTheme(theme: Theme) {
    context.dataStore.edit { preferences ->
        preferences[THEME_KEY] = theme.name
    }
}
```

---

## 11. Additional Features & Notes

### 11.1 Notifications
- **Local notifications:** Remind users to journal
- **Push notifications:** Community replies, support messages
- Use WorkManager for background tasks

### 11.2 Analytics (Optional)
- Firebase Analytics for usage tracking
- Crash reporting with Firebase Crashlytics
- Track: screen views, tool usage, journey completion rates

### 11.3 Accessibility
- Content descriptions for all images/icons
- Minimum touch target size: 48dp
- Support TalkBack
- High contrast mode support
- Adjustable text sizes

### 11.4 Performance
- Lazy loading for lists (LazyColumn)
- Image caching with Coil
- Database queries on background threads
- Pagination for community topics

### 11.5 Security
- Encrypt local database with SQLCipher (optional)
- Secure API keys in local.properties
- ProGuard/R8 obfuscation for release builds
- Certificate pinning for Supabase API

### 11.6 Testing
- Unit tests for ViewModels
- Integration tests for database
- UI tests with Compose Testing
- Mock Supabase responses

---

## 12. Assets & Resources

### 12.1 Required Assets
- App icon (adaptive icon for Android)
- Splash screen
- Sound effect: soft_beep.mp3/wav
- Body scan illustration (SVG/vector)
- Empty state illustrations

### 12.2 String Resources

Create `strings.xml` for all UI text to support future localization.

### 12.3 Configuration

**Build Variants:**
- `debug` - Development with logging
- `release` - Production optimized

**Environment Variables:**
```kotlin
// In local.properties
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

---

## 13. Launch Checklist

### Pre-Launch
- [ ] Set up Google Play Console
- [ ] Create in-app products (subscriptions)
- [ ] Set up Supabase project
- [ ] Configure database tables and RLS policies
- [ ] Implement all core features
- [ ] Add location permission requests
- [ ] Implement subscription logic
- [ ] Design all screens per specification
- [ ] Test on multiple devices/screen sizes
- [ ] Test subscription flow (sandbox)
- [ ] Write privacy policy
- [ ] Write terms of service
- [ ] Create Play Store listing
- [ ] Generate screenshots
- [ ] Alpha/Beta testing

### Play Store Requirements
- Minimum SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)
- App bundle (.aab format)
- Privacy policy URL
- Data safety form completed
- Content rating questionnaire

---

## 14. Contact & Support

**Support Email:** support@stillstep.com  
**Website:** https://stillstep.com  
**Privacy Policy:** https://stillstep.com/privacy  
**Terms:** https://stillstep.com/terms

---

## 15. Summary

Still Step is a comprehensive mental wellness app with:
- **4 main tabs:** Journeys, Community, Journal, Profile
- **13 coping tools** for anxiety/panic attacks
- **Real-time journey tracking** with panic scale
- **Location tracking** (Pro feature, limited for free)
- **Cloud sync** for journal entries (Pro only)
- **Community forum** for support
- **Freemium model** with monthly/yearly subscriptions
- **Beautiful UI** with gradients, glass effects, adaptive dark mode

**Key Technologies (Android):**
- Kotlin + Jetpack Compose
- Room or Realm for local storage
- Supabase for backend
- Google Play Billing for subscriptions
- Location Services for tracking
- Material Design 3

**Design Philosophy:**
- Clean, modern interface
- Calming color palette
- Smooth animations
- Accessibility-first
- Privacy-focused

This guide provides everything needed to build an Android version that matches the iOS app's functionality and design. Good luck with development! 🚀

