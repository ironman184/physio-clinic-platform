import 'package:cloud_firestore/cloud_firestore.dart';

import 'schedule_rule.dart';

class TreatmentPlanModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String therapistId;
  final int totalSessions;
  final int completedSessions;
  final int cancelledSessions;
  final int noShowCount;
  final int remainingNoShows;
  final String status;
  final ScheduleRule scheduleRule;
  final DateTime createdAt;
  final String createdBy;

  const TreatmentPlanModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.therapistId,
    required this.totalSessions,
    required this.completedSessions,
    required this.cancelledSessions,
    required this.noShowCount,
    required this.remainingNoShows,
    required this.status,
    required this.scheduleRule,
    required this.createdAt,
    required this.createdBy,
  });

  factory TreatmentPlanModel.fromMap(String id, Map<String, dynamic> map) {
    return TreatmentPlanModel(
      id: id,
      clinicId: map['clinicId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      totalSessions: map['totalSessions'] as int,
      completedSessions: map['completedSessions'] as int? ?? 0,
      cancelledSessions: map['cancelledSessions'] as int? ?? 0,
      noShowCount: map['noShowCount'] as int? ?? 0,
      remainingNoShows: map['remainingNoShows'] as int? ?? 2,
      status: map['status'] as String? ?? 'active',
      scheduleRule:
          ScheduleRule.fromMap(map['scheduleRule'] as Map<String, dynamic>),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'clinicId': clinicId,
        'patientId': patientId,
        'therapistId': therapistId,
        'totalSessions': totalSessions,
        'completedSessions': completedSessions,
        'cancelledSessions': cancelledSessions,
        'noShowCount': noShowCount,
        'remainingNoShows': remainingNoShows,
        'status': status,
        'scheduleRule': scheduleRule.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
}
