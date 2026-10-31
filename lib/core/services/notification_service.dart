import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Dịch vụ thông báo cục bộ cho nhắc lịch chăm sóc, tiêm phòng (08:00 trước 1 ngày)
/// và lịch hẹn khám (trước 1 giờ + khi đổi trạng thái).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
      } catch (_) {}
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (_) {
      // Bỏ qua trong môi trường test hoặc nền tảng chưa hỗ trợ
    }
  }

  static const _channel = AndroidNotificationDetails(
    'petcare_channel',
    'Thông báo PetCare',
    channelDescription: 'Nhắc lịch chăm sóc, tiêm phòng và lịch khám thú cưng',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Hiện thông báo ngay lập tức (ví dụ khi lịch hẹn đổi trạng thái).
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await ensureInitialized();
    if (!_initialized) return;
    try {
      await _plugin.show(id, title, body, const NotificationDetails(android: _channel));
    } catch (_) {}
  }

  /// Đặt lịch thông báo một lần vào thời điểm [scheduledAt] (ví dụ 08:00 trước ngày tiêm, hoặc 1h trước giờ khám).
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;
    await ensureInitialized();
    if (!_initialized) return;
    try {
      final tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }

  /// Đặt lịch nhắc hàng ngày vào giờ:phút cố định.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await ensureInitialized();
    if (!_initialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(android: _channel),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
