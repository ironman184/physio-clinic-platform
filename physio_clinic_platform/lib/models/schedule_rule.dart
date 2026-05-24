class ScheduleRule {
  final String frequency;
  final List<String> days;
  final String day1;
  final String slotId;

  const ScheduleRule({
    required this.frequency,
    required this.days,
    required this.day1,
    required this.slotId,
  });

  factory ScheduleRule.fromMap(Map<String, dynamic> map) {
    return ScheduleRule(
      frequency: map['frequency'] as String,
      days: List<String>.from(map['days'] as List),
      day1: map['day1'] as String,
      slotId: map['slotId'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'frequency': frequency,
        'days': days,
        'day1': day1,
        'slotId': slotId,
      };
}
