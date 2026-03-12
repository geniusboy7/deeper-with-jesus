# Changelog

All notable changes to the **Deeper with Jesus** app are documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- **Comment system** — full Firestore persistence for comments
  - `PostService.addComment()` writes to `posts/{postId}/comments` subcollection with atomic `commentsCount` increment via batch write
  - `PostService.watchComments()` streams real-time comments ordered by `createdAt` ascending
  - `PostService.deleteComment()` deletes comment with atomic `commentsCount` decrement
  - `commentsProvider` Riverpod family provider keyed by `postId`
  - `CommentSheet` now streams live comments from Firestore instead of receiving a static list
  - Loading spinner on send button while comment is being written to Firestore
  - Error handling with snackbar on failed comment submission
  - Auth guard: guests see "Sign in to comment" prompt, authenticated users see text input
- **Firestore security rules for comments** (`firestore.rules`)
  - Public read on comments subcollection
  - Authenticated create (must match own `userId`)
  - Delete by comment author or admin only
  - Comments are immutable (updates denied)
- **Version-controlled Firestore rules** — `firestore.rules` file added to project root

### Fixed
- **RenderFlex overflow on Admin Dashboard** — reduced padding and sizes across `_StatsOverview` and `_QuickActionButton` widgets to recover ~40px of vertical space, eliminating overflow errors on smaller screens
  - `_StatsOverview` outer padding: `12,8 → 8,4` (top, bottom)
  - `_StatCard` padding: `12,10 → 8,8` (vertical, horizontal); icon `18 → 16`; value font `20 → 18`
  - `_QuickActionButton` padding: `12,8 → 10,8` (vertical, horizontal); icon `20 → 18`; label font `12 → 11`
  - Quick actions section padding: `4,12 → 2,8` (top, bottom)

### Changed
- `CommentSheet` now requires `postId` parameter instead of `List<Comment>` — signature changed from static data to live Firestore stream
- `home_screen.dart` passes `post.id` to `CommentSheet.show()` instead of `null` comments list
- `post_viewer_screen.dart` passes `post.id` to `CommentSheet.show()` instead of `null` comments list
- Updated PRD to reflect Phase 2B status, comments subcollection, security rules, and service methods

---

## [0.2.0] — 2026-03-12 — Phase 2A: Firebase + Authentication

### Added
- **Firebase integration** — Firebase Core, Firestore, Auth, and Storage initialized
- **Google Sign-In** — full OAuth 2.0 flow with Firebase credential exchange
- **Apple Sign-In** — nonce-based OAuth flow (iOS only) with display name persistence
- **Guest mode** — browse-only access with auth prompts on interactive actions
- **AuthService** — `signInWithGoogle()`, `signInWithApple()`, `signOut()`, `authStateChanges`
- **UserService** — `getOrCreateUser()`, `watchUser()`, `updateUser()`, `deleteUser()`, admin email check
- **PostService** — `createPost()`, `updatePost()`, `deletePost()`, `publishPost()`, `uploadPostImage()`, `watchPublishedPosts()`, `watchAllPosts()`, `watchPostForDate()`, `watchPostsByTopic()`
- **Riverpod auth providers** — `firebaseAuthStateProvider`, `appUserProvider`, `isGuestProvider`, `hasSeenOnboardingProvider`
- **Auth-aware GoRouter** — redirect logic for onboarding, welcome, home, and admin routes
- **AuthPromptSheet** — bottom sheet for guest-to-authenticated upgrade from any screen
- **Firebase Storage setup** — `post_images/` path with public read, authenticated write, 10MB limit, image content type validation
- **Firestore security rules** — role-based access: posts (public read, admin write), users (owner CRUD, admin read), admin_emails (auth read, admin write)
- **Firestore composite indexes** — 3 indexes for published posts, topic filtering, and date range queries
- **Admin email whitelist** — `admin_emails` collection for role assignment on first sign-in
- **Onboarding persistence** — `hasSeenOnboarding` flag in SharedPreferences, skip on subsequent launches
- **Profile screen** — real user data from `appUserProvider`, sign out, delete account with confirmation
- **Post image upload** — compress to 1080x1080 JPEG, upload to Firebase Storage, return download URL

### Changed
- `main.dart` — async initialization with Firebase + SharedPreferences
- `app.dart` — replaced hardcoded auth state with real Firebase auth-aware router
- `WelcomeScreen` — wired Google/Apple/Guest buttons to real auth flows
- `OnboardingScreen` — writes SharedPreferences flag on "Go Deeper" tap
- `PostCard` — auth guard on like button (guests see AuthPromptSheet)
- `CommentSheet` — auth guard on comment input (guests see sign-in prompt)
- `ProfileScreen` — real user data, guest state handling, admin section visibility

---

## [0.1.0] — 2026-03-10 — Phase 1: UI Prototype

### Added
- **Home screen** — full-screen daily post card with horizontal PageView navigation
- **Post card** — two rendering modes: uploaded image with caption, and template text on gradient background
- **10 gradient templates** — Mountain Sunrise, Ocean at Dawn, Forest Path, Misty Valley, Golden Wheat Field, Starry Night Sky, Soft Watercolor, Lily Pond, Candle Flame, Desert Sunset
- **Fallback Bible verses** — deterministic verse selection for dates without posts
- **Discover screen** — TabBar with Calendar and Topics views
- **Calendar tab** — monthly calendar with post thumbnail indicators
- **Topics tab** — horizontal chip filter + 2-column post grid
- **Profile screen** — settings, appearance toggle, admin section placeholder
- **Admin dashboard** — stats overview, quick actions, tabbed post list (Published/Scheduled/All)
- **Create post flow** — image upload path and template path with schedule picker
- **Template picker** — grid of 10 templates with preview
- **Text editor screen** — live template preview with text input and topic selection
- **Comment sheet** — bottom sheet UI with empty state and comment input
- **Design system** — purple-violet color palette with full light/dark mode support
- **Navigation** — GoRouter with 3-tab bottom nav (Home, Discover, Profile) + admin routes
- **iOS glass navbar** — frosted glass bottom navigation bar on iOS
- **10 default topics** — Faith, Prayer, Hope, Love, Gratitude, Strength, Peace, Forgiveness, Purpose, Wisdom
