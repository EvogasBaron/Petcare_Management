import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/home_bottom_nav.dart';
import '../../../core/widgets/state_views.dart';
import '../data/auth_repository.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _avatarUrl;
  bool _initialized = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(String uid) async {
    final file = await ref.read(storageServiceProvider).pickImage();
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final url = await ref.read(storageServiceProvider).uploadOrFallback(
            file: file,
            storagePath: 'avatars/$uid/avatar.jpg',
          );
      setState(() => _avatarUrl = url);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(String uid) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            uid: uid,
            name: _name.text,
            phone: _phone.text,
            avatarUrl: _avatarUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu thông tin cá nhân.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppException.messageOf(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cá nhân')),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 4),
      body: AsyncValueView(
        value: userAsync,
        isEmpty: (u) => u == null,
        builder: (u) {
          final user = u!;
          if (!_initialized) {
            _name.text = user.name;
            _phone.text = user.phone;
            _avatarUrl = user.avatarUrl;
            _initialized = true;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _busy ? null : () => _pickAvatar(user.uid),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        AppAvatar(imageUrl: _avatarUrl, radius: 44, fallbackIcon: Icons.person),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Họ tên'),
                    validator: (v) => validateRequired(v, 'họ tên'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _save(user.uid),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Lưu thay đổi'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => context.push('/home/change-password'),
                      icon: const Icon(Icons.key_outlined),
                      label: const Text('Đổi mật khẩu'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => ref.read(authRepositoryProvider).logout(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Đăng xuất'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
