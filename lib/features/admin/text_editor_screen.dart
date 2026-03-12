import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/templates.dart';
import '../../shared/widgets/template_background.dart';
import 'schedule_picker.dart';

class TextEditorScreen extends StatefulWidget {
  final TemplateData template;
  final String? caption;

  const TextEditorScreen({
    super.key,
    required this.template,
    this.caption,
  });

  @override
  State<TextEditorScreen> createState() => _TextEditorScreenState();
}

class _TextEditorScreenState extends State<TextEditorScreen> {
  String _text = 'Tap to edit';
  double _fontSize = 32;
  Color _textColor = Colors.white;
  bool _isSerif = true;
  Offset _textPosition = Offset.zero;
  bool _positionInitialized = false;

  final List<Color> _colorOptions = [
    Colors.white,
    const Color(0xFF1C1917),
    AppColors.gold,
  ];

  void _showTextEditDialog() {
    final controller = TextEditingController(
      text: _text == 'Tap to edit' ? '' : _text,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(context),
        title: Text(
          'Enter Text',
          style: GoogleFonts.lora(
            color: AppColors.textPrimary(context),
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          style: GoogleFonts.raleway(
            color: AppColors.textPrimary(context),
          ),
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: GoogleFonts.raleway(
              color: AppColors.textSecondary(context),
            ),
            border: OutlineInputBorder(
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
              if (controller.text.isNotEmpty) {
                setState(() => _text = controller.text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen template background
          TemplateBackground(
            template: widget.template,
            width: double.infinity,
            height: double.infinity,
          ),

          // Draggable text block
          LayoutBuilder(
            builder: (context, constraints) {
              if (!_positionInitialized) {
                _textPosition = Offset(
                  constraints.maxWidth / 2 - 100,
                  constraints.maxHeight / 2 - 40,
                );
                _positionInitialized = true;
              }
              return Stack(
                children: [
                  Positioned(
                    left: _textPosition.dx,
                    top: _textPosition.dy,
                    child: GestureDetector(
                      onTap: _showTextEditDialog,
                      onPanUpdate: (details) {
                        setState(() {
                          _textPosition += details.delta;
                        });
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth - 40,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          _text,
                          style: _isSerif
                              ? GoogleFonts.lora(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                )
                              : GoogleFonts.raleway(
                                  fontSize: _fontSize,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Preview: 1080x1080 render',
                            style: GoogleFonts.raleway(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Preview',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SchedulePicker(
                            template: widget.template,
                            textContent: _text == 'Tap to edit' ? '' : _text,
                            caption: widget.caption ?? '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Next',
                      style: GoogleFonts.raleway(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Font size slider
                  Row(
                    children: [
                      Icon(
                        LucideIcons.type,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_fontSize.round()}',
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.gold,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.2),
                            thumbColor: AppColors.gold,
                            overlayColor: AppColors.gold.withValues(alpha: 0.2),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            min: 16,
                            max: 72,
                            value: _fontSize,
                            onChanged: (v) => setState(() => _fontSize = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Color picker + Font toggle
                  Row(
                    children: [
                      // Color circles
                      ..._colorOptions.map((color) {
                        final isSelected = _textColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _textColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gold
                                    : Colors.white.withValues(alpha: 0.3),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Font toggle
                      _FontToggle(
                        isSerif: _isSerif,
                        onToggle: (v) => setState(() => _isSerif = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontToggle extends StatelessWidget {
  final bool isSerif;
  final ValueChanged<bool> onToggle;

  const _FontToggle({required this.isSerif, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => onToggle(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSerif
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Serif',
                style: GoogleFonts.lora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => onToggle(false),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !isSerif
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Sans',
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
