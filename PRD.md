# Product Requirements Document (PRD)

## Deeper with Jesus — Daily Devotional App

| Field | Value |
|---|---|
| **Product Name** | Deeper with Jesus |
| **Version** | 1.0.0 |
| **Platform** | iOS, Android, Web (Flutter) |
| **Last Updated** | March 13, 2026 |
| **Status** | Phase 4 Complete — Preparing for App Store & Play Store submission |

---

## 1. Product Overview

### 1.1 Vision
Deeper with Jesus is a mobile-first daily devotional app that delivers one beautifully crafted spiritual post per day. It combines the simplicity of a daily devotional calendar with the visual richness of a social media post, creating a focused faith-building habit without the noise of traditional social feeds.

### 1.2 Problem Statement
Existing devotional apps are either text-heavy and uninspiring, or bloated with features that distract from spiritual focus. Users want a single, beautiful daily moment with God — not an information firehose.

### 1.3 Solution
A curated one-post-per-day devotional experience where an admin team publishes spiritually enriching content (images with captions or templated text on gradient backgrounds) on a daily schedule. Users open the app, see today's post, and engage through likes and comments.

### 1.4 Target Audience
- **Primary**: Christians aged 18-45 seeking consistent daily devotional habits
- **Secondary**: Church leaders and ministry teams who manage content
- **Tertiary**: Curious spiritual seekers exploring faith in a low-pressure format

---

## 2. Technical Architecture

### 2.1 Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter 3.42.0 (Dart SDK ^3.11.0) |
| State Management | Riverpod 3.3.1 |
| Navigation | GoRouter 17.1.0 |
| Backend | Firebase (Blaze Plan) |
| Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Authentication | Firebase Auth (Google, Apple, Guest) |
| Typography | Google Fonts (Playfair Display, Raleway, Lora) |
| Icons | Lucide Icons |
| Calendar | table_calendar 3.2.0 |
| Local Storage | SharedPreferences |

### 2.2 Architecture Pattern
- **Feature-first** directory structure (`lib/features/{feature}/`)
- **Service layer** (`lib/core/services/`) encapsulates all Firebase operations
- **Provider layer** (`lib/core/providers/`) exposes reactive streams via Riverpod
- **Real-time updates** via Firestore snapshot streams → Riverpod StreamProviders → UI
- **No backend server** — fully serverless via Firebase services

### 2.3 Firebase Collections

| Collection | Document ID | Purpose |
|---|---|---|
| `posts` | Auto-generated | Devotional posts (published + scheduled) |
| `posts/{postId}/comments` | Auto-generated | Comments subcollection per post |
| `users` | Firebase Auth UID | User profiles and preferences |
| `admin_emails` | Email address | Admin role whitelist |
| `fcm_tokens` | FCM token string | Push notification tokens per device |
| `notifications` | Auto-generated | Log of sent push notifications |

### 2.4 Firebase Storage Structure

| Path | Purpose |
|---|---|
| `post_images/{filename}` | Uploaded post images (JPEG, max 10MB) |

---

## 3. User Roles & Permissions

### 3.1 Guest (Unauthenticated)
- Browse all published posts (Home, Calendar, Topics)
- View post details and engagement counts
- Cannot like, comment, or access profile features
- Prompted to sign in when attempting authenticated actions

### 3.2 User (Authenticated)
- Everything a Guest can do, plus:
- Like posts (toggle, with count)
- Comment on posts
- Manage profile settings (notifications, appearance)
- Delete own account

### 3.3 Admin
- Everything a User can do, plus:
- Access Admin Dashboard with engagement analytics
- Create, edit, publish, schedule, and delete posts
- Upload images or use template-based post creation
- Moderate comments (approve/delete)
- Manage admin email whitelist (add/remove admins)
- Manage topics (create/edit/delete)
- Send push notifications to all users

### 3.4 Admin Assignment
- Admin status is granted by email whitelist in the `admin_emails` Firestore collection
- On first sign-in, `UserService.getOrCreateUser()` checks if the user's email exists in `admin_emails`
- If match found: `role = 'admin'`; otherwise: `role = 'user'`
- Existing admins can add/remove emails via the Manage Admins screen

---

## 4. Feature Specifications

### 4.1 Onboarding Flow

