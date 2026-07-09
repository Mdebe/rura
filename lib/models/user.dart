import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String? uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const AppUser({
    this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    required String passwordHash,
  });

  AppUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
    required String firestoreId,
    required bool isSynced,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      passwordHash: '',
    );
  }

  // For Firestore - DON'T convert to string here
  // Use FieldValue.serverTimestamp() in AuthProvider instead
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt), // FIX: Send as Timestamp
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // For local SQLite - convert to ISO string
  Map<String, dynamic> toSqliteMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  static String _toString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  // FIX: Handle Timestamp, String, DateTime, int
  static DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate(); // Firestore Timestamp
    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return fallback ?? DateTime.now();
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: _toString(map['uid']),
      name: _toString(map['name'], fallback: 'Enumerator'),
      email: _toString(map['email']),
      phone: _toString(map['phone']),
      role: _toString(map['role'], fallback: 'Enumerator'),
      createdAt: _toDateTime(map['createdAt']),
      lastLogin: map['lastLogin'] != null
          ? _toDateTime(map['lastLogin'], fallback: null)
          : null,
      passwordHash: '',
    );
  }
}
