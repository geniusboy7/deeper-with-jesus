import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  bool get _isIOS {
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await signInWithGoogle(ref);
      // Router redirect handles navigation to /home
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${_friendlyError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await signInWithApple(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: ${_friendlyError(e)}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuestContinue() {
    continueAsGuest(ref);
    // Router redirect handles navigation to /home
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    debugPrint('Sign-in error: $msg');
    if (msg.contains('sign-in-cancelled') || msg.contains('canceled')) {
      return 'Sign-in cancelled';
    }
    return msg.length > 100 ? 'Please try again' : msg;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        const Color(0xFF2D1B4E),
                        AppColors.backgroundDark,
                      ]
                    : [
                        AppColors.primaryLight,
                        const Color(0xFFE9D5FF),
                      ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),

                      // Cross icon
                      Icon(
                        LucideIcons.cross,
                        size: 48,
                        color: isDark
                            ? AppColors.secondaryDark.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.8),
                      ),

                      const SizedBox(height: 24),

                      // App name
                      Text(
                        'Deeper with Jesus',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? AppColors.textPrimaryDark : Colors.white,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tagline
                      Text(
                        'Daily devotionals to deepen\nyour walk with God',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : Colors.white.withValues(alpha: 0.9),
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Continue with Apple (iOS only)
                      if (_isIOS) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _handleAppleSignIn,
                            icon: const Icon(Icons.apple, size: 22),
                            label: Text(
                              'Continue with Apple',
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.black,
                              foregroundColor: AppColors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Continue with Google
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              _isLoading ? null : _handleGoogleSignIn,
                          icon: Text(
                            'G',
                            style: GoogleFonts.raleway(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          label: Text(
                            'Continue with Google',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                isDark ? AppColors.surfaceDark : AppColors.white,
                            foregroundColor: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.dividerDark
                                  : AppColors.dividerLight,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Continue as Guest
                      GestureDetector(
                        onTap: _isLoading ? null : _handleGuestContinue,
                        child: Text(
                          'Continue as Guest',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.white.withValues(alpha: 0.8),
                            decoration: TextDecoration.underline,
                            decorationColor: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),

                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