**Screen**: `OnboardingScreen`

| Requirement | Detail |
|---|---|
| Slides | 3-slide carousel introducing app value propositions |
| Persistence | `hasSeenOnboarding` flag stored in SharedPreferences |
| CTA | "Go Deeper" button advances to Welcome screen |
| Skip Logic | Returns directly to Welcome after first completion |

**Screen**: `WelcomeScreen`

| Requirement | Detail |
|---|---|
| Sign-in Options | Google Sign-In, Apple Sign-In (iOS only), Continue as Guest |
| Visual Design | Gradient background adapting to light/dark theme |
| Loading State | Overlay spinner during auth operations |
| Error Handling | Snackbar messages for auth failures |
| Post-Auth | Creates/fetches Firestore user doc, navigates to Home |

### 4.2 Home Tab — Daily Devotional

**Screen**: `HomeScreen`

| Requirement | Detail |
|---|---|
| Layout | Full-screen post card, one per day |
| Navigation | Horizontal swipe (PageView) between days |
| Date Display | Pill showing "Today", "Yesterday", "Tomorrow", or formatted date |
| Date Arrows | Left/right arrows for day navigation |
| Forward Limit | Cannot swipe or navigate beyond tomorrow |
| Backward Limit | Unlimited backward scrolling |
| Fallback | When no post exists for a date, shows a random Bible verse |

**Component**: `PostCard`

| Post Type | Rendering |
|---|---|
| **Template Post** | Full-screen gradient background from template + centered text content |
| **Image Post** | Square image (from Firebase Storage) + caption below + topic tags |

| Interaction | Detail |
|---|---|
| Like Button | Heart icon, toggles filled/outline, shows count. Requires auth. |
| Comment Button | Opens CommentSheet bottom sheet with real-time Firestore comments. Shows count. Requires auth to post. |
| Share Button | Native share sheet with post content. |
| Topic Tags | Displayed as hashtag chips below content. |

### 4.3 Discover Tab

**Screen**: `DiscoverScreen` — TabBar with two sub-views

#### 4.3.1 Calendar View (`CalendarTab`)

| Requirement | Detail |
|---|---|
| Calendar Widget | Monthly calendar (table_calendar package) |
| Post Indicators | Circular thumbnails on days that have posts |
| Template Posts | Show miniature gradient dot |
| Image Posts | Show miniature image thumbnail |
| Tap Action | Opens PostViewerScreen at the tapped date |
| Today Highlight | Gold accent color |
| Selected Highlight | Primary color |

#### 4.3.2 Topics View (`TopicsTab`)

| Requirement | Detail |
|---|---|
| Filter Bar | Horizontal scrolling chip selector for all topics |
| Grid Layout | 2-column grid of post thumbnails |
| Image Posts | Show image thumbnail with overlay |
| Template Posts | Show gradient background with text preview |
| Tap Action | Opens PostViewerScreen at the post's date |

### 4.4 Profile Tab

**Screen**: `ProfileScreen`

| Section | Items |
|---|---|
| User Info | Avatar (initials or icon), display name, email |
| Settings | Notifications toggle, Appearance selector (Light/Dark/System) |
| Links | Instagram, Contact Support, Privacy Policy |
| Admin Section | Dashboard, Create Post, Topics, Admins (shown only if `isAdmin`) |
| Account | Sign Out, Delete Account (with confirmation dialog) |
| Guest State | Sign-in prompt instead of user info and account actions |

### 4.5 Admin Dashboard

**Screen**: `AdminDashboard`

| Section | Detail |
|---|---|
| **Stats Row 1** | Total Posts, Published Count, Scheduled Count |
| **Stats Row 2** | Total Views, Total Likes, Total Comments |
| **Post Tabs** | Published / Scheduled / All |
| **Post List** | Thumbnail, title, date, engagement counts, status badge |
| **Quick Actions** | Send Notification, Create Post, Moderate Comments |
| **FAB** | Floating action button → Create Post |
| **Number Format** | Counts formatted with "k" suffix for thousands |

### 4.6 Post Creation

**Flow**: Create Post → (Upload Image OR Pick Template) → Configure → Publish/Schedule

#### 4.6.1 Image Upload Path

