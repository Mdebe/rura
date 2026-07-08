import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import '../database/db_helper.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppUser? _currentUser;
  User? _firebaseUser;
  bool _isLoaded = false;

  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoaded => _isLoaded;
  bool get isAdmin => _currentUser?.role == 'Admin';
  bool get isViewer => _currentUser?.role == 'Viewer';

  AuthProvider() {
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> checkAuthStatus() async {
    _firebaseUser = _firebaseAuth.currentUser;
    if (_firebaseUser != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(_firebaseUser!.uid)
            .get();
        if (doc.exists) {
          _currentUser = AppUser.fromMap(doc.data()!);
        } else {
          _currentUser = await DBHelper.instance.getUserByEmail(
            _firebaseUser!.email!,
          );
        }
      } catch (e) {
        debugPrint('Failed to load user: $e');
        _currentUser = null;
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      try {
        final docRef = _firestore.collection('users').doc(firebaseUser.uid);
        final doc = await docRef.get();

        if (doc.exists) {
          _currentUser = AppUser.fromMap(doc.data()!);
          final now = DateTime.now();
          await docRef.update({'lastLogin': now.toIso8601String()});
          await DBHelper.instance.updateUser(
            _currentUser!.copyWith(lastLogin: now),
          );
          _currentUser = _currentUser!.copyWith(lastLogin: now);
        } else {
          _currentUser = await DBHelper.instance.getUserByEmail(
            firebaseUser.email!,
          );
          if (_currentUser != null) {
            await docRef.set(_currentUser!.toMap());
          }
        }
      } catch (e) {
        debugPrint('Error syncing user: $e');
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }
    _isLoaded = true; // FIX: Always set this
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final docRef = _firestore.collection('users').doc(cred.user!.uid);
      final doc = await docRef.get();

      AppUser localUser;
      final now = DateTime.now();

      if (!doc.exists) {
        localUser = AppUser(
          name: cred.user?.displayName ?? 'User',
          email: email.trim(),
          phone: '',
          role: 'Viewer', // CHANGED: Default to Viewer instead of Enumerator
          createdAt: now,
          lastLogin: now,
        );

        await docRef.set(localUser.toMap());
        await DBHelper.instance.insertUser(localUser);
      } else {
        localUser = AppUser.fromMap(doc.data()!);
        await docRef.update({'lastLogin': now.toIso8601String()});
        localUser = localUser.copyWith(lastLogin: now);
      }

      _currentUser = localUser;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    UserCredential? cred;
    try {
      cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user?.updateDisplayName(name.trim());

      final now = DateTime.now();
      final user = AppUser(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role, // Role passed from RegisterScreen
        createdAt: now,
        lastLogin: now,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());
      await DBHelper.instance.insertUser(user);
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

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    _firebaseUser = null;
    notifyListeners();
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

      await _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'name': name.trim(),
        'phone': phone.trim(),
      });

      await DBHelper.instance.updateUser(updated);
      _currentUser = updated;
      notifyListeners();
      return null;
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

      await _firestore.collection('users').doc(_firebaseUser!.uid).delete();
      await DBHelper.instance.deleteUser(_currentUser!.email);
      await _firebaseUser!.delete();

      _currentUser = null;
      _firebaseUser = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Failed to delete account: $e';
    }
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
      case 'requires-recent-login':
        return 'Please log out and log in again';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
