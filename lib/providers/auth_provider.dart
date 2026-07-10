import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
        // Try Firestore first
        final doc = await _firestore
            .collection('users')
            .doc(_firebaseUser!.uid)
            .get();
        if (doc.exists) {
          _currentUser = AppUser.fromMap(doc.data()!);
        } else {
          // Fallback to SQLite
          _currentUser = await DBHelper.instance.getUserByEmail(
            _firebaseUser!.email!,
          );
        }
      } catch (e) {
        debugPrint('Failed to load user online: $e');
        // Offline fallback - check SQLite
        _currentUser = await DBHelper.instance.getUserByEmail(
          _firebaseUser!.email!,
        );
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
          await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
          final updatedDoc = await docRef.get();
          _currentUser = AppUser.fromMap(updatedDoc.data()!);
          await DBHelper.instance.updateUser(_currentUser!);

          // Cache UID for offline login
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_uid', firebaseUser.uid);
        } else {
          _currentUser = await DBHelper.instance.getUserByEmail(
            firebaseUser.email!,
          );
          if (_currentUser != null) {
            final data = _currentUser!.toMap();
            data['lastLogin'] = Timestamp.fromDate(DateTime.now());
            data['createdAt'] = Timestamp.fromDate(_currentUser!.createdAt);
            await docRef.set(data);
          }
        }
      } catch (e) {
        debugPrint('Error syncing user online: $e');
        // Offline: load from SQLite by email
        _currentUser = await DBHelper.instance.getUserByEmail(
          firebaseUser.email!,
        );
      }
    } else {
      _currentUser = null;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    // Check connectivity first
    final connectivity = await Connectivity().checkConnectivity();
    final hasConnection = connectivity.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet,
    );

    try {
      if (hasConnection) {
        // ONLINE LOGIN
        final cred = await _firebaseAuth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final docRef = _firestore.collection('users').doc(cred.user!.uid);
        final doc = await docRef.get();

        AppUser localUser;

        if (!doc.exists) {
          localUser = AppUser(
            uid: cred.user!.uid,
            name: cred.user?.displayName ?? 'User',
            email: email.trim(),
            phone: '',
            role: 'Viewer',
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );

          final data = localUser.toMap();
          data['createdAt'] = FieldValue.serverTimestamp();
          data['lastLogin'] = FieldValue.serverTimestamp();
          await docRef.set(data);

          final newDoc = await docRef.get();
          localUser = AppUser.fromMap(newDoc.data()!);
        } else {
          localUser = AppUser.fromMap(doc.data()!);
          await docRef.update({'lastLogin': FieldValue.serverTimestamp()});
          final updatedDoc = await docRef.get();
          localUser = AppUser.fromMap(updatedDoc.data()!);
        }

        // Cache to SQLite + SharedPreferences
        await DBHelper.instance.insertUser(localUser);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_uid', cred.user!.uid);

        _currentUser = localUser;
        notifyListeners();
        return null;
      } else {
        // OFFLINE LOGIN - only works for last logged-in user
        final prefs = await SharedPreferences.getInstance();
        final lastUid = prefs.getString('last_uid');

        if (lastUid == null) {
          return 'No internet. Please connect to log in for the first time.';
        }

        final cached = await DBHelper.instance.getUserByUid(lastUid);
        if (cached == null || cached.email != email.trim()) {
          return 'Offline login only available for last user. Connect to internet.';
        }

        // We can't verify password offline with Firebase, so we trust device
        // For production, hash password locally on first login and verify here
        _currentUser = cached;
        notifyListeners();
        return null;
      }
    } on FirebaseAuthException catch (e) {
      // If Firebase fails, try offline as last resort
      if (!hasConnection) {
        final prefs = await SharedPreferences.getInstance();
        final lastUid = prefs.getString('last_uid');
        if (lastUid != null) {
          final cached = await DBHelper.instance.getUserByUid(lastUid);
          if (cached != null && cached.email == email.trim()) {
            _currentUser = cached;
            notifyListeners();
            return null;
          }
        }
      }
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

      final data = {
        'uid': cred.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(cred.user!.uid).set(data);

      final doc = await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .get();
      final savedUser = AppUser.fromMap(doc.data()!);
      await DBHelper.instance.insertUser(savedUser);
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
    // Keep SQLite + SharedPreferences for offline login next time
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_uid');

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
