class SlotModel {
  final String id;
  final String start;
  final String end;

  const SlotModel({
    required this.id,
    required this.start,
    required this.end,
  });

  factory SlotModel.fromMap(String id, Map<String, dynamic> map) {
    return SlotModel(
      id: id,
      start: map['start'] as String,
      end: map['end'] as String,
    );
  }

  Map<String, dynamic> toMap() => {
        'start': start,
        'end': end,
      };

  String get display => '$start – $end';
}
