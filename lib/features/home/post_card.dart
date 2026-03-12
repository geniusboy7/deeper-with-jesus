import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/templates.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/post_provider.dart';
import '../../shared/widgets/template_background.dart';
import '../auth/auth_prompt_sheet.dart';

/// Inline fallback verses used when BibleVerses class is not yet available.
const List<Map<String, String>> _fallbackVerses = [
  {
    'text': 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.',
    'reference': 'Jeremiah 29:11',
  },
  {
    'text': 'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters.',
    'reference': 'Psalm 23:1-2',
  },
  {
    'text': 'Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.',
    'reference': 'Joshua 1:9',
  },
  {
    'text': 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to Him, and He will make your paths straight.',
    'reference': 'Proverbs 3:5-6',
  },
  {
    'text': 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary.',
    'reference': 'Isaiah 40:31',
  },
];

class PostCard extends ConsumerStatefulWidget {
  final DevotionalPost? post;
  final DateTime date;
  final VoidCallback? onCommentTap;

  const PostCard({
    super.key,
    this.post,
    required this.date,
    this.onCommentTap,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLiked = false;
  late int _likeCount;
  bool _isLiking = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post?.likesCount ?? 0;
    _checkInitialLikeState();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post?.id != widget.post?.id) {
      _likeCount = widget.post?.likesCount ?? 0;
      _checkInitialLikeState();
    } else {
      // Update count from Firestore but keep local like state
      _likeCount = widget.post?.likesCount ?? 0;
    }
  }

  Future<void> _checkInitialLikeState() async {
    final firebaseUser = ref.read(firebaseAuthStateProvider).value;
    final post = widget.post;
    if (firebaseUser == null || post == null) {
      _isLiked = false;
      return;
    }
    final liked = await ref.read(postServiceProvider).hasUserLiked(
          postId: post.id,
          userId: firebaseUser.uid,
        );
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _toggleLike() async {
    // Auth guard: guests must sign in before liking
    final firebaseUser = ref.read(firebaseAuthStateProvider).value;
    if (firebaseUser == null) {
      AuthPromptSheet.show(context);
      return;
    }

    final post = widget.post;
    if (post == null || _isLiking) return;

    // Optimistic UI update
    setState(() {
      _isLiking = true;
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await ref.read(postServiceProvider).toggleLike(
            postId: post.id,
            userId: firebaseUser.uid,
          );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  void _showShareSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share coming soon',
          style: GoogleFonts.raleway(),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.post != null) {
      return _buildPublishedPost(widget.post!);
    }
    return _buildFallbackPost();
  }

  Widget _buildPublishedPost(DevotionalPost post) {
    if (post.type == 'uploaded' && post.imageUrl != null) {
      return _buildUploadedPost(post);
    }
    return _buildTemplatePost(post);
  }

  Widget _buildUploadedPost(DevotionalPost post) {
    return Column(
      children: [
        // Scrollable content area
        Expanded(
          child: SingleChildScrollView(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Square image
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.network(
                      post.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.surface(context),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.primary(context),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary(context).withValues(alpha: 0.1),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.image,
                                  size: 48,
                                  color: AppColors.primary(context).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Image unavailable',
                                  style: GoogleFonts.raleway(
                                    fontSize: 14,
                                    color: AppColors.textSecondary(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Caption
                  if (post.caption != null && post.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Text(
                        post.caption!,
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textPrimary(context),
                          height: 1.5,
                        ),
                      ),
                    ),

                  // Topic chips
                  if (post.topicIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: post.topicIds.map((topic) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary(context).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '#${topic[0].toUpperCase()}${topic.substring(1)}',
                              style: GoogleFonts.raleway(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary(context),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Action bar
        _buildActionBar(post),
      ],
    );
  }

  Widget _buildTemplatePost(DevotionalPost post) {
    // Resolve the template
    TemplateData template = Templates.all.firstWhere(
      (t) => t.id == post.templateId,
      orElse: () => Templates.getTemplateForDate(widget.date),
    );

    final isDark = Templates.isDarkTemplate(template);
    final textColor = isDark ? Colors.white : Colors.black87;

    return Column(
      children: [
        // Gradient area with text content
        Expanded(
          child: TemplateBackground(
            template: template,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Main text content
                    if (post.textContent != null && post.textContent!.isNotEmpty)
                      Text(
                        post.textContent!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lora(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    const Spacer(flex: 2),
                    // Caption below the main visual area
                    if (post.caption != null && post.caption!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          post.caption!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: textColor.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action bar
        _buildActionBar(post),
      ],
    );
  }

  Widget _buildActionBar(DevotionalPost post) {
    return Container(
      color: AppColors.surface(context),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Like button
            _ActionButton(
              icon: _isLiked ? LucideIcons.heart : LucideIcons.heart,
              filled: _isLiked,
              filledColor: AppColors.likeRed,
              label: _likeCount > 0 ? '$_likeCount' : '',
              onTap: _toggleLike,
            ),
            const SizedBox(width: 24),
            // Comment button
            _ActionButton(
              icon: LucideIcons.messageCircle,
              label: post.commentsCount > 0 ? '${post.commentsCount}' : '',
              onTap: widget.onCommentTap,
            ),
            const Spacer(),
            // Share button
            _ActionButton(
              icon: LucideIcons.share2,
              onTap: _showShareSnackbar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPost() {
    final template = Templates.getTemplateForDate(widget.date);
    final dayIndex = widget.date.difference(DateTime(2020, 1, 1)).inDays;
    final verse = _fallbackVerses[dayIndex.abs() % _fallbackVerses.length];

    return TemplateBackground(
      template: template,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Text(
                verse['text']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                verse['reference']!,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool filled;
  final Color? filledColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    this.label,
    this.filled = false,
    this.filledColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = AppColors.textPrimary(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: filled ? (filledColor ?? defaultColor) : defaultColor,
          ),
          if (label != null && label!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label!,
              style: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: filled ? (filledColor ?? defaultColor) : defaultColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
