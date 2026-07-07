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
  bool _isLoaded = false; // Add this
  
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null; // Renamed from isLoggedIn for AuthGate
  bool get isLoaded => _isLoaded; // Add this getter
  bool get isAdmin => _currentUser?.role == 'Admin';

  AuthProvider() {
    // Listen to Firebase auth state changes
    _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);
  }

  // Add this method - called from main.dart
  Future<void> checkAuthStatus() async {
    // Firebase handles session persistence automatically
    // Just wait for first authStateChanges event
    _firebaseUser = _firebaseAuth.currentUser;
    if (_firebaseUser != null) {
      _currentUser = await DBHelper.instance.getUserByEmail(_firebaseUser!.email!);
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    _firebaseUser = firebaseUser;
    if (firebaseUser != null) {
      _currentUser = await DBHelper.instance.getUserByEmail(firebaseUser.email!);
      if (_currentUser != null) {
        await DBHelper.instance.updateUser(
          _currentUser!.copyWith(lastLogin: DateTime.now()),
        );
      }
    } else {
      _currentUser = null;
    }
    // Only notify if already loaded, otherwise checkAuthStatus handles it
    if (_isLoaded) notifyListeners();
  }

  Future<String?> login({required String email, required String password}) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if user exists in local DB, if not create basic profile
      var localUser = await DBHelper.instance.getUserByEmail(email);
      if (localUser == null) {
        localUser = AppUser(
          name: cred.user?.displayName ?? 'User',
          email: email,
          phone: '',
          role: 'Enumerator', // default role
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
        );
        await DBHelper.instance.insertUser(localUser);
      }
      
      return null; // success
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
      // 1. Create Firebase user
      final cred = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await cred.user?.updateDisplayName(name);

      // 2. Save profile to local DB
      final user = AppUser(
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      await DBHelper.instance.insertUser(user);
      
      return null; // success
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

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access admin panel',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      return didAuth;
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    _currentUser = null;
    notifyListeners();
  }
  // Add these inside AuthProvider class, before the last }

Future<String?> updateProfile({
  required String name,
  required String phone,
}) async {
  if (_currentUser == null) return 'Not logged in';
  try {
    // Update Firebase display name
    await _firebaseUser?.updateDisplayName(name);

    // Update local DB
    final updated = _currentUser!.copyWith(
      name: name,
      phone: phone,
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
    // Re-authenticate first
    final cred = EmailAuthProvider.credential(
      email: _firebaseUser!.email!,
      password: currentPassword,
    );
    await _firebaseUser!.reauthenticateWithCredential(cred);

    // Update password
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
    // Re-authenticate
    final cred = EmailAuthProvider.credential(
      email: _firebaseUser!.email!,
      password: password,
    );
    await _firebaseUser!.reauthenticateWithCredential(cred);

    // Delete from local DB first
    await DBHelper.instance.deleteUser(_currentUser!.email);

    // Delete Firebase account
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
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}