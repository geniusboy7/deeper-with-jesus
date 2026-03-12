import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/default_topics.dart';
import '../../core/constants/templates.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/post_provider.dart';
import '../../shared/widgets/template_background.dart';
import '../home/post_viewer_screen.dart';

class TopicsTab extends ConsumerStatefulWidget {
  const TopicsTab({super.key});

  @override
  ConsumerState<TopicsTab> createState() => _TopicsTabState();
}

class _TopicsTabState extends ConsumerState<TopicsTab> {
  String? _selectedTopicId;

  @override
  Widget build(BuildContext context) {
    // If a topic is selected, watch posts for that topic.
    // Otherwise, show all published posts.
    final postsAsync = _selectedTopicId != null
        ? ref.watch(postsByTopicProvider(_selectedTopicId!))
        : ref.watch(publishedPostsProvider);

    final posts = postsAsync.value ?? [];

    return Column(
      children: [
        // Topic chips
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: DefaultTopics.topics.length,
            separatorBuilder: (c, i) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final topic = DefaultTopics.topics[index];
              final isSelected = _selectedTopicId == topic.id;

              return FilterChip(
                selected: isSelected,
                label: Text(
                  topic.name,
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : topic.color,
                  ),
                ),
                backgroundColor: topic.color.withValues(alpha: 0.1),
                selectedColor: topic.color,
                side: BorderSide(
                  color: isSelected
                      ? topic.color
                      : topic.color.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    _selectedTopicId = selected ? topic.id : null;
                  });
                },
              );
            },
          ),
        ),

        // Post grid
        Expanded(
          child: posts.isEmpty
              ? Center(
                  child: Text(
                    _selectedTopicId != null
                        ? 'No posts for this topic yet'
                        : 'No posts yet',
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _PostThumbnail(post: post);
                  },
                ),
        ),
      ],
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  final DevotionalPost post;

  const _PostThumbnail({required this.post});

  @override
  Widget build(BuildContext context) {
    // For uploaded image posts, show the image
    if (post.type == 'uploaded' && post.imageUrl != null) {
      return GestureDetector(
        onTap: () => _openPost(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => Container(
                  color: AppColors.primary(context).withValues(alpha: 0.1),
                ),
              ),
              if (post.caption != null && post.caption!.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      post.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Template post
    final template = Templates.all.firstWhere(
      (t) => t.id == post.templateId,
      orElse: () => Templates.all.first,
    );
    final isDarkTemplate = Templates.isDarkTemplate(template);

    return GestureDetector(
      onTap: () => _openPost(context),
      child: TemplateBackground(
        template: template,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                post.textContent ?? '',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDarkTemplate
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.95),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.caption ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.raleway(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostViewerScreen(initialDate: post.scheduledFor),
      ),
    );
  }
}
