import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/theme/app_theme.dart';
import 'package:petcare/features/auth/data/auth_repository.dart';
import 'package:petcare/features/auth/presentation/change_password_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  String? lastCurrentPassword;
  String? lastNewPassword;
  bool shouldThrow = false;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (shouldThrow) {
      throw Exception('Mật khẩu hiện tại không chính xác.');
    }
    lastCurrentPassword = currentPassword;
    lastNewPassword = newPassword;
  }
}

Widget _wrapScreen(_FakeAuthRepository fakeRepo) => ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: const ChangePasswordScreen(),
      ),
    );

void main() {
  testWidgets('Kiểm thử giao diện và validate form đổi mật khẩu', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    await tester.pumpWidget(_wrapScreen(fakeRepo));
    await tester.pumpAndSettle();

    // 1. Kiểm tra tiêu đề và các trường nhập
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
    expect(find.text('Mật khẩu mới'), findsOneWidget);
    expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);

    final submitBtn = find.widgetWithText(FilledButton, 'Cập nhật mật khẩu');
    expect(submitBtn, findsOneWidget);

    // 2. Bấm Cập nhật khi để trống -> hiển thị lỗi validate
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Vui lòng nhập mật khẩu hiện tại.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 6 ký tự.'), findsOneWidget);
    expect(find.text('Vui lòng xác nhận mật khẩu mới.'), findsOneWidget);

    // 3. Nhập mật khẩu mới trùng với mật khẩu cũ
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '123456');
    await tester.enterText(textFields.at(1), '123456');
    await tester.enterText(textFields.at(2), '123456');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Mật khẩu mới không được trùng mật khẩu cũ.'), findsOneWidget);

    // 4. Nhập xác nhận không khớp
    await tester.enterText(textFields.at(1), 'abcdef');
    await tester.enterText(textFields.at(2), 'xyz123');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();
    expect(find.text('Mật khẩu xác nhận không khớp.'), findsOneWidget);

    // 5. Nhập hợp lệ -> gọi repository thành công
    await tester.enterText(textFields.at(0), 'oldPassword123');
    await tester.enterText(textFields.at(1), 'newPassword456');
    await tester.enterText(textFields.at(2), 'newPassword456');
    await tester.ensureVisible(submitBtn);
    await tester.tap(submitBtn);
    await tester.pump();

    expect(fakeRepo.lastCurrentPassword, 'oldPassword123');
    expect(fakeRepo.lastNewPassword, 'newPassword456');
  });

  testWidgets('Ẩn/hiện mật khẩu khi bấm biểu tượng con mắt', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    await tester.pumpWidget(_wrapScreen(fakeRepo));
    await tester.pumpAndSettle();

    // Tìm các IconButton con mắt
    final eyeButtons = find.byType(IconButton);
    expect(eyeButtons, findsNWidgets(3));

    // Bấm con mắt đầu tiên để chuyển sang hiện mật khẩu
    await tester.tap(eyeButtons.first);
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
