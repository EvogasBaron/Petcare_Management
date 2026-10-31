import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../models/app_user.dart';
import '../models/clinic.dart';

/// Phiên đăng nhập, dùng chung cho cả ba vai trò (router phụ thuộc vào ba provider này).
final authStateProvider = StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

/// users/{uid} của người đang đăng nhập; null nếu chưa đăng nhập hoặc chưa có tài liệu.
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(authStateProvider).when(
        data: (u) => u?.uid,
        loading: () => null,
        error: (_, __) => null,
      );
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? AppUser.fromFirestore(s) : null);
});

/// clinics/{uid} của tài khoản đối tác; null nếu không phải đối tác hoặc chưa nhập hồ sơ.
final myClinicProvider = StreamProvider<Clinic?>((ref) {
  final user = ref.watch(currentUserProvider).when(
        data: (u) => u,
        loading: () => null,
        error: (_, __) => null,
      );
  if (user == null || user.role != Roles.clinic) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('clinics')
      .doc(user.uid)
      .snapshots()
      .map((s) => s.exists ? Clinic.fromFirestore(s) : null);
});