| Step | Screen | Detail |
|---|---|---|
| 1 | CreatePostScreen | Tap "Upload Image" → opens device gallery |
| 2 | CreatePostScreen | Image compressed to 1080x1080, 85% JPEG quality |
| 3 | CreatePostScreen | Add caption (3-line text area) |
| 4 | SchedulePicker | Select topics, pick date/time or publish now |
| 5 | — | Image uploaded to Firebase Storage → post doc created in Firestore |

#### 4.6.2 Template Path

| Step | Screen | Detail |
|---|---|---|
| 1 | CreatePostScreen | Tap "Use Template" |
| 2 | TemplatePicker | Grid of 10 gradient templates with names, tap to select |
| 3 | TextEditorScreen | Enter text content, select topics, add caption |
| 4 | TextEditorScreen | Publish immediately or schedule |
| 5 | — | Post doc created in Firestore with templateId + textContent |

### 4.7 Content Templates

10 built-in gradient templates:

| # | Name | Colors |
|---|---|---|
| 1 | Mountain Sunrise | Purple to Gold |
| 2 | Ocean at Dawn | Blue to Cyan |
| 3 | Forest Path | Green gradient |
| 4 | Misty Valley | Gray gradient |
| 5 | Golden Wheat Field | Brown to Gold |
| 6 | Starry Night Sky | Dark Navy to Indigo |
| 7 | Soft Watercolor | Pastel mix |
| 8 | Lily Pond | Teal to Green |
| 9 | Candle Flame | Warm Brown to Gold |
| 10 | Desert Sunset | Orange to Red |

Each template defines a `LinearGradient` with customizable alignment and color stops. Templates include luminance detection for automatic dark/light text color selection.

### 4.8 Default Topics

10 built-in topic categories with custom brand colors:

| Topic | Color |
|---|---|
| Faith | Purple |
| Prayer | Indigo |
| Hope | Cyan |
| Love | Pink |
| Gratitude | Gold |
| Strength | Red |
| Peace | Green |
| Forgiveness | Violet |
| Purpose | Orange |
| Wisdom | Teal |

Admins can create additional custom topics via the Manage Topics screen.

### 4.9 Fallback Bible Verses

When no post is published for a given date, the app displays a fallback Bible verse from a curated collection of 365+ verses stored in `lib/core/constants/bible_verses.dart`. Verses are deterministically selected based on the date to ensure consistency across sessions.

---

## 5. Authentication Specification

### 5.1 Google Sign-In
- OAuth 2.0 flow via `google_sign_in` package
- Supported on iOS, Android, and Web
- Retrieves `idToken` and `accessToken` → creates Firebase `GoogleAuthProvider.credential`
- On success: calls `UserService.getOrCreateUser()` to create/fetch Firestore profile

### 5.2 Apple Sign-In
- Available on iOS only (conditionally rendered)
- Uses nonce-based security: generates random nonce → SHA256 hash → sends to Apple
- Persists first-name from initial Apple authorization (Apple only sends name on first sign-in)
- Creates `OAuthProvider('apple.com').credential` with `idToken` + raw nonce
- Updates display name on Firestore user doc if available from Apple response

### 5.3 Guest Mode
- Sets `isGuestProvider` flag to `true` (no Firebase Auth session)
- Full read access to published content
- Authenticated actions trigger `AuthPromptSheet` bottom sheet
- AuthPromptSheet offers Google/Apple sign-in from anywhere in the app

### 5.4 Auth State Management
- `firebaseAuthStateProvider` (StreamProvider) watches `FirebaseAuth.authStateChanges()`
- `appUserProvider` (StreamProvider) derives from auth state → streams Firestore user doc
- GoRouter `refreshListenable` triggers route recalculation on auth state changes
- Auth guard redirects: unauthenticated + not-guest → `/welcome`, admin routes require `isAdmin`

---

## 6. Data Models

### 6.1 DevotionalPost

```
id              String          Firestore document ID (auto-generated)
imageUrl        String?         Firebase Storage download URL (image posts)
templateId      String?         Template identifier (template posts)
textContent     String?         Main text content (template posts)
caption         String?         Subtitle/caption (all post types)
scheduledFor    DateTime        Publication date/time
isPublished     bool            Whether post is live
topicIds        List<String>    Associated topic IDs for filtering
type            String          'uploaded' or 'template'
likesCount      int             Total like count
commentsCount   int             Total comment count
viewsCount      int             Total view count
```

