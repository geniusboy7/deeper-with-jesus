import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/post_provider.dart';
import 'post_card.dart';
import 'comment_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const int _initialPage = 10000;
  late final PageController _pageController;
  late int _currentPage;
  final DateTime _today = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage;
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Convert a page index to a date. _initialPage = today.
  DateTime _dateForPage(int page) {
    final offset = page - _initialPage;
    return _today.add(Duration(days: offset));
  }

  /// How far into the future the user can swipe (1 day max).
  bool _canSwipeToPage(int page) {
    final date = _dateForPage(page);
    final maxDate = _today.add(const Duration(days: 1));
    return !date.isAfter(maxDate);
  }

  void _goToPage(int page) {
    if (!_canSwipeToPage(page)) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = _dateForPage(_currentPage);
    final canGoForward = _canSwipeToPage(_currentPage + 1);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          // Date indicator bar
          _DateIndicator(
            date: currentDate,
            canGoBack: true,
            canGoForward: canGoForward,
            onBack: () => _goToPage(_currentPage - 1),
            onForward: () => _goToPage(_currentPage + 1),
          ),

          // PageView of PostCards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                // Prevent swiping beyond tomorrow
                if (!_canSwipeToPage(page)) {
                  _pageController.animateToPage(
                    _currentPage,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                  );
                  return;
                }
                setState(() => _currentPage = page);
              },
              itemBuilder: (context, index) {
                final date = _dateForPage(index);
                return _PostPageForDate(date: date);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Watches Firestore for a post on the given date and renders PostCard.
class _PostPageForDate extends ConsumerWidget {
  final DateTime date;

  const _PostPageForDate({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postForDateProvider(date));

    return postAsync.when(
      data: (post) {
        return PostCard(
          post: post,
          date: date,
          onCommentTap: () {
            if (post != null) {
              CommentSheet.show(
                context,
                postId: post.id,
                likesCount: post.likesCount,
              );
            }
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(
          color: AppColors.primary(context),
          strokeWidth: 2,
        ),
      ),
      error: (e, s) => PostCard(
        post: null,
        date: date,
      ),
    );
  }
}

class _DateIndicator extends StatelessWidget {
  final DateTime date;
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _DateIndicator({
    required this.date,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
  });

  String _formatDate(DateTime date) {
    final now = DateUtils.dateOnly(DateTime.now());
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    String label;
    if (date.isAtSameMomentAs(now)) {
      label = 'Today';
    } else if (date.isAtSameMomentAs(tomorrow)) {
      label = 'Tomorrow';
    } else if (date.isAtSameMomentAs(yesterday)) {
      label = 'Yesterday';
    } else {
      label = DateFormat('MMMM d, y').format(date);
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left arrow
            GestureDetector(
              onTap: canGoBack ? onBack : null,
              child: Icon(
                LucideIcons.chevronLeft,
                size: 20,
                color: canGoBack
                    ? AppColors.textPrimary(context)
                    : AppColors.textPrimary(context).withValues(alpha: 0.25),
              ),
            ),
            const SizedBox(width: 8),

            // Date pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.divider(context),
                  width: 1,
                ),
              ),
              child: Text(
                _formatDate(date),
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
            ),

            const SizedBox(width: 8),
            // Right arrow
            GestureDetector(
              onTap: canGoForward ? onForward : null,
              child: Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: canGoForward
                    ? AppColors.textPrimary(context)
                    : AppColors.textPrimary(context).withValues(alpha: 0.25),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
