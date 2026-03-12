import 'dart:io' show Platform;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';

import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/templates.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/notification_provider.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/home/home_screen.dart';
import 'features/discover/discover_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/admin/admin_dashboard.dart';
import 'features/admin/create_post_screen.dart';
import 'features/admin/template_picker.dart';
import 'features/admin/text_editor_screen.dart';
import 'features/admin/schedule_picker.dart';
import 'features/admin/comment_moderation_screen.dart';
import 'features/admin/manage_admins_screen.dart';
import 'features/admin/manage_topics_screen.dart';
import 'features/admin/send_notification_screen.dart';
import 'features/home/post_viewer_screen.dart';

// ---------------------------------------------------------------------------
// Theme mode provider
// ---------------------------------------------------------------------------
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

// ---------------------------------------------------------------------------
// GoRouter ↔ Riverpod bridge
// ---------------------------------------------------------------------------

/// A ChangeNotifier that fires whenever the Firebase auth state or guest
/// flag changes, so GoRouter re-evaluates its redirect.
class _AuthNotifier extends ChangeNotifier {
  late final ProviderSubscription<AsyncValue<User?>> _authSub;
  late final ProviderSubscription<bool> _guestSub;
  late final ProviderSubscription<bool> _onboardingSub;

  _AuthNotifier(Ref ref) {
    _authSub = ref.listen(firebaseAuthStateProvider, (_, _) {
      notifyListeners();
    });
    _guestSub = ref.listen(isGuestProvider, (_, _) {
      notifyListeners();
    });
    _onboardingSub = ref.listen(hasSeenOnboardingProvider, (_, _) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSub.close();
    _guestSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  ref.onDispose(() => authNotifier.dispose());

  final router = GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(firebaseAuthStateProvider);
      final isGuest = ref.read(isGuestProvider);
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
      final isLoggedIn = authState.value != null;
      final location = state.matchedLocation;

      final isOnAuthPage =
          location == '/onboarding' || location == '/welcome';

      // Not authenticated and not guest → show onboarding or welcome
      if (!isLoggedIn && !isGuest) {
        if (!hasSeenOnboarding && location != '/onboarding') {
          return '/onboarding';
        }
        if (hasSeenOnboarding && !isOnAuthPage) {
          return '/welcome';
        }
        return null; // stay on current auth page
      }

      // Authenticated or guest → redirect away from auth pages
      if (isOnAuthPage) {
        return '/home';
      }

      // Admin route protection
      if (location.startsWith('/admin')) {
        final appUser = ref.read(appUserProvider).value;
        if (appUser == null || !appUser.isAdmin) {
          return '/home';
        }
      }

      return null; // no redirect
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/discover',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      // Admin routes (outside shell — full screen)
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/admin/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/admin/templates',
        builder: (context, state) => const TemplatePicker(),
      ),
      GoRoute(
        path: '/admin/editor',
        builder: (context, state) {
          final template = state.extra as TemplateData? ?? Templates.all.first;
          return TextEditorScreen(template: template);
        },
      ),
      GoRoute(
        path: '/admin/schedule',
        builder: (context, state) => const SchedulePicker(),
      ),
      GoRoute(
        path: '/admin/comments',
        builder: (context, state) => const CommentModerationScreen(),
      ),
      GoRoute(
        path: '/admin/admins',
        builder: (context, state) => const ManageAdminsScreen(),
      ),
      GoRoute(
        path: '/admin/topics',
        builder: (context, state) => const ManageTopicsScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) => const SendNotificationScreen(),
      ),
      // Deep link route for notification taps
      GoRoute(
        path: '/post/:postId',
        builder: (context, state) {
          final dateStr = state.uri.queryParameters['date'];
          final date = dateStr != null
              ? DateTime.tryParse(dateStr) ?? DateTime.now()
              : DateTime.now();
          return PostViewerScreen(initialDate: date);
        },
      ),
    ],
  );

  // Attach router to notification service for deep linking
  final notifService = ref.read(notificationServiceProvider);
  notifService.setRouter(router);

  return router;
});

// ---------------------------------------------------------------------------
// App widget
// ---------------------------------------------------------------------------

class DeeperWithJesusApp extends ConsumerWidget {
  const DeeperWithJesusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    // Auto-initialize notifications when user signs in
    ref.watch(notificationInitProvider);

    return MaterialApp.router(
      title: 'Deeper with Jesus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

// ---------------------------------------------------------------------------
// Main shell (bottom nav)
// ---------------------------------------------------------------------------

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const _paths = ['/home', '/discover', '/profile'];

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
    final inactiveColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      extendBody: _isIOS,
      body: widget.child,
      bottomNavigationBar: _isIOS
          ? NativeGlassNavBar(
              currentIndex: _currentIndex,
              onTap: _onTap,
              tintColor: activeColor,
              tabs: const [
                NativeGlassNavBarItem(label: 'Home', symbol: 'house.fill'),
                NativeGlassNavBarItem(label: 'Discover', symbol: 'safari.fill'),
                NativeGlassNavBarItem(label: 'Profile', symbol: 'person.fill'),
              ],
              fallback: _buildMaterialNavBar(activeColor, inactiveColor),
            )
          : _buildMaterialNavBar(activeColor, inactiveColor),
    );
  }

  Widget _buildMaterialNavBar(Color activeColor, Color inactiveColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: LucideIcons.home,
                label: 'Home',
                isActive: _currentIndex == 0,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onTap(0),
              ),
              _NavItem(
                icon: LucideIcons.compass,
                label: 'Discover',
                isActive: _currentIndex == 1,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onTap(1),
              ),
              _NavItem(
                icon: LucideIcons.user,
                label: 'Profile',
                isActive: _currentIndex == 2,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                onTap: () => _onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(int index) {
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
      context.go(_paths[index]);
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.raleway(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
