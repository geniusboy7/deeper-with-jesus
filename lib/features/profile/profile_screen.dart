import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../app.dart' show themeModeProvider;
import '../../core/providers/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../auth/auth_prompt_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late String _themeMode;

  @override
  void initState() {
    super.initState();
    // Sync local label with actual provider state
    final mode = ref.read(themeModeProvider);
    _themeMode = switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      _ => 'System',
    };
  }

  String _initials(String displayName) {
    final parts = displayName.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return displayName.substring(0, 1).toUpperCase();
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String tempTheme = _themeMode;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return SimpleDialog(
              title: Text(
                'Appearance',
                style: GoogleFonts.lora(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              children: ['Light', 'Dark', 'System'].map((option) {
                final isSelected = tempTheme == option;
                return ListTile(
                  title: Text(
                    option,
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  leading: Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary(context) : AppColors.textSecondary(context),
                  ),
                  onTap: () {
                    setDialogState(() => tempTheme = option);
                    setState(() => _themeMode = option);

                    // Actually apply the theme
                    final mode = switch (option) {
                      'Light' => ThemeMode.light,
                      'Dark' => ThemeMode.dark,
                      _ => ThemeMode.system,
                    };
                    ref.read(themeModeProvider.notifier).set(mode);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Theme set to $option'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      await signOut(ref);
      // Router redirect handles navigation automatically
    } catch (e) {
      if (mounted) {
        _showSnackBar('Sign-out failed. Please try again.');
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
          style: GoogleFonts.raleway(fontSize: 15),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.errorDark
                  : AppColors.errorLight,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      // Delete Firestore user document
      final userService = ref.read(userServiceProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await userService.deleteUser(firebaseUser.uid);
        // Delete the Firebase Auth account
        await firebaseUser.delete();
      }
      // Sign out (clears Google session etc.)
      await signOut(ref);
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to delete account. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firebaseUser = ref.watch(firebaseAuthStateProvider).value;
    final appUserAsync = ref.watch(appUserProvider);
    final appUser = appUserAsync.value;
    final isGuest = firebaseUser == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          // Extra bottom padding so content clears the glass navbar on iOS
          bottom: MediaQuery.of(context).viewPadding.bottom + 80,
        ),
        children: [
          const SizedBox(height: 24),

          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary(context).withValues(alpha: 0.15),
              child: isGuest
                  ? Icon(
                      LucideIcons.user,
                      size: 36,
                      color: AppColors.primary(context),
                    )
                  : Text(
                      _initials(appUser?.displayName ?? 'U'),
                      style: GoogleFonts.lora(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary(context),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Display name
          Center(
            child: Text(
              isGuest ? 'Guest' : (appUser?.displayName ?? 'User'),
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Email (hidden for guests)
          if (!isGuest)
            Center(
              child: Text(
                appUser?.email ?? '',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),

          // Guest sign-in prompt
          if (isGuest) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Sign in to access all features',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () => AuthPromptSheet.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary(context),
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Sign In',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Streak card (signed-in users only)
          if (!isGuest && appUser != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary(context).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    '🔥',
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appUser.appOpens} Devotions Read',
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep going deeper with Jesus',
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 8),

          // Settings section
          _SectionHeader(title: 'Settings'),
          const SizedBox(height: 4),

          // Notifications
          ListTile(
            leading: Icon(LucideIcons.bell, color: AppColors.textSecondary(context), size: 20),
            title: Text(
              'Notify me of new posts',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            trailing: Switch.adaptive(
              value: appUser?.notificationsEnabled ?? true,
              activeTrackColor: AppColors.primary(context),
              onChanged: isGuest
                  ? null
                  : (value) async {
                      // Persist to Firestore
                      final userService = ref.read(userServiceProvider);
                      await userService.updateUserFields(
                        firebaseUser.uid,
                        {'notificationsEnabled': value},
                      );
                      // Subscribe/unsubscribe from FCM topic
                      final notifService =
                          ref.read(notificationServiceProvider);
                      await notifService.handleTopicSubscription(value);
                      if (mounted) {
                        _showSnackBar(
                          value
                              ? 'Notifications enabled'
                              : 'Notifications disabled',
                        );
                      }
                    },
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          ),

          // Appearance
          ListTile(
            leading: Icon(
              isDark ? LucideIcons.moon : LucideIcons.sun,
              color: AppColors.textSecondary(context),
              size: 20,
            ),
            title: Text(
              'Appearance',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            subtitle: Text(
              _themeMode,
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: AppColors.textSecondary(context),
              ),
            ),
            trailing: Icon(
              LucideIcons.chevronRight,
              color: AppColors.textSecondary(context),
              size: 18,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: _showThemeDialog,
          ),

          const Divider(),
          const SizedBox(height: 4),

          // Links section
          ListTile(
            leading: Icon(LucideIcons.instagram, color: AppColors.textSecondary(context), size: 20),
            title: Text(
              'Follow on Instagram',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            trailing: Icon(
              LucideIcons.externalLink,
              color: AppColors.textSecondary(context),
              size: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () => launchUrl(Uri.parse('https://www.instagram.com/deeper_with_jesus/'), mode: LaunchMode.externalApplication),
          ),

          ListTile(
            leading: Icon(LucideIcons.helpCircle, color: AppColors.textSecondary(context), size: 20),
            title: Text(
              'Contact Support',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            trailing: Icon(
              LucideIcons.externalLink,
              color: AppColors.textSecondary(context),
              size: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () => launchUrl(Uri.parse('https://www.instagram.com/deeper_with_jesus/'), mode: LaunchMode.externalApplication),
          ),

          ListTile(
            leading: Icon(LucideIcons.fileText, color: AppColors.textSecondary(context), size: 20),
            title: Text(
              'Privacy Policy',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
            ),
            trailing: Icon(
              LucideIcons.externalLink,
              color: AppColors.textSecondary(context),
              size: 16,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            onTap: () => launchUrl(Uri.parse('https://www.geniustechhub.com/privacy-policy'), mode: LaunchMode.externalApplication),
          ),

          // Admin section (conditional — real user role)
          if (appUser?.isAdmin == true) ...[
            const Divider(),
            const SizedBox(height: 4),
            _SectionHeader(title: 'Admin'),
            const SizedBox(height: 4),

            _AdminTile(
              icon: LucideIcons.layoutDashboard,
              title: 'Dashboard',
              onTap: () => context.push('/admin'),
            ),
            _AdminTile(
              icon: LucideIcons.plusSquare,
              title: 'Create Post',
              onTap: () => context.push('/admin/create'),
            ),
            _AdminTile(
              icon: LucideIcons.tag,
              title: 'Manage Topics',
              onTap: () => context.push('/admin/topics'),
            ),
            _AdminTile(
              icon: LucideIcons.shield,
              title: 'Manage Admins',
              onTap: () => context.push('/admin/admins'),
            ),
          ],

          // Sign out / Delete account (only for signed-in users)
          if (!isGuest) ...[
            const Divider(),
            const SizedBox(height: 4),

            // Sign out
            ListTile(
              leading: Icon(LucideIcons.logOut, color: AppColors.textSecondary(context), size: 20),
              title: Text(
                'Sign Out',
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary(context),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              onTap: _handleSignOut,
            ),

            const SizedBox(height: 48),

            // Delete account
            Center(
              child: GestureDetector(
                onTap: _handleDeleteAccount,
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.errorDark : AppColors.errorLight,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: GoogleFonts.raleway(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary(context),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AdminTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary(context), size: 20),
      title: Text(
        title,
        style: GoogleFonts.raleway(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary(context),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        color: AppColors.textSecondary(context),
        size: 18,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
    );
  }
}
