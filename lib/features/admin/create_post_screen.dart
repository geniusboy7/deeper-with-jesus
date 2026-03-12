import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/post_provider.dart';
import 'schedule_picker.dart';
import 'template_picker.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _handleUploadImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final postService = ref.read(postServiceProvider);
      final imageUrl = await postService.uploadPostImage(File(image.path));

      if (mounted) {
        setState(() => _isUploading = false);
        // Navigate to schedule picker with the uploaded image URL
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchedulePicker(
              imageUrl: imageUrl,
              caption: _captionController.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload image: $e',
              style: GoogleFonts.raleway(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.likeRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Post',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Two option cards
            Row(
              children: [
                Expanded(
                  child: _OptionCard(
                    icon: LucideIcons.upload,
                    title: 'Upload Image',
                    subtitle: 'Choose from gallery',
                    isLoading: _isUploading,
                    onTap: _isUploading ? null : _handleUploadImage,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _OptionCard(
                    icon: LucideIcons.palette,
                    title: 'Use Template',
                    subtitle: 'Pick a template and add text',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TemplatePicker(
                            caption: _captionController.text,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Caption input
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
                hintText: 'Write a caption for your post...',
                hintStyle: GoogleFonts.raleway(
                  fontSize: 15,
                  color: AppColors.textSecondary(context),
                ),
                filled: true,
                fillColor: AppColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.divider(context),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.divider(context),
                  ),
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
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool isLoading;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary(context).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary(context),
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 28,
                        color: AppColors.primary(context),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                isLoading ? 'Uploading...' : title,
                style: GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isLoading ? 'Please wait' : subtitle,
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  color: AppColors.textSecondary(context),
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