### 6.2 AppUser

```
uid                     String      Firebase Auth UID (document ID)
displayName             String      User's display name
email                   String?     Email address (null for some OAuth)
photoUrl                String?     Profile photo URL
role                    String      'user' or 'admin'
notificationsEnabled    bool        Push notification preference
isBanned                bool        Ban status flag
createdAt               DateTime    Account creation timestamp
```

**Computed**: `isAdmin` getter returns `role == 'admin'`

### 6.3 Comment

```
id              String      Comment document ID
userId          String      Author's Firebase Auth UID
displayName     String      Author's display name at time of comment
photoUrl        String?     Author's photo URL at time of comment
text            String      Comment body text
createdAt       DateTime    Timestamp of comment creation
```

---

## 7. Security Rules

### 7.1 Firestore Security Rules (Production)

| Collection | Read | Write |
|---|---|---|
| `posts/{postId}` | Public (anyone) | Admin only (`isAdmin()` check via admin_emails) |
| `posts/{postId}/comments/{commentId}` | Public (anyone) | Create: authenticated (own userId). Delete: author or admin. Update: denied (immutable). |
| `users/{userId}` | Owner or Admin | Owner only (create, update, delete) |
| `admin_emails/{email}` | Authenticated users | Admin only |
| Everything else | Denied | Denied |

**Helper functions**: `isAuth()`, `isAdmin()` (checks admin_emails collection), `isOwner(userId)`

### 7.2 Firebase Storage Security Rules (Production)

| Path | Read | Write |
|---|---|---|
| `post_images/{imageId}` | Public | Authenticated + size < 10MB + image content type |
| Everything else | Denied | Denied |

### 7.3 Firebase Cloud Functions

| Function | Trigger | Purpose |
|---|---|---|
| `onPostPublished` | Firestore document update (`posts/{postId}`) | Sends FCM topic notification when `isPublished` flips to `true` |
| `onPostCreatedPublished` | Firestore document create (`posts/{postId}`) | Sends FCM topic notification when a post is created already published |
| `sendCustomNotification` | HTTPS Callable (admin-only) | Admin broadcast notification to all subscribers via `new_posts` topic |
| `autoPublishScheduledPosts` | Scheduled (every 30 minutes) | Auto-publishes posts whose `scheduledFor` time has passed |

### 7.3 Firestore Composite Indexes

| # | Collection | Fields | Status |
|---|---|---|---|
| 1 | posts | `isPublished` ASC + `scheduledFor` DESC | Enabled |
| 2 | posts | `isPublished` ASC + `topicIds` Arrays + `scheduledFor` DESC | Enabled |
| 3 | posts | `isPublished` ASC + `scheduledFor` ASC | Enabled |

---

## 8. Design System

### 8.1 Color Palette

**Light Mode**

| Token | Hex | Usage |
|---|---|---|
| Primary | `#7C3AED` | Buttons, active states, links |
| Secondary | `#A78BFA` | Accents, secondary actions |
| Background | `#FAF5FF` | Page backgrounds |
| Surface | `#FFFFFF` | Cards, sheets, dialogs |
| Text Primary | `#4C1D95` | Headings, body text |
| Text Secondary | `#6D28D9` | Captions, labels |
| Gold | `#CA8A04` | CTAs, today highlight |
| Error | `#DC2626` | Error states, destructive actions |
| Like Red | `#EF4444` | Liked heart icon |
| Divider | `#E9D5FF` | Separators, borders |

**Dark Mode**

| Token | Hex | Usage |
|---|---|---|
| Primary | `#A78BFA` | Buttons, active states, links |
| Secondary | `#C4B5FD` | Accents, secondary actions |
| Background | `#1C1023` | Page backgrounds |
| Surface | `#2D1F3D` | Cards, sheets, dialogs |
| Text Primary | `#F3E8FF` | Headings, body text |
| Text Secondary | `#C4B5FD` | Captions, labels |
| Gold | `#EAB308` | CTAs, today highlight |
| Error | `#F87171` | Error states |
| Divider | `#3D2A54` | Separators, borders |

### 8.2 Typography

