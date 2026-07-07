import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import '../database/db_helper.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AppUser? _currentUser;
  User? _firebaseUser;
  bool _isLoaded = false;
  bool _authListenerActive = false;

  AppUser? get currentUser => _currentUser;
  User? get firebaseUser => _firebaseUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoaded => _isLoaded;
  bool get isAdmin => _currentUser?.role == 'Admin';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
    _authListenerActive = true;
  }

  // Called from main.dart after runApp
  Future<void> checkAuthStatus() async {
    // Wait for listener to fire first time
    if (!_authListenerActive) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _firebaseUser = _firebaseAuth.currentUser;
    if (_firebaseUser != null) {
      try {
        _currentUser = await DBHelper.instance.getUserByEmail(
          _firebaseUser!.email!,
        );
      } catch (e) {
        debugPrint('Failed to load user from DB: $e');
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
        _currentUser = await DBHelper.instance.getUserByEmail(
          firebaseUser.email!,
        );
        if (_currentUser != null) {
          final updated = _currentUser!.copyWith(lastLogin: DateTime.now());
          await DBHelper.instance.updateUser(updated);
          _currentUser = updated;
        }
      } catch (e) {
        debugPrint('Error syncing user on auth change: $e');
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }

    if (_isLoaded) notifyListeners();
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

      // Ensure local user exists
      var localUser = await DBHelper.instance.getUserByEmail(email.trim());
      if (localUser == null) {
        localUser = AppUser(
          name: cred.user?.displayName ?? 'User',
          email: email.trim(),
          phone: '',
          role: 'Enumerator',
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await DBHelper.instance.insertUser(localUser);
      }

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
    try {
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user?.updateDisplayName(name.trim());

      final user = AppUser(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      await DBHelper.instance.insertUser(user);

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access admin panel',
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
