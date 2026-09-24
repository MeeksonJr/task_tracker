import 'package:cloud_firestore/cloud_firestore.dart';

// setting the user roles
enum UserRole {
  admin,
  member;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.member:
        return 'Member';
    }
  }

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.member;
    return role.toLowerCase() == 'admin' ? UserRole.admin : UserRole.member;
  }
}

class AppUser {
  final String id;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['createdAt'] as Timestamp?;
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      role: UserRole.fromString(data['role'] as String?),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    final timestamp = data['createdAt'] as Timestamp?;
    return AppUser(
      id: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'User',
      role: UserRole.fromString(data['role'] as String?),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}
