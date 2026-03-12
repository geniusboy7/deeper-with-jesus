import 'package:flutter/material.dart';

class TopicData {
  final String id;
  final String name;
  final Color color;
  final bool isDefault;

  const TopicData({
    required this.id,
    required this.name,
    required this.color,
    this.isDefault = true,
  });
}

class DefaultTopics {
  static const List<TopicData> topics = [
    TopicData(id: 'faith', name: 'Faith', color: Color(0xFF7C3AED)),
    TopicData(id: 'prayer', name: 'Prayer', color: Color(0xFF6366F1)),
    TopicData(id: 'hope', name: 'Hope', color: Color(0xFF0EA5E9)),
    TopicData(id: 'love', name: 'Love', color: Color(0xFFEC4899)),
    TopicData(id: 'gratitude', name: 'Gratitude', color: Color(0xFFCA8A04)),
    TopicData(id: 'strength', name: 'Strength', color: Color(0xFFEF4444)),
    TopicData(id: 'peace', name: 'Peace', color: Color(0xFF10B981)),
    TopicData(id: 'forgiveness', name: 'Forgiveness', color: Color(0xFF8B5CF6)),
    TopicData(id: 'purpose', name: 'Purpose', color: Color(0xFFF97316)),
    TopicData(id: 'wisdom', name: 'Wisdom', color: Color(0xFF14B8A6)),
  ];
}
