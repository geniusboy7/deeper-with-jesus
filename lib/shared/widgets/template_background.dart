import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/templates.dart';

class TemplateBackground extends StatelessWidget {
  final TemplateData template;
  final Widget? child;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const TemplateBackground({
    super.key,
    required this.template,
    this.child,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // Custom uploaded image template
    if (template.imagePath != null) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(template.imagePath!),
                fit: BoxFit.cover,
                width: width,
                height: height,
              ),
              ?child,
            ],
          ),
        ),
      );
    }

    // Built-in gradient template
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          colors: template.gradientColors,
          begin: template.gradientBegin,
          end: template.gradientEnd,
        ),
      ),
      child: child,
    );
  }
}
