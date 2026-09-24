import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../role_access/models/user_role.dart';

/// Represents a row in the `users` Firestore collection.
/// This is intentionally separate from firebase_auth's User object —
/// Firebase Auth handles identity/credentials, this model handles
/// app-level profile + role data.
class AppUser {
  final String uid;
  final String name;
  final String? email;
  final String? phone;
  final UserRole role;
  final bool isActive;
  final String? photoUrl;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    this.email,
    this.phone,
    required this.role,
    this.isActive = true,
    this.photoUrl,
    required this.createdAt,
  });

  factory AppUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'customer'),
      isActive: data['isActive'] as bool? ?? true,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'isActive': isActive,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    bool? isActive,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
