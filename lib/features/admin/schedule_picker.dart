import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/default_topics.dart';
import '../../core/constants/templates.dart';
import '../../core/models/devotional_post.dart';
import '../../core/providers/post_provider.dart';

class SchedulePicker extends ConsumerStatefulWidget {
  final TemplateData? template;
  final String textContent;
  final String caption;
  final String? imageUrl; // For uploaded image posts
  final DevotionalPost? existingPost; // Non-null when editing

  const SchedulePicker({
    super.key,
    this.template,
    this.textContent = '',
    this.caption = '',
    this.imageUrl,
    this.existingPost,
  });

  bool get isEditing => existingPost != null;

  @override
  ConsumerState<SchedulePicker> createState() => _SchedulePickerState();
}

class _SchedulePickerState extends ConsumerState<SchedulePicker> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final Set<String> _selectedTopicIds = {};
  late TextEditingController _captionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingPost;
    if (existing != null) {
      _selectedDate = existing.scheduledFor;
      _selectedTime = TimeOfDay(
        hour: existing.scheduledFor.hour,
        minute: existing.scheduledFor.minute,
      );
      _selectedTopicIds.addAll(existing.topicIds);
      _captionController = TextEditingController(text: existing.caption ?? '');
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _captionController = TextEditingController(text: widget.caption);
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: widget.isEditing
          ? DateTime(2020)
          : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary(context),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary(context),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _schedulePost() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final postService = ref.read(postServiceProvider);
      final scheduledFor = _combineDateAndTime();
      final existing = widget.existingPost;

      if (existing != null) {
        // Editing an existing post
        final updated = existing.copyWith(
          caption: _captionController.text.isNotEmpty
              ? _captionController.text
              : null,
          scheduledFor: scheduledFor,
          isPublished: false,
          topicIds: _selectedTopicIds.toList(),
        );
        await postService.updatePost(updated);
      } else {
        // Creating a new post
        final post = DevotionalPost(
          id: '',
          imageUrl: widget.imageUrl,
          templateId: widget.template?.id,
          textContent:
              widget.textContent.isNotEmpty ? widget.textContent : null,
          caption: _captionController.text.isNotEmpty
              ? _captionController.text
              : null,
          scheduledFor: scheduledFor,
          isPublished: false,
          topicIds: _selectedTopicIds.toList(),
          type: widget.imageUrl != null ? 'uploaded' : 'template',
        );
        await postService.createPost(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing != null
                  ? 'Post updated and scheduled for ${DateFormat('MMM d, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}'
                  : 'Post scheduled for ${DateFormat('MMM d, yyyy').format(_selectedDate)} at ${_selectedTime.format(context)}',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to schedule post: $e',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.likeRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _publishNow() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final postService = ref.read(postServiceProvider);
      final existing = widget.existingPost;

      if (existing != null) {
        // Editing: update and publish
        final updated = existing.copyWith(
          caption: _captionController.text.isNotEmpty
              ? _captionController.text
              : null,
          scheduledFor: _combineDateAndTime(),
          isPublished: true,
          topicIds: _selectedTopicIds.toList(),
        );
        await postService.updatePost(updated);
      } else {
        // Creating new and publishing
        final post = DevotionalPost(
          id: '',
          imageUrl: widget.imageUrl,
          templateId: widget.template?.id,
          textContent:
              widget.textContent.isNotEmpty ? widget.textContent : null,
          caption: _captionController.text.isNotEmpty
              ? _captionController.text
              : null,
          scheduledFor: DateTime.now(),
          isPublished: true,
          topicIds: _selectedTopicIds.toList(),
          type: widget.imageUrl != null ? 'uploaded' : 'template',
        );
        await postService.createPost(post);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing != null
                  ? 'Post updated and published!'
                  : 'Post published successfully!',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppColors.primary(context),
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to publish post: $e',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.likeRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Post' : 'Schedule Post',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date picker
            Text(
              'Date',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 20,
                      color: AppColors.primary(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Time picker
            Text(
              'Time',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider(context)),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 20,
                      color: AppColors.primary(context),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime.format(context),
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: AppColors.textSecondary(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Topics
            Text(
              'Topics',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DefaultTopics.topics.map((topic) {
                final isSelected = _selectedTopicIds.contains(topic.id);
                return FilterChip(
                  selected: isSelected,
                  label: Text(topic.name),
                  labelStyle: GoogleFonts.raleway(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : topic.color,
                  ),
                  backgroundColor: topic.color.withValues(alpha: 0.1),
                  selectedColor: topic.color,
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTopicIds.add(topic.id);
                      } else {
                        _selectedTopicIds.remove(topic.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Caption
            Text(
              'Caption',
              style: GoogleFonts.lora(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _captionController,
              maxLines: 3,
              style: GoogleFonts.raleway(
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                hintStyle: GoogleFonts.raleway(
                  fontSize: 15,
                  color: AppColors.textSecondary(context),
                ),
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.divider(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primary(context),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 32),

            // Schedule button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _schedulePost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isEditing ? 'Update Schedule' : 'Schedule Post',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Publish now button
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isSaving ? null : _publishNow,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.isEditing ? 'Update & Publish' : 'Publish Now',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
