import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/app_user.dart';
import '../../../core/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? db})
      : _authInstance = auth,
        _dbInstance = db;

  final FirebaseAuth? _authInstance;
  final FirebaseFirestore? _dbInstance;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;

  Future<void> login(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  /// role là Roles.user hoặc Roles.clinic (Rules không cho tự nhận admin).
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) =>
      _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final user = AppUser(
          uid: cred.user!.uid,
          role: role,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
        );
        try {
          await _db.collection('users').doc(user.uid).set(user.toMap());
        } catch (_) {
          await cred.user!.delete(); // không để lại tài khoản thiếu hồ sơ users (router sẽ kẹt ở màn hình chờ)
          rethrow;
        }
      });

  Future<void> sendPasswordReset(String email) => _guard(() async {
        try {
          await _auth.sendPasswordResetEmail(email: email.trim());
        } on FirebaseAuthException catch (e) {
          if (e.code != 'user-not-found') rethrow; // không lộ email nào đã đăng ký
        }
      });

  /// Chỉ gửi name, phone, avatarUrl theo đúng giới hạn của Firestore Security Rules.
  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    String? avatarUrl,
  }) =>
      _guard(() => _db.collection('users').doc(uid).update({
            'name': name.trim(),
            'phone': phone.trim(),
            'avatarUrl': avatarUrl,
          }));

  /// Đổi mật khẩu có xác thực lại mật khẩu hiện tại (reauthenticate) để đảm bảo an toàn.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(() async {
        final user = _auth.currentUser;
        if (user == null || user.email == null) {
          throw const AppException('Phiên đăng nhập đã hết hạn.');
        }
        try {
          final cred = EmailAuthProvider.credential(
            email: user.email!,
            password: currentPassword,
          );
          await user.reauthenticateWithCredential(cred);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
            throw const AppException('Mật khẩu hiện tại không chính xác.');
          }
          rethrow;
        }
        await user.updatePassword(newPassword);
      });

  Future<void> logout() async {
    await NotificationService.instance.cancelAll();
    await _auth.signOut();
  }

  Future<void> _guard(Future<void> Function() run) async {
    try {
      await run();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }
}
