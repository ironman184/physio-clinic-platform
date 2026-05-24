import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TherapistCalendarScreen extends StatefulWidget {
  final String clinicId;
  const TherapistCalendarScreen({super.key, required this.clinicId});

  @override
  State<TherapistCalendarScreen> createState() =>
      _TherapistCalendarScreenState();
}

class _TherapistCalendarScreenState extends State<TherapistCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTherapistId;

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Therapist Calendar')),
      body: Column(
        children: [
          // Date picker row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1));
                  }),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dateStr,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _selectedDate =
                        _selectedDate.add(const Duration(days: 1));
                  }),
                ),
              ],
            ),
          ),

          // Therapist selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _TherapistDropdown(
              clinicId: widget.clinicId,
              selected: _selectedTherapistId,
              onChanged: (id, name) => setState(() {
                _selectedTherapistId = id;
              }),
            ),
          ),
          const SizedBox(height: 8),

          // Sessions list
          Expanded(
            child: _selectedTherapistId == null
                ? Center(
                    child: Text(
                      'Select a therapist to view schedule',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                : _SessionsForDay(
                    clinicId: widget.clinicId,
                    therapistId: _selectedTherapistId!,
                    date: _dateStr,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }
}

class _TherapistDropdown extends StatelessWidget {
  final String clinicId;
  final String? selected;
  final void Function(String id, String name) onChanged;

  const _TherapistDropdown({
    required this.clinicId,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('clinicId', isEqualTo: clinicId)
          .where('role', isEqualTo: 'therapist')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return DropdownButtonFormField<String>(
          value: selected,
          decoration: const InputDecoration(
            labelText: 'Therapist',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final name =
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            return DropdownMenuItem(value: d.id, child: Text(name));
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final doc = docs.firstWhere((d) => d.id == id);
            final data = doc.data() as Map<String, dynamic>;
            final name =
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
            onChanged(id, name);
          },
        );
      },
    );
  }
}

class _SessionsForDay extends StatelessWidget {
  final String clinicId;
  final String therapistId;
  final String date;
  const _SessionsForDay({
    required this.clinicId,
    required this.therapistId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clinicId', isEqualTo: clinicId)
          .where('therapistId', isEqualTo: therapistId)
          .where('date', isEqualTo: date)
          .where('status', whereIn: ['scheduled', 'rescheduled']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No sessions on this day',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${data['sessionNo']}'),
                ),
                title: Text('Patient: ${data['patientId']}'),
                subtitle: Text('Slot: ${data['slotId']}'),
                trailing: Chip(
                  label: Text(
                    data['status'] ?? '',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
