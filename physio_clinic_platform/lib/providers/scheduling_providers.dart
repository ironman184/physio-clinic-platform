import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/scheduling_service.dart';
import '../services/session_query_service.dart';
import '../models/session_model.dart';
import '../models/treatment_plan_model.dart';
import '../models/slot_model.dart';

// ── Service singletons ──────────────────────────────────────────────────────

final schedulingServiceProvider = Provider((_) => SchedulingService());
final sessionQueryServiceProvider = Provider((_) => SessionQueryService());

// ── Bridge: clinicId from auth (set once when user profile loads) ────────────

final clinicIdProvider = StateProvider<String?>((_) => null);

// ── Selected state for plan creation form ────────────────────────────────────

final selectedPatientProvider = StateProvider<String?>((_) => null);
final selectedFrequencyProvider = StateProvider<String>((_) => 'thrice');
final selectedDaysProvider = StateProvider<List<String>>((_) => []);
final selectedDay1Provider = StateProvider<String?>((_) => null);
final selectedSlotProvider = StateProvider<String?>((_) => null);
final totalSessionsProvider = StateProvider<int>((_) => 12);

// ── Available therapists (async, depends on selections above) ────────────────

final availableTherapistsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final clinicId = ref.watch(clinicIdProvider);
  final day1 = ref.watch(selectedDay1Provider);
  final days = ref.watch(selectedDaysProvider);
  final slot = ref.watch(selectedSlotProvider);
  final total = ref.watch(totalSessionsProvider);
  final patientId = ref.watch(selectedPatientProvider);

  if (clinicId == null || day1 == null || days.isEmpty || slot == null) {
    return [];
  }

  final service = ref.read(schedulingServiceProvider);
  final result = await service.getAvailableTherapists(
    clinicId: clinicId,
    scheduleRule: {
      'frequency': ref.read(selectedFrequencyProvider),
      'days': days,
      'day1': day1,
      'slotId': slot,
    },
    totalSessions: total,
    patientId: patientId,
  );

  return List<Map<String, dynamic>>.from(result['therapists'] ?? []);
});

// ── Plan creation loading state ──────────────────────────────────────────────

final createPlanLoadingProvider = StateProvider<bool>((_) => false);

// ── Slots (global, cached for the session) ───────────────────────────────────

final slotsProvider = FutureProvider<List<SlotModel>>((ref) {
  final service = ref.read(sessionQueryServiceProvider);
  return service.getAllSlots();
});

// ── Patient sessions stream ──────────────────────────────────────────────────

final patientSessionsProvider = StreamProvider.autoDispose
    .family<List<SessionModel>, ({String clinicId, String patientId})>(
  (ref, params) {
    final service = ref.read(sessionQueryServiceProvider);
    return service.patientSessions(params.clinicId, params.patientId);
  },
);

// ── Plan sessions stream ─────────────────────────────────────────────────────

final planSessionsProvider =
    StreamProvider.autoDispose.family<List<SessionModel>, String>(
  (ref, planId) {
    final service = ref.read(sessionQueryServiceProvider);
    return service.planSessions(planId);
  },
);

// ── Patient plans stream ─────────────────────────────────────────────────────

final patientPlansProvider = StreamProvider.autoDispose
    .family<List<TreatmentPlanModel>, ({String clinicId, String patientId})>(
  (ref, params) {
    final service = ref.read(sessionQueryServiceProvider);
    return service.patientPlans(params.clinicId, params.patientId);
  },
);
