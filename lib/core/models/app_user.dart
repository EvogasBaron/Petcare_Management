import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl,
    this.isLocked = false,
    this.createdAt,
  });

  final String uid;
  final String role; // Roles.*
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final bool isLocked;
  final DateTime? createdAt;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      role: d['role'] as String? ?? Roles.user,
      name: d['name'] as String? ?? '',
      email: d['email'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      avatarUrl: d['avatarUrl'] as String?,
      isLocked: d['isLocked'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Chỉ dùng khi TẠO tài khoản. Khi sửa, chỉ gửi name, phone, avatarUrl (Security Rules chỉ cho phép ba trường này).
  Map<String, dynamic> toMap() => {
        'role': role,
        'name': name,
        'email': email,
        'phone': phone,
        'avatarUrl': avatarUrl,
        'isLocked': isLocked,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
