class TherapistAvailabilityModel {
  final String therapistId;
  final String clinicId;
  final Map<String, List<String>> weeklySchedule;

  const TherapistAvailabilityModel({
    required this.therapistId,
    required this.clinicId,
    required this.weeklySchedule,
  });

  factory TherapistAvailabilityModel.fromMap(
    String therapistId,
    Map<String, dynamic> map,
  ) {
    final schedule = <String, List<String>>{};
    final raw = map['weeklySchedule'] as Map<String, dynamic>? ?? {};
    for (final entry in raw.entries) {
      schedule[entry.key] = List<String>.from(entry.value as List);
    }
    return TherapistAvailabilityModel(
      therapistId: therapistId,
      clinicId: map['clinicId'] as String,
      weeklySchedule: schedule,
    );
  }

  /// Returns slot IDs for a given day abbreviation (mon, tue, etc.)
  List<String> slotsForDay(String day) => weeklySchedule[day] ?? [];

  /// Whether the therapist works on a given day
  bool worksOn(String day) => slotsForDay(day).isNotEmpty;

  /// Whether the therapist works a specific slot on a specific day
  bool worksSlotOnDay(String day, String slotId) =>
      slotsForDay(day).contains(slotId);
}