| Style | Font | Weight | Usage |
|---|---|---|---|
| Display / Headline | Playfair Display | Bold | Section headers, large titles |
| Body / Label | Raleway | Regular/Medium | Body text, captions, UI labels |
| Emphasis | Lora | Regular | Quotes, scripture text, emphasis |

### 8.3 Component Specs

| Component | Spec |
|---|---|
| Button Border Radius | 12px |
| Card Border Radius | 16px |
| Bottom Sheet Top Radius | 24px |
| Default Icon Size | 24px (Lucide) |
| Post Image Compression | 1080x1080, JPEG 85% quality |

### 8.4 Theme Modes
- **Light Mode**: Purple-violet palette on light lavender backgrounds
- **Dark Mode**: Lighter violet accents on deep purple-black backgrounds
- **System Mode**: Follows device setting (default)
- Stored via SharedPreferences, managed by Riverpod NotifierProvider

---

## 9. Navigation & Routing

### 9.1 Route Map

```
/onboarding          → OnboardingScreen         (first launch only)
/welcome             → WelcomeScreen             (unauthenticated landing)
/home                → HomeScreen                (main tab 1 - daily post)
/discover            → DiscoverScreen            (main tab 2 - calendar/topics)
/profile             → ProfileScreen             (main tab 3 - settings)
/admin               → AdminDashboard            (admin panel)
/admin/create        → CreatePostScreen          (new post workflow)
/admin/templates     → TemplatePicker            (select template)
/admin/editor        → TextEditorScreen          (write template post)
/admin/schedule      → SchedulePicker            (set date/time)
/admin/comments      → CommentModerationScreen   (moderate comments)
/admin/admins        → ManageAdminsScreen        (admin email list)
/admin/topics        → ManageTopicsScreen        (topic management)
/admin/notifications → SendNotificationScreen    (broadcast notifications)
```

### 9.2 Bottom Navigation
- 3 tabs: **Home**, **Discover**, **Profile**
- iOS: `NativeGlassNavBar` (frosted glass blur effect)
- Android/Web: Material bottom navigation bar
- Icons: Lucide Icons (Home, Compass, User)
- Active tab: primary color highlight

### 9.3 Route Guards
- **Auth Guard**: If not authenticated AND not guest AND past onboarding → redirect to `/welcome`
- **Onboarding Guard**: If hasn't seen onboarding → redirect to `/onboarding`
- **Admin Guard**: If route starts with `/admin` AND user is not admin → redirect to `/home`

---

## 10. API & Service Layer

### 10.1 AuthService

| Method | Description |
|---|---|
| `signInWithGoogle()` | Google OAuth → Firebase credential → sign in |
| `signInWithApple()` | Apple OAuth with nonce → Firebase credential → sign in |
| `signOut()` | Sign out from Firebase + Google SDK |
| `authStateChanges` | Stream of Firebase `User?` |
| `currentUser` | Current `User?` getter |

### 10.2 PostService

| Method | Description |
|---|---|
| `createPost(DevotionalPost)` | Creates post doc in Firestore |
| `updatePost(DevotionalPost)` | Updates existing post doc |
| `publishPost(String id)` | Sets `isPublished = true` |
| `deletePost(String id)` | Deletes post doc |
| `uploadPostImage(File)` | Uploads to Storage, returns download URL |
| `watchPublishedPosts()` | Stream of published posts, ordered by date desc |
| `watchAllPosts()` | Stream of all posts (admin view) |
| `watchPostForDate(DateTime)` | Stream of single post for a specific date |
| `watchPostsByTopic(String)` | Stream of posts filtered by topic ID |
| `addComment(postId, userId, displayName, photoUrl?, text)` | Creates comment in subcollection + atomically increments `commentsCount` |
| `watchComments(String postId)` | Real-time stream of comments ordered by `createdAt` ascending |
| `deleteComment(postId, commentId)` | Deletes comment + atomically decrements `commentsCount` |

### 10.3 NotificationService

| Method | Description |
|---|---|
| `initialize(String userId)` | Request permissions, get APNs/FCM tokens, subscribe to `new_posts` topic, set up handlers |
| `handleTopicSubscription(bool)` | Subscribe/unsubscribe from `new_posts` FCM topic |
| `setRouter(GoRouter)` | Attach router for deep linking from notification taps |
| `removeToken(String userId)` | Remove device FCM token on sign-out |
| `showStreakMilestone(int count)` | Local notification for reading streak milestones |

