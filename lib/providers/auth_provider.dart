import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // REQUIRED
import 'package:local_auth/local_auth.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
          // FIX: Use FieldValue.serverTimestamp() not DateTime
          await docRef.update({'lastLogin': FieldValue.serverTimestamp()});

          // Fetch updated doc to get server timestamp back
          final updatedDoc = await docRef.get();
          _currentUser = AppUser.fromMap(updatedDoc.data()!);
          await DBHelper.instance.updateUser(_currentUser!);
        } else {
          _currentUser = await DBHelper.instance.getUserByEmail(
            firebaseUser.email!,
          );
          if (_currentUser != null) {
            // FIX: Convert DateTime to Timestamp for Firestore
            final data = _currentUser!.toMap();
            data['lastLogin'] = Timestamp.fromDate(DateTime.now());
            data['createdAt'] = Timestamp.fromDate(_currentUser!.createdAt);
            await docRef.set(data);
          }
        }
      } catch (e) {
        debugPrint('Error syncing user: $e');
        _currentUser = null;
      }
    } else {
      _currentUser = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // 1. Create local user first - always works offline
    final localUser = AppUser(
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      role: role,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      passwordHash: _hashPassword(password), // Store hash for offline login
    );

    try {
      // Check if user exists locally first
      final existing = await DBHelper.instance.getUserByEmail(email.trim());
      if (existing != null) {
        return 'Email already registered locally';
      }

      // Save to SQLite first - offline first
      await DBHelper.instance.insertUser(localUser);

      // 2. Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      if (!isOnline) {
        // Offline: return success, will sync later via Dashboard
        await _firebaseAuth.signOut(); // Ensure no stale session
        return null;
      }

      // 3. Online: create Firebase Auth + Firestore
      UserCredential? cred;
      try {
        cred = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        await cred.user?.updateDisplayName(name.trim());

        // Write to Firestore with server timestamp
        final data = localUser.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['lastLogin'] = FieldValue.serverTimestamp();
        data.remove('passwordHash'); // Don't store hash in Firestore

        await _firestore.collection('users').doc(cred.user!.uid).set(data);

        // 4. Mark as synced locally
        final syncedUser = localUser.copyWith(
          firestoreId: cred.user!.uid,
          isSynced: true,
        );
        await DBHelper.instance.updateUser(syncedUser);

        await _firebaseAuth.signOut(); // Force manual login
        return null;
      } on FirebaseAuthException catch (e) {
        // Firebase failed but SQLite succeeded - keep local user
        await cred?.user?.delete(); // Cleanup if partial
        debugPrint('Firebase register failed, saved offline: ${e.message}');
        return null; // Still success - user saved locally
      }
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  // Helper to hash password for offline login
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
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

      if (!doc.exists) {
        // FIX: Create with server timestamp
        localUser = AppUser(
          name: cred.user?.displayName ?? 'User',
          email: email.trim(),
          phone: '',
          role: 'Viewer',
          createdAt: DateTime.now(),
          // ignore: unnecessary_string_interpolations
          lastLogin: DateTime.now(),
          passwordHash: '${_hashPassword(password)}',
        );

        final data = localUser.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        data['lastLogin'] = FieldValue.serverTimestamp();
        await docRef.set(data);

        // Fetch back to get actual server timestamps
        final newDoc = await docRef.get();
        localUser = AppUser.fromMap(newDoc.data()!);
        await DBHelper.instance.insertUser(localUser);
      } else {
        localUser = AppUser.fromMap(doc.data()!);
        // FIX: Use FieldValue.serverTimestamp()
        await docRef.update({'lastLogin': FieldValue.serverTimestamp()});

        // Fetch updated doc
        final updatedDoc = await docRef.get();
        localUser = AppUser.fromMap(updatedDoc.data()!);
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
        firestoreId: ' ',
        isSynced: true,
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
