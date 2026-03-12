import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/app_colors.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _emailController = TextEditingController();
  final List<String> _adminEmails = ['heroescope@gmail.com'];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _addAdmin() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid email address',
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
    if (_adminEmails.contains(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This email is already an admin',
            style: GoogleFonts.raleway(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    setState(() {
      _adminEmails.add(email);
      _emailController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$email added as admin',
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

  void _removeAdmin(int index) {
    final email = _adminEmails[index];
    setState(() => _adminEmails.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$email removed',
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
            setState(() => _adminEmails.insert(index, email));
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
          'Manage Admins',
          style: GoogleFonts.lora(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // Add admin section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.raleway(
                      fontSize: 15,
                      color: AppColors.textPrimary(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Admin email address',
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
                      prefixIcon: Icon(
                        LucideIcons.mail,
                        size: 20,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                    onSubmitted: (_) => _addAdmin(),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _addAdmin,
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
          ),

          Divider(color: AppColors.divider(context), height: 1),

          // Admin list
          Expanded(
            child: _adminEmails.isEmpty
                ? Center(
                    child: Text(
                      'No admins added',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _adminEmails.length,
                    itemBuilder: (context, index) {
                      final email = _adminEmails[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary(context)
                                .withValues(alpha: 0.12),
                            child: Icon(
                              LucideIcons.shieldCheck,
                              size: 20,
                              color: AppColors.primary(context),
                            ),
                          ),
                          title: Text(
                            email,
                            style: GoogleFonts.raleway(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _removeAdmin(index),
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
