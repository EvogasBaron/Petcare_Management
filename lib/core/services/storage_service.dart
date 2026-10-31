import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      return await _picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    } catch (_) {
      return null;
    }
  }

  /// Tải ảnh lên Firebase Storage tại đường dẫn [storagePath].
  /// Nếu dự án Firebase đang ở gói Spark (chưa bật Cloud Storage), tự động dùng đường dẫn cục bộ
  /// để ứng dụng vẫn hoạt động mượt mà trong lúc phát triển và demo.
  Future<String> uploadOrFallback({
    required XFile file,
    required String storagePath,
  }) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putFile(File(file.path), SettableMetadata(contentType: 'image/jpeg'));
      return await ref.getDownloadURL();
    } catch (_) {
      return file.path;
    }
  }
}
