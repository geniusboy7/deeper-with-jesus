import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/templates.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/post_provider.dart';
import '../../shared/widgets/template_background.dart';
import 'create_post_screen.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<DevotionalPost> _filteredPosts(
      int tabIndex, List<DevotionalPost> allPosts) {
    switch (tabIndex) {
      case 0: // Published
        return allPosts.where((p) => p.isPublished).toList();
      case 1: // Scheduled
        return allPosts.where((p) => !p.isPublished).toList();
      default: // All
        return allPosts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(allPostsProvider);
    final allPosts = postsAsync.value ?? [];

    final totalLikes = allPosts.fold<int>(0, (sum, p) => sum + p.likesCount);
    final totalViews = allPosts.fold<int>(0, (sum, p) => sum + p.viewsCount);
    final totalComments =
        allPosts.fold<int>(0, (sum, p) => sum + p.commentsCount);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              LucideIcons.bell,
              color: AppColors.primary(context),
              size: 22,
            ),
            tooltip: 'Send Notification',
            onPressed: () => context.push('/admin/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats overview section
          _StatsOverview(
            totalPosts: allPosts.length,
            publishedPosts:
                allPosts.where((p) => p.isPublished).length,
            scheduledPosts:
                allPosts.where((p) => !p.isPublished).length,
            totalViews: totalViews,
            totalLikes: totalLikes,
            totalComments: totalComments,
          ),

          // Quick actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.send,
                    label: 'Send\nNotification',
                    onTap: () => context.push('/admin/notifications'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.plusSquare,
                    label: 'Create\nPost',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CreatePostScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    icon: LucideIcons.messageCircle,
                    label: 'Moderate\nComments',
                    onTap: () => context.push('/admin/comments'),
                  ),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            labelColor: AppColors.primary(context),
            unselectedLabelColor: AppColors.textSecondary(context),
            indicatorColor: AppColors.primary(context),
            labelStyle: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'Published'),
              Tab(text: 'Scheduled'),
              Tab(text: 'All'),
            ],
          ),

          // Post list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (tabIndex) {
                final posts = _filteredPosts(tabIndex, allPosts);
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.fileText,
                          size: 48,
                          color: AppColors.textSecondary(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No posts yet',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            color: AppColors.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return _PostCard(post: posts[index]);
                  },
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          );
        },
        backgroundColor: AppColors.primary(context),
        child: Icon(
          LucideIcons.plus,
          color: isDark ? AppColors.backgroundDark : AppColors.white,
        ),
      ),
    );
  }
}

// ── Stats Overview ──────────────────────────────────────────────────────────

class _StatsOverview extends StatelessWidget {
  final int totalPosts;
  final int publishedPosts;
  final int scheduledPosts;
  final int totalViews;
  final int totalLikes;
  final int totalComments;

  const _StatsOverview({
    required this.totalPosts,
    required this.publishedPosts,
    required this.scheduledPosts,
    required this.totalViews,
    required this.totalLikes,
    required this.totalComments,
  });

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Posts row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.fileText,
                  label: 'Total Posts',
                  value: _formatCount(totalPosts),
                  color: AppColors.primary(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.checkCircle,
                  label: 'Published',
                  value: _formatCount(publishedPosts),
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.clock,
                  label: 'Scheduled',
                  value: _formatCount(scheduledPosts),
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Engagement row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.eye,
                  label: 'Views',
                  value: _formatCount(totalViews),
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.heart,
                  label: 'Likes',
                  value: _formatCount(totalLikes),
                  color: AppColors.likeRed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.messageCircle,
                  label: 'Comments',
                  value: _formatCount(totalComments),
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Quick Action Button ─────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary(context).withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primary(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.raleway(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Post Card ───────────────────────────────────────────────────────────────

class _PostCard extends StatelessWidget {
  final DevotionalPost post;

  const _PostCard({required this.post});

  TemplateData? _getTemplate() {
    if (post.templateId == null) return null;
    try {
      return Templates.all.firstWhere((t) => t.id == post.templateId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = _getTemplate();
    final dateStr = DateFormat('MMM d, yyyy').format(post.scheduledFor);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildThumbnail(context, template),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          post.textContent ?? post.caption ?? 'Untitled',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(isPublished: post.isPublished),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stats row
                  Row(
                    children: [
                      _StatChip(
                        icon: LucideIcons.eye,
                        count: post.viewsCount,
                        context: context,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: LucideIcons.heart,
                        count: post.likesCount,
                        context: context,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: LucideIcons.messageCircle,
                        count: post.commentsCount,
                        context: context,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context, TemplateData? template) {
    // Uploaded image post — show network thumbnail
    if (post.type == 'uploaded' && post.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          post.imageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              LucideIcons.image,
              color: AppColors.primary(context),
              size: 24,
            ),
          ),
        ),
      );
    }

    // Template post
    if (template != null) {
      return TemplateBackground(
        template: template,
        width: 60,
        height: 60,
      );
    }

    // Fallback
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primary(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        LucideIcons.image,
        color: AppColors.primary(context),
        size: 24,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isPublished;

  const _StatusBadge({required this.isPublished});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFF10B981).withValues(alpha: 0.15)
            : const Color(0xFFF97316).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isPublished ? 'Published' : 'Scheduled',
        style: GoogleFonts.raleway(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isPublished
              ? const Color(0xFF10B981)
              : const Color(0xFFF97316),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final BuildContext context;

  const _StatChip({
    required this.icon,
    required this.count,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: AppColors.textSecondary(context),
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: GoogleFonts.raleway(
            fontSize: 12,
            color: AppColors.textSecondary(context),
          ),
        ),
      ],
    );
  }
}
