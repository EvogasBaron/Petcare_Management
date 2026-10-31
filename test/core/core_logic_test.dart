import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/constants/app_constants.dart';
import 'package:petcare/core/models/app_user.dart';
import 'package:petcare/core/models/appointment.dart';
import 'package:petcare/core/models/clinic.dart';
import 'package:petcare/core/router/app_router.dart';

AppUser mkUser(String role, {bool locked = false}) =>
    AppUser(uid: 'u1', role: role, name: 'A', email: 'a@x.vn', isLocked: locked);

Clinic mkClinic(String status) => Clinic(id: 'u1', name: 'PK', location: GeoPoint(0, 0), status: status);

String? go(
  String loc, {
  AsyncValue<Object?>? auth,
  AsyncValue<AppUser?>? profile,
  AsyncValue<Clinic?>? clinic,
}) =>
    computeRedirect(
      loc: loc,
      auth: auth ?? AsyncData<Object?>('u1'),
      profile: profile ?? AsyncData<AppUser?>(mkUser(Roles.user)),
      clinic: clinic ?? AsyncData<Clinic?>(null),
    );

Appointment mkAppt(String status, DateTime start) => Appointment(
      id: 'a1', userId: 'u1', userName: 'A', petId: 'p1', petName: 'Mimi', petSpecies: 'cat',
      clinicId: 'c1', clinicName: 'PK', serviceId: 's1', serviceName: 'Khám', servicePrice: 100000,
      startTime: start, slotId: Appointment.slotIdFor(start), status: status, notificationId: 1,
    );

void main() {
  group('computeRedirect', () {
    test('chưa đăng nhập', () {
      final out = AsyncData<Object?>(null);
      expect(go('/home/pets', auth: out), '/login');
      expect(go('/login', auth: out), isNull);
    });

    test('đang tải phiên đăng nhập', () {
      expect(go('/login', auth: AsyncLoading<Object?>()), '/splash');
    });

    test('tài khoản bị khóa', () {
      expect(go('/home/pets', profile: AsyncData<AppUser?>(mkUser(Roles.user, locked: true))), '/locked');
    });

    test('chủ nuôi chỉ ở khu /home', () {
      expect(go('/login'), '/home/pets');
      expect(go('/admin/users'), '/home/pets');
      expect(go('/home/pets/1'), isNull);
    });

    test('admin chỉ ở khu /admin', () {
      final admin = AsyncData<AppUser?>(mkUser(Roles.admin));
      expect(go('/home/pets', profile: admin), '/admin/clinics');
      expect(go('/admin/users', profile: admin), isNull);
    });

    test('đối tác theo trạng thái phòng khám', () {
      final p = AsyncData<AppUser?>(mkUser(Roles.clinic));
      expect(go('/clinic/dashboard', profile: p), '/clinic/setup'); // chưa có hồ sơ
      expect(go('/clinic/dashboard', profile: p, clinic: AsyncData<Clinic?>(mkClinic(ClinicStatus.pending))),
          '/clinic/pending');
      expect(go('/clinic/setup', profile: p, clinic: AsyncData<Clinic?>(mkClinic(ClinicStatus.rejected))),
          isNull); // bị từ chối được sửa hồ sơ
      expect(go('/clinic/pending', profile: p, clinic: AsyncData<Clinic?>(mkClinic(ClinicStatus.approved))),
          '/clinic/dashboard');
      expect(go('/clinic/services', profile: p, clinic: AsyncData<Clinic?>(mkClinic(ClinicStatus.approved))),
          isNull);
    });
  });

  group('Appointment', () {
    final start = DateTime(2026, 10, 20, 9, 30);

    test('slotId và date', () {
      expect(Appointment.slotIdFor(start), '20261020_0930');
      expect(Appointment.slotDateFor(start), '20261020');
    });

    test('quy tắc hủy 2 giờ', () {
      expect(mkAppt(AppointmentStatus.pending, start).canUserCancel(DateTime(2026, 10, 20, 9)), isTrue);
      final confirmed = mkAppt(AppointmentStatus.confirmed, start);
      expect(confirmed.canUserCancel(DateTime(2026, 10, 20, 6, 30)), isTrue); // còn 3 giờ
      expect(confirmed.canUserCancel(DateTime(2026, 10, 20, 8, 30)), isFalse); // còn 1 giờ
      expect(mkAppt(AppointmentStatus.cancelled, start).canUserCancel(DateTime(2026, 10, 19)), isFalse);
    });
  });
}
