import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/default_topics.dart';

class ManageTopicsScreen extends StatefulWidget {
  const ManageTopicsScreen({super.key});

  @override
  State<ManageTopicsScreen> createState() => _ManageTopicsScreenState();
}

class _ManageTopicsScreenState extends State<ManageTopicsScreen> {
  final _nameController = TextEditingController();
  late List<TopicData> _topics;
  Color _selectedColor = const Color(0xFF7C3AED);

  static const List<Color> _colorOptions = [
    Color(0xFF7C3AED),
    Color(0xFFEC4899),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFEF4444),
  ];

  @override
  void initState() {
    super.initState();
    _topics = List.from(DefaultTopics.topics);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a topic name',
            style: GoogleFonts.raleway(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.errorLight,
        ),
      );
      return;
    }
    setState(() {
      _topics.add(TopicData(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
        color: _selectedColor,
        isDefault: false,
      ));
      _nameController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"$name" topic added',
          style: GoogleFonts.raleway(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _removeTopic(int index) {
    final topic = _topics[index];
    setState(() => _topics.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${topic.name}" removed',
          style: GoogleFonts.raleway(),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: AppColors.gold,
          onPressed: () {
            setState(() => _topics.insert(index, topic));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Topics',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Add topic section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.raleway(
                          fontSize: 15,
                          color: AppColors.textPrimary(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'New topic name',
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
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _addTopic(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addTopic,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Add',
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Color picker row
                Row(
                  children: _colorOptions.map((color) {
                    final isSelected = _selectedColor == color;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.textPrimary(context),
                                  width: 2.5,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                LucideIcons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          Divider(color: AppColors.divider(context), height: 1),

          // Topics list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: topic.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      topic.name,
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary(context),
                      ),
                    ),
                    trailing: topic.isDefault
                        ? Icon(
                            LucideIcons.lock,
                            size: 18,
                            color: AppColors.textSecondary(context),
                          )
                        : IconButton(
                            onPressed: () => _removeTopic(index),
                            icon: const Icon(LucideIcons.trash2),
                            color: AppColors.errorLight,
                            iconSize: 20,
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
