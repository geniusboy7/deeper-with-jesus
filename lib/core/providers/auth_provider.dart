import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/devotional_post.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

// -----------------------------------------------------------------------------
// Service singletons
// -----------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final userServiceProvider = Provider<UserService>((ref) => UserService());

// -----------------------------------------------------------------------------
// Auth state
// -----------------------------------------------------------------------------

/// Raw Firebase auth state stream (User or null).
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Whether the user chose "Continue as Guest" (browsing without sign-in).
final isGuestProvider = NotifierProvider<IsGuestNotifier, bool>(
  IsGuestNotifier.new,
);

class IsGuestNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Whether the user has seen the onboarding slides.
/// Initialized from SharedPreferences in main.dart via ProviderScope override.
final hasSeenOnboardingProvider =
    NotifierProvider<HasSeenOnboardingNotifier, bool>(
  HasSeenOnboardingNotifier.new,
);

class HasSeenOnboardingNotifier extends Notifier<bool> {
  final bool _initialValue;

  HasSeenOnboardingNotifier([this._initialValue = false]);

  @override
  bool build() => _initialValue;

  void set(bool value) => state = value;
}

// -----------------------------------------------------------------------------
// App user from Firestore
// -----------------------------------------------------------------------------

/// The full AppUser document from Firestore. Null when not signed in.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return ref.watch(userServiceProvider).watchUser(firebaseUser.uid);
    },
    loading: () => Stream.value(null),
    error: (_, _) => Stream.value(null),
  );
});

// -----------------------------------------------------------------------------
// Auth actions (accept WidgetRef so they work from UI code)
// -----------------------------------------------------------------------------

/// Sign in with Google, then ensure Firestore user doc exists.
Future<AppUser> signInWithGoogle(WidgetRef ref) async {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);

  final credential = await authService.signInWithGoogle();
  final appUser = await userService.getOrCreateUser(credential.user!);

  ref.read(isGuestProvider.notifier).set(false);
  return appUser;
}

/// Sign in with Apple, then ensure Firestore user doc exists.
Future<AppUser> signInWithApple(WidgetRef ref) async {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);

  final credential = await authService.signInWithApple();
  final appUser = await userService.getOrCreateUser(credential.user!);

  ref.read(isGuestProvider.notifier).set(false);
  return appUser;
}

/// Enter guest mode (no Firebase Auth, browsing only).
void continueAsGuest(WidgetRef ref) {
  ref.read(isGuestProvider.notifier).set(true);
}

/// Sign out and reset guest flag.
Future<void> signOut(WidgetRef ref) async {
  await ref.read(authServiceProvider).signOut();
  ref.read(isGuestProvider.notifier).set(false);
}
