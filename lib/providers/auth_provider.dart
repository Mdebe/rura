import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../database/db_helper.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AppUser? _currentUser;
  User? _firebaseUser;
  bool _isLoaded = false;
  bool _hasAcceptedTerms = false;

  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoaded => _isLoaded;
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isEnumerator => _currentUser?.role == 'Enumerator';
  bool get isViewer => _currentUser?.role == 'Viewer';
  bool get hasAcceptedTerms => _hasAcceptedTerms;

  AuthProvider() {
    _loadTermsStatus();
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _loadTermsStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasAcceptedTerms = prefs.getBool('accepted_terms_v1') ?? false;
    notifyListeners();
  }

  Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accepted_terms_v1', true);
    _hasAcceptedTerms = true;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    try {
      if (firebaseUser != null) {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          _currentUser = AppUser.fromMap(doc.data()!);
          await _firestore.collection('users').doc(firebaseUser.uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        } else {
          debugPrint('User doc missing for ${firebaseUser.uid}, signing out');
          await _firebaseAuth.signOut();
          _currentUser = null;
        }
      } else {
        _currentUser = null;
      }
    } catch (e) {
      debugPrint('Auth state error: $e');
      _currentUser = null;
      // Don't sign out here - user might just be offline
    } finally {
      _isLoaded = true; // ALWAYS set this
      notifyListeners();
    }
  }

  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    UserCredential? cred;
    try {
      cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      final uid = cred.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'Viewer',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      await _firebaseAuth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      try {
        await cred?.user?.delete();
      } catch (_) {}
      return _handleFirebaseError(e);
    } catch (e) {
      try {
        await cred?.user?.delete();
      } catch (_) {}
      return 'Registration failed: $e';
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Sign in cancelled';

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _firebaseAuth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': cred.user!.displayName ?? 'User',
          'email': cred.user!.email ?? '',
          'phone': cred.user!.phoneNumber ?? '',
          'role': 'Viewer',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } catch (e) {
      return 'Google sign in failed: $e';
    }
  }

  Future<String?> signInWithPhone({
    required String phone,
    required Function(String) onCodeSent,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (cred) async {
          final res = await _firebaseAuth.signInWithCredential(cred);
          await _ensureUserDoc(res.user!, phone);
        },
        verificationFailed: (e) => throw e,
        codeSent: (verId, _) => onCodeSent(verId),
        codeAutoRetrievalTimeout: (_) {},
      );
      return null;
    } catch (e) {
      return 'Phone auth failed: $e';
    }
  }

  Future<String?> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final res = await _firebaseAuth.signInWithCredential(cred);
      await _ensureUserDoc(res.user!, res.user!.phoneNumber ?? '');
      return null;
    } catch (e) {
      return 'Invalid code';
    }
  }

  Future<void> _ensureUserDoc(User user, String phone) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? 'User',
        'email': user.email ?? '',
        'phone': phone,
        'role': 'Viewer',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String?> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (_currentUser == null || _firebaseUser == null) return 'Not logged in';
    try {
      await _firebaseUser!.updateDisplayName(name.trim());
      final updated = _currentUser!.copyWith(
        name: name.trim(),
        phone: phone.trim(),
      );

      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update({'name': name.trim(), 'phone': phone.trim()})
          .timeout(const Duration(seconds: 10));

      await DBHelper.instance.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
      return null;
    } on TimeoutException {
      return 'Network timeout. Try again.';
    } catch (e) {
      return 'Failed to update profile: $e';
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_firebaseUser == null) return 'Not logged in';
    try {
      final cred = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: currentPassword,
      );
      await _firebaseUser!.reauthenticateWithCredential(cred);
      await _firebaseUser!.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') return 'Current password is incorrect';
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Failed to change password: $e';
    }
  }

  Future<String?> deleteAccount(String password) async {
    if (_firebaseUser == null || _currentUser == null) return 'Not logged in';
    try {
      final cred = EmailAuthProvider.credential(
        email: _firebaseUser!.email!,
        password: password,
      );
      await _firebaseUser!.reauthenticateWithCredential(cred);

      final uid = _firebaseUser!.uid;
      final email = _currentUser!.email;

      await _firestore
          .collection('users')
          .doc(uid)
          .delete()
          .timeout(const Duration(seconds: 10));
      await DBHelper.instance.deleteUser(email);
      await _firebaseUser!.delete();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accepted_terms_v1');

      _currentUser = null;
      _firebaseUser = null;
      _hasAcceptedTerms = false;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } on TimeoutException {
      return 'Network timeout. Try again.';
    } catch (e) {
      return 'Failed to delete account: $e';
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
  }

  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'Email already registered';
      case 'weak-password':
        return 'Password too weak. Use at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'requires-recent-login':
        return 'Please log out and log in again';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