**iOS-specific**: Waits for APNs token before FCM operations. Foreground notifications displayed via `flutter_local_notifications`.

**Deep linking**: Notification taps navigate to `/post/{postId}` with optional `?date=` query parameter.

### 10.4 UserService

| Method | Description |
|---|---|
| `getOrCreateUser(User)` | Creates Firestore doc on first sign-in, checks admin email |
| `getUser(String uid)` | One-shot read of user doc |
| `watchUser(String uid)` | Real-time stream of user doc |
| `updateUser(AppUser)` | Merge-update user doc fields |
| `deleteUser(String uid)` | Deletes user doc from Firestore |
| `isAdminEmail(String)` | Checks if email exists in `admin_emails` collection |

---

## 11. Firestore Query Patterns

| Query | Collection | Filters | Order |
|---|---|---|---|
| Published posts feed | `posts` | `isPublished == true` | `scheduledFor` DESC |
| Post for specific date | `posts` | `isPublished == true`, `scheduledFor` in day range | `scheduledFor` ASC |
| Posts by topic | `posts` | `isPublished == true`, `topicIds` arrayContains | `scheduledFor` DESC |
| All posts (admin) | `posts` | None | `scheduledFor` DESC |
| Comments for a post | `posts/{postId}/comments` | None | `createdAt` ASC |

---

## 12. Project Structure

```
firestore.rules                        Firestore security rules (version-controlled)
lib/
├── main.dart                          App entry point, Firebase init
├── app.dart                           GoRouter config, MainShell, theme
├── firebase_options.dart              Firebase project configuration
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            Color palette (light + dark)
│   │   ├── app_theme.dart             Material 3 theme definitions
│   │   ├── templates.dart             10 gradient post templates
│   │   ├── default_topics.dart        10 topic categories with colors
│   │   └── bible_verses.dart          365+ fallback Bible verses
│   ├── models/
│   │   └── devotional_post.dart       DevotionalPost, Comment, AppUser
│   ├── services/
│   │   ├── auth_service.dart          Firebase Auth operations
│   │   ├── post_service.dart          Post CRUD + image upload
│   │   ├── user_service.dart          User profile management
│   │   └── notification_service.dart  FCM init, topic subscription, deep linking
│   └── providers/
│       ├── auth_provider.dart         Auth state + sign-in functions
│       ├── post_provider.dart         Post stream providers
│       └── notification_provider.dart Auto-init notifications on sign-in
│
├── features/
│   ├── auth/
│   │   ├── onboarding_screen.dart     3-slide intro carousel
│   │   ├── welcome_screen.dart        Sign-in / guest entry
│   │   └── auth_prompt_sheet.dart     Auth bottom sheet for guests
│   ├── home/
│   │   ├── home_screen.dart           Daily post PageView
│   │   ├── post_card.dart             Post rendering (image + template)
│   │   ├── post_viewer_screen.dart    Full-screen post browser
│   │   └── comment_sheet.dart         Comment bottom sheet
│   ├── discover/
│   │   ├── discover_screen.dart       TabBar (Calendar + Topics)
│   │   ├── calendar_tab.dart          Monthly calendar with indicators
│   │   └── topics_tab.dart            Topic filter + post grid
│   ├── profile/
│   │   └── profile_screen.dart        Settings, links, admin access
│   └── admin/
│       ├── admin_dashboard.dart       Stats + post management
│       ├── create_post_screen.dart    Post creation entry point
│       ├── template_picker.dart       Template selection grid
│       ├── text_editor_screen.dart    Template text editor
│       ├── schedule_picker.dart       Date/time scheduling
│       ├── comment_moderation_screen.dart  Comment moderation
│       ├── manage_admins_screen.dart  Admin email management
│       ├── manage_topics_screen.dart  Topic CRUD
│       └── send_notification_screen.dart   Push notification composer
│
└── shared/
    └── widgets/
        └── template_background.dart   Reusable gradient background

functions/
└── src/
    └── index.ts                       Cloud Functions (notifications, auto-publish)

firestore.rules                        Firestore security rules (version-controlled)
```

---

## 13. Dependencies

### Production Dependencies

