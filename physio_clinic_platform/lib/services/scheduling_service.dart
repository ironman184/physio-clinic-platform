import 'package:cloud_functions/cloud_functions.dart';

class SchedulingService {
  static final SchedulingService _instance = SchedulingService._internal();
  factory SchedulingService() => _instance;
  SchedulingService._internal();

  final _functions = FirebaseFunctions.instance;

  /// Create a new treatment plan + sessions.
  /// [idempotencyKey] prevents duplicate plans on retry.
  Future<Map<String, dynamic>> createPlan({
    required String clinicId,
    required String patientId,
    required String therapistId,
    required int totalSessions,
    required int remainingNoShows,
    required Map<String, dynamic> scheduleRule,
    String? idempotencyKey,
  }) async {
    final result = await _functions.httpsCallable('createPlan').call({
      'clinicId': clinicId,
      'patientId': patientId,
      'therapistId': therapistId,
      'totalSessions': totalSessions,
      'remainingNoShows': remainingNoShows,
      'scheduleRule': scheduleRule,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Get therapists available for a given schedule.
  Future<Map<String, dynamic>> getAvailableTherapists({
    required String clinicId,
    required Map<String, dynamic> scheduleRule,
    required int totalSessions,
    String? patientId,
  }) async {
    final result =
        await _functions.httpsCallable('getAvailableTherapists').call({
      'clinicId': clinicId,
      'scheduleRule': scheduleRule,
      'totalSessions': totalSessions,
      if (patientId != null) 'patientId': patientId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Reschedule a single session.
  Future<Map<String, dynamic>> rescheduleSession({
    required String sessionId,
    required String newDate,
    required String newSlotId,
    required String clinicId,
  }) async {
    final result =
        await _functions.httpsCallable('rescheduleSessionFn').call({
      'sessionId': sessionId,
      'newDate': newDate,
      'newSlotId': newSlotId,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Full reschedule of a plan.
  Future<Map<String, dynamic>> fullReschedule({
    required String planId,
    required String newDay1,
    required List<String> newDays,
    required String newSlotId,
    required String clinicId,
  }) async {
    final result = await _functions.httpsCallable('fullRescheduleFn').call({
      'planId': planId,
      'newDay1': newDay1,
      'newDays': newDays,
      'newSlotId': newSlotId,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Cancel a single session.
  Future<Map<String, dynamic>> cancelSession({
    required String sessionId,
    required String reason,
    required String clinicId,
  }) async {
    final result = await _functions.httpsCallable('cancelSessionFn').call({
      'sessionId': sessionId,
      'reason': reason,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Cancel multiple sessions.
  Future<Map<String, dynamic>> cancelRange({
    required String planId,
    required List<String> sessionIds,
    required String reason,
    required String clinicId,
  }) async {
    final result = await _functions.httpsCallable('cancelRangeFn').call({
      'planId': planId,
      'sessionIds': sessionIds,
      'reason': reason,
      'clinicId': clinicId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  /// Mark session as completed or no_show.
  Future<void> markSession({
    required String sessionId,
    required String status,
    required String clinicId,
  }) async {
    await _functions.httpsCallable('markSession').call({
      'sessionId': sessionId,
      'status': status,
      'clinicId': clinicId,
    });
  }
}
