/// Kiểm tra dữ liệu form dùng chung; trả null khi hợp lệ, trả thông báo tiếng Việt khi sai.
String? validateEmail(String? v) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Email không hợp lệ.';

String? validatePassword(String? v) => (v ?? '').length >= 6 ? null : 'Mật khẩu cần ít nhất 6 ký tự.';

String? validateRequired(String? v, String label) => (v ?? '').trim().isEmpty ? 'Vui lòng nhập $label.' : null;
