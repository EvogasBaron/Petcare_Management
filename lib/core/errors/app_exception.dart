import 'package:firebase_auth/firebase_auth.dart';

/// Lỗi có nghĩa, thông báo tiếng Việt. Repository bắt lỗi Firebase rồi ném lại bằng lớp này.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  factory AppException.fromFirebase(Object e) {
    if (e is AppException) return e;
    if (e is FirebaseAuthException) {
      return AppException(switch (e.code) {
        'invalid-email' => 'Email không hợp lệ.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu quá yếu, cần ít nhất 6 ký tự.',
        'user-disabled' => 'Tài khoản đã bị khóa.',
        'too-many-requests' => 'Thao tác quá nhiều lần, vui lòng thử lại sau.',
        'requires-recent-login' => 'Vì lý do bảo mật, vui lòng đăng xuất và đăng nhập lại trước khi đổi mật khẩu.',
        'network-request-failed' => 'Không có kết nối mạng.',
        _ => 'Không thực hiện được, vui lòng thử lại.',
      });
    }
    if (e is FirebaseException) {
      return AppException(switch (e.code) {
        'permission-denied' => 'Bạn không có quyền thực hiện thao tác này.',
        'unavailable' => 'Không kết nối được máy chủ, vui lòng kiểm tra mạng.',
        'not-found' => 'Không tìm thấy dữ liệu.',
        _ => 'Đã xảy ra lỗi, vui lòng thử lại.',
      });
    }
    return const AppException('Đã xảy ra lỗi, vui lòng thử lại.');
  }

  /// Dùng ở UI: lấy thông báo hiển thị từ mọi loại lỗi, không lộ lỗi thô.
  static String messageOf(Object e) => AppException.fromFirebase(e).message;

  @override
  String toString() => message;
}

/// Ném trong transaction đặt lịch khi khung giờ vừa đầy.
class SlotFullException extends AppException {
  const SlotFullException() : super('Khung giờ này vừa đầy, vui lòng chọn khung giờ khác.');
}
