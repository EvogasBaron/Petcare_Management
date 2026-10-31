import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/app.dart';
import 'package:petcare/core/models/app_user.dart';
import 'package:petcare/core/models/clinic.dart';
import 'package:petcare/core/providers/session_providers.dart';
import 'package:petcare/features/auth/data/auth_repository.dart';

class _FakeAuthRepository extends AuthRepository {
  String? lastResetEmail;
  String? lastRegisteredRole;

  @override
  Future<void> login(String email, String password) async {}

  @override
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    lastRegisteredRole = role;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    lastResetEmail = email.trim();
  }

  @override
  Future<void> logout() async {}
}

Widget _buildTestApp(_FakeAuthRepository fakeRepo) => ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        currentUserProvider.overrideWith((ref) => Stream<AppUser?>.value(null)),
        myClinicProvider.overrideWith((ref) => Stream<Clinic?>.value(null)),
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const PetCareApp(),
    );

void main() {
  testWidgets('Luồng màn hình Đăng nhập, Đăng ký và Quên mật khẩu', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    await tester.pumpWidget(_buildTestApp(fakeRepo));
    await tester.pumpAndSettle();

    // 1. Mặc định chưa đăng nhập sẽ ở màn hình Đăng nhập
    expect(find.text('Đăng nhập'), findsWidgets);

    // Bấm Đăng nhập khi trống -> hiển thị lỗi validate tiếng Việt
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Email không hợp lệ.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 6 ký tự.'), findsOneWidget);

    // 2. Chuyển sang màn hình Quên mật khẩu
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();
    expect(find.text('Gửi thư đặt lại mật khẩu'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'user@petcare.vn');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi thư đặt lại mật khẩu'));
    await tester.pumpAndSettle();
    expect(fakeRepo.lastResetEmail, 'user@petcare.vn');

    // 3. Chuyển sang màn hình Đăng ký
    await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.text('Chủ nuôi'), findsOneWidget);
    expect(find.text('Phòng khám'), findsOneWidget);

    // Chuyển vai trò sang Phòng khám -> đổi nhãn thành 'Tên người liên hệ'
    await tester.tap(find.text('Phòng khám'));
    await tester.pump();
    expect(find.text('Tên người liên hệ'), findsOneWidget);
  });
}