| Package | Version | Purpose |
|---|---|---|
| flutter_riverpod | ^3.3.1 | State management |
| go_router | ^17.1.0 | Declarative routing |
| google_fonts | ^8.0.2 | Custom typography |
| lucide_icons | ^0.257.0 | UI icons |
| shared_preferences | ^2.5.4 | Local key-value storage |
| table_calendar | ^3.2.0 | Calendar widget |
| intl | ^0.20.2 | Date formatting |
| native_glass_navbar | ^1.0.1 | iOS glass navbar effect |
| image_picker | ^1.1.2 | Gallery image selection |
| firebase_core | ^3.12.1 | Firebase initialization |
| firebase_auth | ^5.6.1 | Authentication |
| cloud_firestore | ^5.6.5 | Database |
| firebase_storage | ^12.4.4 | File storage |
| firebase_messaging | ^15.2.4 | Push notifications (FCM) |
| flutter_local_notifications | ^18.0.1 | Foreground notification display |
| cloud_functions | ^5.3.4 | Firebase Cloud Functions client |
| firebase_app_check | ^0.3.2+10 | App integrity verification |
| google_sign_in | ^6.2.2 | Google OAuth |
| sign_in_with_apple | ^7.0.1 | Apple OAuth |
| crypto | ^3.0.6 | SHA256 for Apple nonce |
| url_launcher | ^6.3.1 | External link opening |
| share_plus | ^10.1.4 | Native share sheet |
| flutter_svg | ^2.1.0 | SVG rendering |
| path_provider | ^2.1.5 | File system paths |

### Dev Dependencies

| Package | Version | Purpose |
|---|---|---|
| flutter_lints | ^6.0.0 | Lint rules |
| flutter_launcher_icons | ^0.14.3 | App icon generation |

---

## 14. User Journeys

### 14.1 First Launch
1. App opens → `main.dart` initializes Firebase + loads SharedPreferences
2. `hasSeenOnboarding == false` → redirect to `/onboarding`
3. User swipes through 3 onboarding slides
4. Taps "Go Deeper" → navigates to `/welcome`
5. User signs in (Google/Apple) or continues as guest
6. Post-auth: Firestore user doc created, admin role checked
7. Navigate to `/home` → today's devotional post displayed

### 14.2 Daily Reading (Returning User)
1. App opens → auth state restored automatically
2. Route to `/home` → today's post loads from Firestore stream
3. User reads post, taps like (heart fills, count increments)
4. User taps comment → CommentSheet opens
5. User swipes left → yesterday's post loads
6. User taps Discover tab → Calendar view with post thumbnails

### 14.3 Admin Publishing (Image Post)
1. Admin opens Profile → taps Dashboard → AdminDashboard loads
2. Taps "Create Post" (FAB or quick action)
3. Taps "Upload Image" → image picker opens
4. Selects image → compressed to 1080x1080
5. Adds caption in text area
6. Taps "Next" → SchedulePicker screen
7. Selects topic tags (multi-select)
8. Chooses "Publish Now" or picks future date
9. Image uploaded to Firebase Storage → post doc created in Firestore
10. Post appears in dashboard and on user feeds

### 14.4 Admin Publishing (Template Post)
1. From CreatePostScreen, taps "Use Template"
2. TemplatePicker shows 10 gradient options → taps one
3. TextEditorScreen opens with template preview
4. Types devotional text, adds caption
5. Selects topic tags
6. Chooses publish now or schedule
7. Post doc created with templateId + textContent (no image upload)

### 14.5 Guest → Authenticated Upgrade
1. Guest browsing posts, taps Like button
2. `AuthPromptSheet` appears: "Sign in to interact"
3. Guest taps Google Sign-In
4. Auth completes → user doc created → sheet dismisses
5. Like action completes, heart fills

---

## 15. Roadmap & Completion Status

### Phase 1 — UI Prototype ✅
- [x] Full-screen daily post card with horizontal swipe navigation
- [x] 10 gradient templates, fallback Bible verses
- [x] Discover screen (Calendar + Topics), Profile, Admin dashboard
- [x] Create post flow (image upload + template), design system (light/dark)

