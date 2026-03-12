import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes (user or null).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  // ---------------------------------------------------------------------------
  // Apple Sign-In
  // ---------------------------------------------------------------------------

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    // Apple only provides the display name on the FIRST sign-in.
    // Persist it to the Firebase user profile so it's always available.
    final user = userCredential.user;
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      final givenName = appleCredential.givenName ?? '';
      final familyName = appleCredential.familyName ?? '';
      final fullName = '$givenName $familyName'.trim();
      if (fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
        // Reload to reflect the updated profile.
        await user.reload();
      }
    }

    return userCredential;
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Generate a cryptographically-secure random nonce (URL-safe Base64).
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }
}

/// Convenience exception for cancelled sign-in flows.
class FirebaseAuthException implements Exception {
  final String code;
  final String message;
  const FirebaseAuthException({required this.code, required this.message});

  @override
  String toString() => 'FirebaseAuthException($code): $message';
}
