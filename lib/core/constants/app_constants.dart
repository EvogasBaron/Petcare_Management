/// Hằng số dùng chung. Đổi giá trị ở đây, không rải số trong code.
abstract final class AppConstants {
  static const int slotDurationMin = 30; // độ dài khung giờ đặt lịch (cố định toàn hệ thống)
  static const int cancelBeforeHours = 2; // người dùng chỉ hủy lịch đã xác nhận trước giờ hẹn ít nhất 2 giờ
  static const int maxHealthLogPhotos = 5;
}

abstract final class Roles {
  static const String user = 'user';
  static const String clinic = 'clinic';
  static const String admin = 'admin';
}

abstract final class ClinicStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String locked = 'locked';
}

abstract final class AppointmentStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String cancelled = 'cancelled';
  static const String completed = 'completed';
}
