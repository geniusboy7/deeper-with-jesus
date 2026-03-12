import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _adminEmailsRef = FirebaseFirestore.instance.collection('admin_emails');
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _addAdmin() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar('Please enter a valid email address', isError: true);
      return;
    }

    // Check if already exists
    final doc = await _adminEmailsRef.doc(email).get();
    if (doc.exists) {
      _showSnackBar('This email is already an admin');
      return;
    }

    setState(() => _isAdding = true);
    try {
      await _adminEmailsRef.doc(email).set({
        'addedAt': FieldValue.serverTimestamp(),
      });
      _emailController.clear();
      if (mounted) _showSnackBar('$email added as admin', isSuccess: true);
    } catch (e) {
      if (mounted) _showSnackBar('Failed to add admin: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removeAdmin(String email) async {
    try {
      await _adminEmailsRef.doc(email).delete();
      if (mounted) {
        _showSnackBar('$email removed');
      }
    } catch (e) {
      if (mounted) _showSnackBar('Failed to remove: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.raleway()),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError
            ? AppColors.errorLight
            : isSuccess
                ? const Color(0xFF10B981)
                : null,
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
                    onPressed: _isAdding ? null : _addAdmin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isAdding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary(context),
                            ),
                          )
                        : Text(
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

          // Admin list — real-time from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _adminEmailsRef.orderBy('addedAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary(context),
                      strokeWidth: 2,
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No admins added',
                      style: GoogleFonts.raleway(
                        fontSize: 16,
                        color: AppColors.textSecondary(context),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final email = docs[index].id;
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
                          onPressed: () => _removeAdmin(email),
                          icon: const Icon(LucideIcons.trash2),
                          color: AppColors.errorLight,
                          iconSize: 20,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
