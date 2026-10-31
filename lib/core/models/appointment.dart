import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class AppointmentResult {
  const AppointmentResult({this.diagnosis = '', this.prescription = '', this.advice = '', this.followUpDate});

  final String diagnosis;
  final String prescription;
  final String advice;
  final DateTime? followUpDate;

  factory AppointmentResult.fromMap(Map<String, dynamic> m) => AppointmentResult(
        diagnosis: m['diagnosis'] as String? ?? '',
        prescription: m['prescription'] as String? ?? '',
        advice: m['advice'] as String? ?? '',
        followUpDate: (m['followUpDate'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'diagnosis': diagnosis,
        'prescription': prescription,
        'advice': advice,
        'followUpDate': followUpDate == null ? null : Timestamp.fromDate(followUpDate!),
      };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.petId,
    required this.petName,
    required this.petSpecies,
    required this.clinicId,
    required this.clinicName,
    required this.serviceId,
    required this.serviceName,
    required this.servicePrice,
    this.doctorId,
    this.doctorName,
    required this.startTime,
    required this.slotId,
    this.status = AppointmentStatus.pending,
    this.cancelReason,
    this.cancelledBy,
    this.result,
    required this.notificationId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId, userName, userPhone;
  final String petId, petName, petSpecies;
  final String clinicId, clinicName;
  final String serviceId, serviceName;
  final int servicePrice; // VND
  final String? doctorId, doctorName; // bác sĩ là tùy chọn
  final DateTime startTime;
  final String slotId;
  final String status; // AppointmentStatus.*
  final String? cancelReason;
  final String? cancelledBy; // 'user' | 'clinic' | 'system'
  final AppointmentResult? result;
  final int notificationId; // id thông báo cục bộ nhắc trước giờ hẹn
  final DateTime? createdAt, updatedAt;

  /// Id tài liệu slot: yyyyMMdd_HHmm (giờ địa phương), ví dụ 20261020_0930.
  static String slotIdFor(DateTime t) => DateFormat('yyyyMMdd_HHmm').format(t);

  /// Trường date của tài liệu slot: yyyyMMdd.
  static String slotDateFor(DateTime t) => DateFormat('yyyyMMdd').format(t);

  /// Quy tắc hủy của người dùng: lịch chờ xác nhận thì luôn hủy được,
  /// lịch đã xác nhận chỉ hủy được trước giờ hẹn ít nhất cancelBeforeHours giờ.
  bool canUserCancel(DateTime now) {
    if (status == AppointmentStatus.pending) return true;
    if (status == AppointmentStatus.confirmed) {
      return now.isBefore(startTime.subtract(const Duration(hours: AppConstants.cancelBeforeHours)));
    }
    return false;
  }

  factory Appointment.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final r = d['result'] as Map<String, dynamic>?;
    return Appointment(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      userName: d['userName'] as String? ?? '',
      userPhone: d['userPhone'] as String? ?? '',
      petId: d['petId'] as String? ?? '',
      petName: d['petName'] as String? ?? '',
      petSpecies: d['petSpecies'] as String? ?? '',
      clinicId: d['clinicId'] as String? ?? '',
      clinicName: d['clinicName'] as String? ?? '',
      serviceId: d['serviceId'] as String? ?? '',
      serviceName: d['serviceName'] as String? ?? '',
      servicePrice: (d['servicePrice'] as num?)?.toInt() ?? 0,
      doctorId: d['doctorId'] as String?,
      doctorName: d['doctorName'] as String?,
      startTime: (d['startTime'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
      slotId: d['slotId'] as String? ?? '',
      status: d['status'] as String? ?? AppointmentStatus.pending,
      cancelReason: d['cancelReason'] as String?,
      cancelledBy: d['cancelledBy'] as String?,
      result: r == null ? null : AppointmentResult.fromMap(r),
      notificationId: (d['notificationId'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Dùng khi TẠO lịch (trong transaction đặt lịch): status luôn là pending.
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'petId': petId,
        'petName': petName,
        'petSpecies': petSpecies,
        'clinicId': clinicId,
        'clinicName': clinicName,
        'serviceId': serviceId,
        'serviceName': serviceName,
        'servicePrice': servicePrice,
        'doctorId': doctorId,
        'doctorName': doctorName,
        'startTime': Timestamp.fromDate(startTime),
        'slotId': slotId,
        'status': AppointmentStatus.pending,
        'cancelReason': null,
        'cancelledBy': null,
        'result': null,
        'notificationId': notificationId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
