import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/app_constants.dart';

/// clinics/{clinicId}, với clinicId = uid của tài khoản đối tác (một tài khoản = một phòng khám).
class Clinic {
  const Clinic({
    required this.id,
    required this.name,
    required this.location,
    this.address = '',
    this.phone = '',
    this.openTime = '08:00',
    this.closeTime = '17:00',
    this.openDays = const [1, 2, 3, 4, 5, 6],
    this.photoUrl,
    this.slotCapacity = 1,
    this.status = ClinicStatus.pending,
    this.rejectReason,
    this.createdAt,
  });

  final String id;
  final String name;
  final GeoPoint location;
  final String address;
  final String phone;
  final String openTime; // 'HH:mm'
  final String closeTime;
  final List<int> openDays; // 1 = thứ hai ... 7 = chủ nhật
  final String? photoUrl;
  final int slotCapacity; // số lịch tối đa mỗi khung giờ
  final String status; // ClinicStatus.*
  final String? rejectReason;
  final DateTime? createdAt;

  factory Clinic.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Clinic(
      id: doc.id,
      name: d['name'] as String? ?? '',
      location: d['location'] as GeoPoint? ?? GeoPoint(0, 0),
      address: d['address'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      openTime: d['openTime'] as String? ?? '08:00',
      closeTime: d['closeTime'] as String? ?? '17:00',
      openDays: (d['openDays'] as List?)?.cast<int>() ?? const [1, 2, 3, 4, 5, 6],
      photoUrl: d['photoUrl'] as String?,
      slotCapacity: (d['slotCapacity'] as num?)?.toInt() ?? 1,
      status: d['status'] as String? ?? ClinicStatus.pending,
      rejectReason: d['rejectReason'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Dùng khi TẠO hồ sơ (status luôn là pending). Khi sửa, chỉ gửi các trường thay đổi và không gửi status.
  Map<String, dynamic> toMap() => {
        'name': name,
        'location': location,
        'address': address,
        'phone': phone,
        'openTime': openTime,
        'closeTime': closeTime,
        'openDays': openDays,
        'photoUrl': photoUrl,
        'slotCapacity': slotCapacity,
        'status': ClinicStatus.pending,
        'rejectReason': null,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