### Phase 2A — Firebase + Authentication ✅
- [x] Firebase Core, Firestore, Auth, Storage integration
- [x] Google Sign-In, Apple Sign-In (iOS), Guest mode
- [x] Auth-aware routing with Riverpod providers
- [x] Firestore security rules, composite indexes

### Phase 2B — Comments & Engagement ✅
- [x] Comment creation/deletion with Firestore subcollection
- [x] Real-time comment streams, atomic comment count tracking
- [x] Comment moderation workflow (admin approve/delete)
- [x] Like toggle persistence per user

### Phase 3 — Push Notifications ✅
- [x] Firebase Cloud Messaging (FCM) integration (iOS + Android)
- [x] APNs token handling for iOS with wait-for-token pattern
- [x] Topic-based notifications (`new_posts` topic)
- [x] Admin broadcast notifications via Cloud Functions
- [x] Notification preferences (per-user opt-in/out)
- [x] Deep linking from notification → specific post
- [x] Reading streak milestone local notifications
- [x] Firebase App Check for app integrity

### Phase 4 — Store Submission (In Progress)
- [x] iOS bundle ID registered (`com.deeperwithjesus.mobile`)
- [x] Android release signing configuration
- [x] App Store metadata prepared
- [x] Play Store metadata prepared
- [ ] iOS App Store submission
- [ ] Google Play Store submission

### Future Phases
- [ ] Rich text editor for template posts
- [ ] Video/audio devotional support
- [ ] User bookmarks / saved posts
- [ ] Share to social media (Instagram Stories, etc.)
- [ ] Community prayer wall
- [ ] Multi-language support
- [ ] Offline mode (cached posts)

---

## 16. Non-Functional Requirements

### 16.1 Performance
- App cold start: < 3 seconds on mid-range devices
- Post loading (Firestore stream): < 1 second
- Image upload: < 5 seconds for 10MB file on 4G
- Smooth 60fps scrolling on PageView and calendar

### 16.2 Security
- Firebase Security Rules enforcing role-based access
- No sensitive data in client-side code
- Apple Sign-In nonce-based CSRF protection
- Image upload validation (type + size limits)
- Admin operations server-side gated via Firestore rules

### 16.3 Reliability
- Firestore real-time streams with automatic reconnection
- Graceful fallback content (Bible verses) when no post exists
- Error handling with user-friendly messages (snackbars)
- Offline tolerance (cached Firestore data)

### 16.4 Accessibility
- Semantic labels on interactive elements
- Contrast ratios meeting WCAG AA in both themes
- Touch targets minimum 44x44 points
- Screen reader compatible navigation structure

### 16.5 Scalability
- Firestore auto-scales with user growth
- Firebase Storage CDN for global image delivery
- Composite indexes for efficient compound queries
- No server infrastructure to manage (fully serverless)

---

## 17. Release Checklist

### Pre-Release
- [x] `flutter analyze` — 0 issues
- [x] All Firestore composite indexes enabled
- [x] Firestore security rules published (production)
- [x] Storage security rules published (production)
- [x] Admin email seeded in `admin_emails` collection
- [x] Firebase Auth providers enabled (Google, Apple)
- [x] App icon generated via flutter_launcher_icons
- [x] Privacy Policy URL configured (`https://www.geniustechhub.com/privacy-policy`)
- [x] Cloud Functions deployed (notifications, auto-publish)
- [x] APNs Authentication Key uploaded in Firebase Console
- [x] Firebase App Check enabled

### iOS Submission
- [x] Bundle ID registered (`com.deeperwithjesus.mobile`)
- [ ] App Store Connect listing created
- [ ] Screenshots captured (6.7", 6.5")
- [ ] App Privacy details filled
- [x] Sign in with Apple entitlement enabled
- [ ] `ios/Runner.xcworkspace` archive builds cleanly
- [ ] TestFlight build uploaded and tested
- [ ] App Review submission

### Android Submission
- [x] Package name: `com.deeperwithjesus.deeper_with_jesus`
- [x] Release signing key configured (`key.properties` + `build.gradle.kts`)
- [ ] Play Store listing created
- [ ] Feature graphic + screenshots uploaded
- [ ] Data safety form completed
- [ ] AAB bundle built and uploaded
- [ ] Internal testing track verified
- [ ] Production release submission

---

*This PRD is a living document and should be updated as the product evolves through each phase of development.*
