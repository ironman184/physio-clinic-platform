import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String clinicId;
  final String planId;
  final String patientId;
  final String therapistId;
  final int sessionNo;
  final String date; // YYYY-MM-DD
  final String slotId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? rescheduledFrom;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelReason;

  const SessionModel({
    required this.id,
    required this.clinicId,
    required this.planId,
    required this.patientId,
    required this.therapistId,
    required this.sessionNo,
    required this.date,
    required this.slotId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.rescheduledFrom,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelReason,
  });

  factory SessionModel.fromMap(String id, Map<String, dynamic> map) {
    return SessionModel(
      id: id,
      clinicId: map['clinicId'] as String,
      planId: map['planId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      sessionNo: map['sessionNo'] as int,
      date: map['date'] as String,
      slotId: map['slotId'] as String,
      status: map['status'] as String,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      rescheduledFrom: map['rescheduledFrom'] as String?,
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancelledBy: map['cancelledBy'] as String?,
      cancelReason: map['cancelReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'planId': planId,
        'patientId': patientId,
        'therapistId': therapistId,
        'sessionNo': sessionNo,
        'date': date,
        'slotId': slotId,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (rescheduledFrom != null) 'rescheduledFrom': rescheduledFrom,
        if (cancelledAt != null)
          'cancelledAt': Timestamp.fromDate(cancelledAt!),
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (cancelReason != null) 'cancelReason': cancelReason,
      };

  /// Helper: is this session today or in the future?
  bool get isFuture {
    final sessionDate = DateTime.parse(date);
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    return !sessionDate.isBefore(todayDateOnly);
  }

  /// Can be rescheduled/cancelled (future + active status).
  bool get isModifiable =>
      isFuture && (status == 'scheduled' || status == 'rescheduled');
}
