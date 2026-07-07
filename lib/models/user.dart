class AppUser {
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    this.lastLogin,
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
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

  static DateTime _toDateTime(dynamic value, {DateTime? fallback}) {
    if (value is DateTime) return value;
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
      name: _toString(map['name'], fallback: 'Enumerator'),
      email: _toString(map['email']),
      phone: _toString(map['phone']),
      role: _toString(map['role'], fallback: 'Enumerator'),
      createdAt: _toDateTime(map['createdAt']),
      lastLogin: map['lastLogin'] != null
          ? _toDateTime(map['lastLogin'], fallback: null)
          : null,
    );
  }
}
