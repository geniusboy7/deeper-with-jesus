import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      headline: 'A Word for Every Day',
      body:
          'Each day brings a fresh devotional \u2014 crafted to encourage, '
          'challenge, and draw you closer to God. Swipe through today\u2019s '
          'post or revisit past words whenever you need them.',
    ),
    _SlideData(
      headline: 'Explore What Speaks to You',
      body:
          'Browse by calendar or topic \u2014 from faith and prayer to love '
          'and forgiveness. Find the exact word God has for your season.',
    ),
    _SlideData(
      headline: 'Built for Your Walk',
      body:
          'Like posts that move you, share them with friends, and join a '
          'community growing deeper together. Your daily quiet time, reimagined.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctaColor = isDark ? AppColors.ctaGoldDark : AppColors.ctaGoldLight;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),

            // App logo
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icons/app_logo.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 16),

            // App title
            Text(
              'Deeper with Jesus',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary(context),
              ),
            ),

            // Slide content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide.headline,
                          style: GoogleFonts.lora(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            slide.body,
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary(context),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (index) {
                final isActive = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: isActive ? 8 : 6,
                  height: isActive ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? AppColors.primary(context)
                        : AppColors.primary(context).withValues(alpha: 0.3),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Go Deeper button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('hasSeenOnboarding', true);
                    ref.read(hasSeenOnboardingProvider.notifier).set(true);
                    if (context.mounted) context.go('/welcome');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ctaColor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Go Deeper',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String headline;
  final String body;

  const _SlideData({required this.headline, required this.body});
}
