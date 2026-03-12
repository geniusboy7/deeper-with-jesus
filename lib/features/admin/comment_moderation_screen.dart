import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/devotional_post.dart';

class CommentModerationScreen extends StatefulWidget {
  const CommentModerationScreen({super.key});

  @override
  State<CommentModerationScreen> createState() =>
      _CommentModerationScreenState();
}

class _CommentModerationScreenState extends State<CommentModerationScreen> {
  late List<Comment> _comments;

  @override
  void initState() {
    super.initState();
    // TODO: Replace with Firestore query once comments are wired up.
    _comments = [];
  }

  void _removeComment(int index) {
    final removed = _comments[index];
    setState(() => _comments.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Comment by ${removed.displayName} deleted',
          style: GoogleFonts.raleway(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.gold,
          onPressed: () {
            setState(() => _comments.insert(index, removed));
          },
        ),
      ),
    );
  }

  void _showModerationSheet(Comment comment, int index) {
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
                    _removeComment(index);
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
                    comment.displayName,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${comment.displayName} has been banned',
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
      body: _comments.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return Dismissible(
                  key: Key(comment.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeComment(index),
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
                    onLongPress: () => _showModerationSheet(comment, index),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary(context)
                                  .withValues(alpha: 0.15),
                              child: Text(
                                comment.displayName[0].toUpperCase(),
                                style: GoogleFonts.lora(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary(context),
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
                                      Expanded(
                                        child: Text(
                                          comment.displayName,
                                          style: GoogleFonts.raleway(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                AppColors.textPrimary(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _formatTimeAgo(comment.createdAt),
                                        style: GoogleFonts.raleway(
                                          fontSize: 12,
                                          color:
                                              AppColors.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    comment.text,
                                    style: GoogleFonts.raleway(
                                      fontSize: 14,
                                      color: AppColors.textPrimary(context),
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
    );
  }
}
