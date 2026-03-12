import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/post_provider.dart';
import 'post_card.dart';
import 'comment_sheet.dart';

/// A full-screen post viewer that opens at a specific date
/// and allows swiping left/right through dates — same UX as the home screen.
class PostViewerScreen extends ConsumerStatefulWidget {
  final DateTime initialDate;

  const PostViewerScreen({super.key, required this.initialDate});

  @override
  ConsumerState<PostViewerScreen> createState() => _PostViewerScreenState();
}

class _PostViewerScreenState extends ConsumerState<PostViewerScreen> {
  static const int _centerPage = 10000;
  late final PageController _pageController;
  late int _currentPage;
  late final DateTime _anchorDate;

  @override
  void initState() {
    super.initState();
    _anchorDate = DateUtils.dateOnly(widget.initialDate);
    _currentPage = _centerPage;
    _pageController = PageController(initialPage: _centerPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _dateForPage(int page) {
    final offset = page - _centerPage;
    return _anchorDate.add(Duration(days: offset));
  }

  bool _canSwipeToPage(int page) {
    final date = _dateForPage(page);
    final today = DateUtils.dateOnly(DateTime.now());
    final maxDate = today.add(const Duration(days: 1));
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

  String _formatDate(DateTime date) {
    final now = DateUtils.dateOnly(DateTime.now());
    final tomorrow = now.add(const Duration(days: 1));
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.isAtSameMomentAs(now)) return 'Today';
    if (date.isAtSameMomentAs(tomorrow)) return 'Tomorrow';
    if (date.isAtSameMomentAs(yesterday)) return 'Yesterday';
    return DateFormat('MMMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = _dateForPage(_currentPage);
    final canGoForward = _canSwipeToPage(_currentPage + 1);

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: Column(
        children: [
          // Top bar with back button + date
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      LucideIcons.arrowLeft,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const Spacer(),
                  // Left arrow
                  GestureDetector(
                    onTap: () => _goToPage(_currentPage - 1),
                    child: Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Date pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.divider(context),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      _formatDate(currentDate),
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
                    onTap: canGoForward ? () => _goToPage(_currentPage + 1) : null,
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: canGoForward
                          ? AppColors.textPrimary(context)
                          : AppColors.textPrimary(context).withValues(alpha: 0.25),
                    ),
                  ),
                  const Spacer(),
                  // Invisible spacer to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Swipeable post cards
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
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
                return _ViewerPostPage(date: date);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Watches Firestore for a post on the given date and renders PostCard.
class _ViewerPostPage extends ConsumerWidget {
  final DateTime date;

  const _ViewerPostPage({required this.date});

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
