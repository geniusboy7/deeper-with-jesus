import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/templates.dart';
import '../../shared/widgets/template_background.dart';
import 'text_editor_screen.dart';

class TemplatePicker extends StatefulWidget {
  final String? caption;

  const TemplatePicker({super.key, this.caption});

  @override
  State<TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<TemplatePicker> {
  final List<TemplateData> _customTemplates = [];
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _uploadCustomTemplate() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 90,
    );

    if (image != null) {
      final template = TemplateData(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Custom Template',
        imagePath: image.path,
      );
      setState(() {
        _customTemplates.add(template);
      });
    }
  }

  void _deleteCustomTemplate(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Delete Template',
          style: GoogleFonts.lora(
            color: AppColors.textPrimary(context),
          ),
        ),
        content: Text(
          'Remove this custom template?',
          style: GoogleFonts.raleway(
            color: AppColors.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.raleway(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _customTemplates.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.likeRed,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToEditor(TemplateData template) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TextEditorScreen(
          template: template,
          caption: widget.caption,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Total items: 1 upload card + custom templates + built-in templates
    final totalItems = 1 + _customTemplates.length + Templates.all.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Template',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          // First card: Upload button
          if (index == 0) {
            return _UploadCard(onTap: _uploadCustomTemplate);
          }

          // Custom templates
          final customIndex = index - 1;
          if (customIndex < _customTemplates.length) {
            final template = _customTemplates[customIndex];
            return _CustomTemplateGridItem(
              template: template,
              onTap: () => _navigateToEditor(template),
              onLongPress: () => _deleteCustomTemplate(customIndex),
            );
          }

          // Built-in templates
          final builtInIndex = customIndex - _customTemplates.length;
          final template = Templates.all[builtInIndex];
          return _TemplateGridItem(
            template: template,
            onTap: () => _navigateToEditor(template),
          );
        },
      ),
    );
  }
}

// ── Upload Card ─────────────────────────────────────────────────────────────

class _UploadCard extends StatelessWidget {
  final VoidCallback onTap;

  const _UploadCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary(context).withValues(alpha: 0.4),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                color: AppColors.primary(context).withValues(alpha: 0.06),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary(context).withValues(alpha: 0.12),
                    ),
                    child: Icon(
                      LucideIcons.plus,
                      size: 24,
                      color: AppColors.primary(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload',
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Custom Template',
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Custom Template Grid Item ───────────────────────────────────────────────

class _CustomTemplateGridItem extends StatelessWidget {
  final TemplateData template;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CustomTemplateGridItem({
    required this.template,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(template.imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                // Custom badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary(context),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Custom',
                      style: GoogleFonts.raleway(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            template.name,
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Built-in Template Grid Item ─────────────────────────────────────────────

class _TemplateGridItem extends StatelessWidget {
  final TemplateData template;
  final VoidCallback onTap;

  const _TemplateGridItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: TemplateBackground(
                template: template,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            template.name,
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
