import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/session_model.dart';
import '../models/treatment_plan_model.dart';
import '../models/slot_model.dart';

class SessionQueryService {
  static final SessionQueryService _instance = SessionQueryService._internal();
  factory SessionQueryService() => _instance;
  SessionQueryService._internal();

  final _db = FirebaseFirestore.instance;

  /// Stream sessions for a patient in a clinic.
  Stream<List<SessionModel>> patientSessions(
      String clinicId, String patientId) {
    return _db
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('date')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream sessions for a therapist on a specific date.
  Stream<List<SessionModel>> therapistDaySessions(
    String clinicId,
    String therapistId,
    String date,
  ) {
    return _db
        .collection('sessions')
        .where('clinicId', isEqualTo: clinicId)
        .where('therapistId', isEqualTo: therapistId)
        .where('date', isEqualTo: date)
        .where('status', whereIn: ['scheduled', 'rescheduled'])
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream all sessions for a plan.
  Stream<List<SessionModel>> planSessions(String planId) {
    return _db
        .collection('sessions')
        .where('planId', isEqualTo: planId)
        .orderBy('sessionNo')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SessionModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Stream active treatment plans for a patient.
  Stream<List<TreatmentPlanModel>> patientPlans(
    String clinicId,
    String patientId,
  ) {
    return _db
        .collection('treatmentPlans')
        .where('clinicId', isEqualTo: clinicId)
        .where('patientId', isEqualTo: patientId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => TreatmentPlanModel.fromMap(d.id, d.data()))
            .toList());
  }

  /// Get all slots (global, rarely changes).
  Future<List<SlotModel>> getAllSlots() async {
    final snap = await _db.collection('slots').get();
    return snap.docs
        .map((d) => SlotModel.fromMap(d.id, d.data()))
        .toList();
  }
}
