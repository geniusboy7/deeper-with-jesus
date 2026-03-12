import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/devotional_post.dart';

/// A comment paired with the postId it belongs to, so we can target
/// the correct Firestore subcollection when deleting.
class _ModerationComment {
  final Comment comment;
  final String postId;

  const _ModerationComment({required this.comment, required this.postId});
}

class CommentModerationScreen extends StatefulWidget {
  const CommentModerationScreen({super.key});

  @override
  State<CommentModerationScreen> createState() =>
      _CommentModerationScreenState();
}

class _CommentModerationScreenState extends State<CommentModerationScreen> {
  List<_ModerationComment> _comments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAllComments();
  }

  Future<void> _fetchAllComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get all posts that have at least 1 comment
      final postsSnap = await FirebaseFirestore.instance
          .collection('posts')
          .where('commentsCount', isGreaterThan: 0)
          .get();

      final List<_ModerationComment> allComments = [];

      // 2. For each post, fetch its comments subcollection
      for (final postDoc in postsSnap.docs) {
        final commentsSnap = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postDoc.id)
            .collection('comments')
            .orderBy('createdAt', descending: true)
            .get();

        for (final commentDoc in commentsSnap.docs) {
          allComments.add(_ModerationComment(
            comment: Comment.fromFirestore(commentDoc),
            postId: postDoc.id,
          ));
        }
      }

      // Sort all comments by createdAt descending (newest first)
      allComments.sort((a, b) => b.comment.createdAt.compareTo(a.comment.createdAt));

      if (mounted) {
        setState(() {
          _comments = allComments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteComment(_ModerationComment mc) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(mc.postId)
          .collection('comments')
          .doc(mc.comment.id)
          .delete();

      // Decrement the commentsCount on the post document
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(mc.postId)
          .update({'commentsCount': FieldValue.increment(-1)});

      if (mounted) {
        setState(() {
          _comments.removeWhere((c) =>
              c.comment.id == mc.comment.id && c.postId == mc.postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Comment by ${mc.comment.displayName} deleted',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete comment',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showModerationSheet(_ModerationComment mc) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.divider(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    LucideIcons.trash2,
                    color: AppColors.errorLight,
                  ),
                  title: Text(
                    'Delete Comment',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.errorLight,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteComment(mc);
                  },
                ),
                ListTile(
                  leading: Icon(
                    LucideIcons.ban,
                    color: AppColors.textSecondary(context),
                  ),
                  title: Text(
                    'Ban User',
                    style: GoogleFonts.raleway(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  subtitle: Text(
                    mc.comment.displayName,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(mc.comment.userId)
                        .update({'isBanned': true});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${mc.comment.displayName} has been banned',
                          style: GoogleFonts.raleway(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Moderate Comments',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primary(context),
                strokeWidth: 2,
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertTriangle,
                        size: 48,
                        color: AppColors.textSecondary(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load comments',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _fetchAllComments,
                        child: Text(
                          'Retry',
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 48,
                            color: AppColors.textSecondary(context),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments to moderate',
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              color: AppColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAllComments,
                      color: AppColors.primary(context),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final mc = _comments[index];
                          final comment = mc.comment;

                          return Dismissible(
                            key: Key('${mc.postId}_${comment.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) async {
                              await _deleteComment(mc);
                              return false;
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                LucideIcons.trash2,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            child: GestureDetector(
                              onLongPress: () => _showModerationSheet(mc),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Avatar
                                      comment.photoUrl != null
                                          ? CircleAvatar(
                                              radius: 20,
                                              backgroundImage: NetworkImage(
                                                  comment.photoUrl!),
                                              backgroundColor:
                                                  AppColors.primary(context)
                                                      .withValues(alpha: 0.15),
                                            )
                                          : CircleAvatar(
                                              radius: 20,
                                              backgroundColor:
                                                  AppColors.primary(context)
                                                      .withValues(alpha: 0.15),
                                              child: Text(
                                                comment.displayName.isNotEmpty
                                                    ? comment.displayName[0]
                                                        .toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.lora(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary(
                                                      context),
                                                ),
                                              ),
                                            ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    comment.displayName,
                                                    style: GoogleFonts.raleway(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          AppColors.textPrimary(
                                                              context),
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatTimeAgo(
                                                      comment.createdAt),
                                                  style: GoogleFonts.raleway(
                                                    fontSize: 12,
                                                    color:
                                                        AppColors.textSecondary(
                                                            context),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.text,
                                              style: GoogleFonts.raleway(
                                                fontSize: 14,
                                                color: AppColors.textPrimary(
                                                    context),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
