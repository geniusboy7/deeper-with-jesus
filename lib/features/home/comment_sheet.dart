import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
import '../auth/auth_prompt_sheet.dart';

class CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  final int likesCount;

  const CommentSheet({
    super.key,
    required this.postId,
    this.likesCount = 0,
  });

  static void show(BuildContext context, {required String postId, int likesCount = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => CommentSheet(
          postId: postId,
          likesCount: likesCount,
        ),
      ),
    );
  }

  @override
  ConsumerState<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<CommentSheet> {
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Get the current user's initial for the avatar, or '?' for guests.
  String get _userInitial {
    final appUser = ref.read(appUserProvider).value;
    if (appUser != null && appUser.displayName.isNotEmpty) {
      return appUser.displayName[0].toUpperCase();
    }
    return '?';
  }

  /// Whether the current user is a guest (not signed in).
  bool get _isGuest {
    final firebaseUser = ref.read(firebaseAuthStateProvider).value;
    return firebaseUser == null;
  }

  Future<void> _handleSend() async {
    // Auth guard: guests must sign in before commenting
    if (_isGuest) {
      AuthPromptSheet.show(context);
      return;
    }

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Enforce maximum comment length
    if (text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment is too long (max 500 characters)')),
      );
      return;
    }

    final appUser = ref.read(appUserProvider).value;
    if (appUser == null) return;

    // Prevent banned users from commenting
    if (appUser.isBanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has been suspended')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await ref.read(postServiceProvider).addComment(
            postId: widget.postId,
            userId: appUser.uid,
            displayName: appUser.displayName,
            photoUrl: appUser.photoUrl,
            text: text,
          );
      _textController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Watch auth state so UI rebuilds when user signs in
    final firebaseUser = ref.watch(firebaseAuthStateProvider).value;
    final isGuest = firebaseUser == null;

    // Watch real-time comments from Firestore
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final comments = commentsAsync.value ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Comments',
                  style: GoogleFonts.lora(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${comments.length}',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Comments list
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.messageCircle,
                          size: 48,
                          color: AppColors.divider(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No comments yet',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share your thoughts',
                          style: GoogleFonts.raleway(
                            fontSize: 14,
                            color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: comments.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _CommentItem(comment: comment);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary(context),
                  strokeWidth: 2,
                ),
              ),
              error: (e, s) => Center(
                child: Text(
                  'Failed to load comments',
                  style: GoogleFonts.raleway(
                    fontSize: 14,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ),
            ),
          ),

          // Input area — show sign-in prompt for guests, text input for signed-in users
          if (isGuest)
            _buildGuestPrompt(context)
          else
            _buildCommentInput(context, isDark),
        ],
      ),
    );
  }

  Widget _buildGuestPrompt(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.divider(context)),
        ),
      ),
      child: GestureDetector(
        onTap: () => AuthPromptSheet.show(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.logIn,
              size: 18,
              color: AppColors.primary(context),
            ),
            const SizedBox(width: 8),
            Text(
              'Sign in to comment',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 8,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.divider(context)),
        ),
      ),
      child: Row(
        children: [
          // Avatar — real user initial
          CircleAvatar(
            radius: 16,
            backgroundColor: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            child: Text(
              _userInitial,
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              maxLength: 500,
              maxLines: null,
              buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
              style: GoogleFonts.raleway(
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: GoogleFonts.raleway(
                  fontSize: 15,
                  color: AppColors.textSecondary(context).withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          // Send button
          _isSending
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: _handleSend,
                  icon: Icon(
                    LucideIcons.send,
                    size: 20,
                    color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
                  ),
                ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;

  const _CommentItem({required this.comment});

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: (isDark ? AppColors.secondaryDark : AppColors.secondaryLight)
              .withValues(alpha: 0.3),
          child: Text(
            comment.displayName.isNotEmpty
                ? comment.displayName[0].toUpperCase()
                : '?',
            style: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.displayName,
                    style: GoogleFonts.raleway(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _timeAgo(comment.createdAt),
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: AppColors.textSecondary(context).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: AppColors.textPrimary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
