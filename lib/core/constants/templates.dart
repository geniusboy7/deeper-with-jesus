import 'package:flutter/material.dart';

class TemplateData {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final AlignmentGeometry textAlignment;
  final String? imagePath; // For custom uploaded templates

  const TemplateData({
    required this.id,
    required this.name,
    this.gradientColors = const [],
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
    this.textAlignment = Alignment.center,
    this.imagePath,
  });

  bool get isCustom => imagePath != null;
}

class Templates {
  static const List<TemplateData> all = [
    TemplateData(
      id: 'mountain_sunrise',
      name: 'Mountain Sunrise',
      gradientColors: [Color(0xFF7C3AED), Color(0xFFCA8A04), Color(0xFFF59E0B)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
    ),
    TemplateData(
      id: 'ocean_dawn',
      name: 'Ocean at Dawn',
      gradientColors: [Color(0xFF0C4A6E), Color(0xFF0891B2), Color(0xFF67E8F9)],
      gradientBegin: Alignment.bottomCenter,
      gradientEnd: Alignment.topCenter,
    ),
    TemplateData(
      id: 'forest_path',
      name: 'Forest Path',
      gradientColors: [Color(0xFF14532D), Color(0xFF166534), Color(0xFF4ADE80)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
    ),
    TemplateData(
      id: 'misty_valley',
      name: 'Misty Valley',
      gradientColors: [Color(0xFF475569), Color(0xFF94A3B8), Color(0xFFCBD5E1)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
    ),
    TemplateData(
      id: 'golden_field',
      name: 'Golden Wheat Field',
      gradientColors: [Color(0xFF92400E), Color(0xFFD97706), Color(0xFFFBBF24)],
      gradientBegin: Alignment.bottomLeft,
      gradientEnd: Alignment.topRight,
    ),
    TemplateData(
      id: 'starry_night',
      name: 'Starry Night Sky',
      gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
    ),
    TemplateData(
      id: 'watercolor',
      name: 'Soft Watercolor',
      gradientColors: [Color(0xFFFCE7F3), Color(0xFFE9D5FF), Color(0xFFDBEAFE)],
      gradientBegin: Alignment.topLeft,
      gradientEnd: Alignment.bottomRight,
    ),
    TemplateData(
      id: 'lily_pond',
      name: 'Lily Pond',
      gradientColors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF6EE7B7)],
      gradientBegin: Alignment.centerLeft,
      gradientEnd: Alignment.centerRight,
    ),
    TemplateData(
      id: 'candle_flame',
      name: 'Candle Flame',
      gradientColors: [Color(0xFF1C1917), Color(0xFF44403C), Color(0xFFCA8A04)],
      gradientBegin: Alignment.topCenter,
      gradientEnd: Alignment.bottomCenter,
    ),
    TemplateData(
      id: 'desert_sunset',
      name: 'Desert Sunset',
      gradientColors: [Color(0xFF7C2D12), Color(0xFFEA580C), Color(0xFFFBBF24)],
      gradientBegin: Alignment.bottomCenter,
      gradientEnd: Alignment.topCenter,
    ),
  ];

  static TemplateData getRandomTemplate() {
    final index = DateTime.now().millisecondsSinceEpoch % all.length;
    return all[index];
  }

  static TemplateData getTemplateForDate(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    return all[dayOfYear % all.length];
  }

  /// Returns true if the template has dark background (text should be white)
  static bool isDarkTemplate(TemplateData template) {
    final first = template.gradientColors.first;
    final luminance = first.computeLuminance();
    return luminance < 0.4;
  }
}
