import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_repository.dart';
import '../providers/session_providers.dart';

/// Màn hình tạm cho mọi route. Mỗi thành viên thay builder của route thuộc feature mình bằng màn hình thật.
/// Nút đăng xuất giúp thử luồng điều hướng theo vai trò trước khi có màn hình đăng nhập.
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider).when(
          data: (u) => u != null,
          loading: () => false,
          error: (_, __) => false,
        );
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Màn hình đang xây dựng'),
          if (signedIn) ...[
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(authRepositoryProvider).logout(),
              child: const Text('Đăng xuất'),
            ),
          ],
        ]),
      ),
    );
  }
}
