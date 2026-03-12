import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/devotional_post.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _adminEmailsRef =>
      _db.collection('admin_emails');

  // ---------------------------------------------------------------------------
  // Get or create a user document after sign-in
  // ---------------------------------------------------------------------------

  /// Called after Firebase Auth sign-in. Creates the Firestore user doc if it
  /// doesn't exist yet, and auto-assigns admin role when the email is in the
  /// admin_emails collection.
  Future<AppUser> getOrCreateUser(User firebaseUser) async {
    final docRef = _usersRef.doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      return AppUser.fromFirestore(snapshot.data()!, firebaseUser.uid);
    }

    // New user — check if their email qualifies them as admin.
    final email = firebaseUser.email ?? '';
    final isAdmin = email.isNotEmpty && await isAdminEmail(email);

    final newUser = AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? 'User',
      email: email.isNotEmpty ? email : null,
      photoUrl: firebaseUser.photoURL,
      role: isAdmin ? 'admin' : 'user',
    );

    await docRef.set({
      ...newUser.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return newUser;
  }

  // ---------------------------------------------------------------------------
  // Read / watch
  // ---------------------------------------------------------------------------

  /// One-shot read of a user document.
  Future<AppUser?> getUser(String uid) async {
    final snapshot = await _usersRef.doc(uid).get();
    if (!snapshot.exists) return null;
    return AppUser.fromFirestore(snapshot.data()!, uid);
  }

  /// Real-time stream of a user document.
  Stream<AppUser?> watchUser(String uid) {
    return _usersRef.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromFirestore(snapshot.data()!, uid);
    });
  }

  // ---------------------------------------------------------------------------
  // Update / delete
  // ---------------------------------------------------------------------------

  /// Merge-update specific fields on the user document.
  Future<void> updateUser(AppUser user) async {
    await _usersRef.doc(user.uid).set(
          user.toFirestore(),
          SetOptions(merge: true),
        );
  }

  /// Delete the user's Firestore document (used for account deletion).
  Future<void> deleteUser(String uid) async {
    await _usersRef.doc(uid).delete();
  }

  // ---------------------------------------------------------------------------
  // Admin email helpers
  // ---------------------------------------------------------------------------

  /// Check whether an email is in the /admin_emails collection.
  Future<bool> isAdminEmail(String email) async {
    final doc = await _adminEmailsRef.doc(email.toLowerCase()).get();
    return doc.exists;
  }
}
