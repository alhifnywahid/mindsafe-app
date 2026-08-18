import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mindsafe_flutter/core/config/app_config.dart';
import 'package:mindsafe_flutter/data/repositories/firestore_repository.dart';
import 'package:mindsafe_flutter/data/services/sync_service.dart';

class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final _currentUser = Rxn<User>();
  User? get currentUser => _currentUser.value;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Email administrator, dibaca dari konfigurasi build (`--dart-define`).
  /// Lihat `lib/core/config/app_config.dart` dan `CONTRIBUTING.md`.
  static String get adminEmail => AppConfig.adminEmail;

  /// Bernilai `true` hanya bila email admin sudah dikonfigurasi saat build
  /// DAN cocok dengan email akun yang sedang masuk.
  bool get isAdmin {
    if (!AppConfig.hasAdminEmail) return false;
    final email = currentUser?.email;
    if (email == null) return false;
    return email.toLowerCase() == adminEmail.trim().toLowerCase();
  }

  Future<AuthService> init() async {
    _currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((user) {
      _currentUser.value = user;
    });
    return this;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // ── Save user profile to Firestore ──
      final user = userCredential.user;
      if (user != null) {
        try {
          final repo = Get.find<FirestoreRepository>();
          await repo.saveUserProfile(
            userId: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoUrl: user.photoURL,
          );
        } catch (e) {
          debugPrint('⚠️ Profile save skipped: $e');
        }

        // ── Trigger immediate sync of pending data ──
        try {
          final syncService = Get.find<SyncService>();
          syncService.syncNow();
        } catch (e) {
          debugPrint('⚠️ Initial sync skipped: $e');
        }
      }

      return userCredential;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
}
