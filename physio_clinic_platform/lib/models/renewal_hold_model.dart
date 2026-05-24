import 'package:cloud_firestore/cloud_firestore.dart';

class RenewalHoldModel {
  final String id;
  final String clinicId;
  final String patientId;
  final String therapistId;
  final String planId;
  final String slotId;
  final List<String> days;
  final DateTime createdAt;
  final String expiryDate; // YYYY-MM-DD
  final String status;

  const RenewalHoldModel({
    required this.id,
    required this.clinicId,
    required this.patientId,
    required this.therapistId,
    required this.planId,
    required this.slotId,
    required this.days,
    required this.createdAt,
    required this.expiryDate,
    required this.status,
  });

  factory RenewalHoldModel.fromMap(String id, Map<String, dynamic> map) {
    return RenewalHoldModel(
      id: id,
      clinicId: map['clinicId'] as String,
      patientId: map['patientId'] as String,
      therapistId: map['therapistId'] as String,
      planId: map['planId'] as String,
      slotId: map['slotId'] as String,
      days: List<String>.from(map['days'] as List),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      expiryDate: map['expiryDate'] as String,
      status: map['status'] as String,
    );
  }

  bool get isExpired => DateTime.parse(expiryDate).isBefore(DateTime.now());
}
