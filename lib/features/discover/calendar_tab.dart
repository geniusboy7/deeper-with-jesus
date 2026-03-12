import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/templates.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/post_provider.dart';
import '../../shared/widgets/template_background.dart';
import '../home/post_viewer_screen.dart';

class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<DevotionalPost> _getPostsForDay(
      DateTime day, List<DevotionalPost> allPosts) {
    final normalized = _normalizeDate(day);
    return allPosts.where((post) {
      final postDate = _normalizeDate(post.scheduledFor);
      return postDate.isAtSameMomentAs(normalized);
    }).toList();
  }

  void _openPostViewer(DateTime date) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostViewerScreen(initialDate: date),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final postsAsync = ref.watch(publishedPostsProvider);

    final allPosts = postsAsync.value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: AppColors.surface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isDark ? 0 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: TableCalendar<DevotionalPost>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: (day) => _getPostsForDay(day, allPosts),
            calendarFormat: CalendarFormat.month,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.lora(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: AppColors.textSecondary(context),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary(context),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
              weekendStyle: GoogleFonts.raleway(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary(context),
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              defaultTextStyle: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              weekendTextStyle: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary(context),
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary(context),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: GoogleFonts.raleway(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              // Hide default dot markers — we use custom thumbnails
              markersMaxCount: 0,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return null;
                final post = events.first;
                return Positioned(
                  bottom: 2,
                  child: _PostThumbnail(post: post, size: 18),
                );
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              // Open the post viewer at this date
              _openPostViewer(selectedDay);
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
      ),
    );
  }
}

/// Small circular thumbnail showing the post's visual (gradient or image).
class _PostThumbnail extends StatelessWidget {
  final DevotionalPost post;
  final double size;

  const _PostThumbnail({required this.post, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    // Uploaded image post — show network image
    if (post.type == 'uploaded' && post.imageUrl != null) {
      return Image.network(
        post.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _fallbackDot(),
      );
    }

    // Template post — show gradient preview
    if (post.templateId != null) {
      try {
        final template = Templates.all.firstWhere(
          (t) => t.id == post.templateId,
        );
        return TemplateBackground(template: template);
      } catch (_) {
        // Template not found — fall through
      }
    }

    return _fallbackDot();
  }

  Widget _fallbackDot() {
    return Container(color: AppColors.primaryLight);
  }
}
