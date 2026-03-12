import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _audience = 'all'; // 'all' or 'registered'
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // TODO: Replace with real Firestore user count.
  int get _recipientCount {
    return 0;
  }

  void _sendNotification() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Please enter a notification title');
      return;
    }
    if (_bodyController.text.trim().isEmpty) {
      _showSnackBar('Please enter a notification message');
      return;
    }

    setState(() => _isSending = true);

    // Simulate sending delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isSending = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Icon(
          LucideIcons.checkCircle,
          color: const Color(0xFF10B981),
          size: 48,
        ),
        title: Text(
          'Notification Sent!',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        content: Text(
          'Push notification sent to $_recipientCount users.',
          style: GoogleFonts.raleway(
            fontSize: 15,
            color: AppColors.textSecondary(context),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to dashboard
            },
            child: Text(
              'Done',
              style: GoogleFonts.raleway(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Send Notification',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Compose section
          Text(
            'COMPOSE',
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Title field
          TextField(
            controller: _titleController,
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.raleway(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
              hintText: "e.g. Today's Devotional",
              hintStyle: GoogleFonts.raleway(
                fontSize: 14,
                color: AppColors.textSecondary(context).withValues(alpha: 0.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // Body field
          TextField(
            controller: _bodyController,
            style: GoogleFonts.raleway(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary(context),
            ),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: GoogleFonts.raleway(
                fontSize: 14,
                color: AppColors.textSecondary(context),
              ),
              hintText: 'e.g. A new word of encouragement is waiting for you.',
              hintStyle: GoogleFonts.raleway(
                fontSize: 14,
                color: AppColors.textSecondary(context).withValues(alpha: 0.5),
              ),
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.textSecondary(context).withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary(context),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 24),

          // Audience section
          Text(
            'AUDIENCE',
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Audience options
          _AudienceOption(
            title: 'All users',
            subtitle: 'Send to all users with notifications enabled',
            icon: LucideIcons.users,
            isSelected: _audience == 'all',
            onTap: () => setState(() => _audience = 'all'),
          ),
          const SizedBox(height: 8),
          _AudienceOption(
            title: 'Registered users only',
            subtitle: 'Send to signed-in users only',
            icon: LucideIcons.userCheck,
            isSelected: _audience == 'registered',
            onTap: () => setState(() => _audience = 'registered'),
          ),
          const SizedBox(height: 8),

          // Recipient count
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  LucideIcons.info,
                  size: 16,
                  color: AppColors.textSecondary(context),
                ),
                const SizedBox(width: 8),
                Text(
                  'This will be sent to $_recipientCount users',
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Preview section
          Text(
            'PREVIEW',
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _NotificationPreview(
            title: _titleController.text.isEmpty
                ? 'Notification Title'
                : _titleController.text,
            body: _bodyController.text.isEmpty
                ? 'Notification message will appear here...'
                : _bodyController.text,
          ),
          const SizedBox(height: 32),

          // Send button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendNotification,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary(context),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.primary(context).withValues(alpha: 0.5),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.send, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Send Notification',
                          style: GoogleFonts.raleway(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 32),

          // Recent notifications section
          Text(
            'RECENT NOTIFICATIONS',
            style: GoogleFonts.raleway(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary(context),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // TODO: Replace with real Firestore notification history.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No notifications sent yet',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AudienceOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AudienceOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary(context).withValues(alpha: 0.08)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary(context)
                : AppColors.textSecondary(context).withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppColors.primary(context)
                  : AppColors.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.raleway(
                      fontSize: 12,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected
                  ? AppColors.primary(context)
                  : AppColors.textSecondary(context),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  final String title;
  final String body;

  const _NotificationPreview({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.textSecondary(context).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary(context).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.cross,
              size: 20,
              color: AppColors.primary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DEEPER WITH JESUS',
                        style: GoogleFonts.raleway(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      'now',
                      style: GoogleFonts.raleway(
                        fontSize: 11,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.raleway(
                    fontSize: 13,
                    color: AppColors.textSecondary(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
