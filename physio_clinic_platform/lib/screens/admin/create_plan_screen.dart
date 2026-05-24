import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../providers/scheduling_providers.dart';
import '../../services/scheduling_service.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  final String clinicId;
  const CreatePlanScreen({super.key, required this.clinicId});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Patient selection
  String? _selectedPatientId;
  String? _selectedPatientName;

  // Step 2: Schedule config
  String _frequency = 'thrice';
  final List<String> _selectedDays = [];
  DateTime? _day1;
  String? _selectedSlotId;
  int _totalSessions = 12;
  int _remainingNoShows = 2;

  // Step 3: Therapist selection
  String? _selectedTherapistId;
  String? _selectedTherapistName;

  // Loading
  bool _isCreating = false;

  static const _allDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
  static const _dayLabels = {
    'mon': 'Mon',
    'tue': 'Tue',
    'wed': 'Wed',
    'thu': 'Thu',
    'fri': 'Fri',
    'sat': 'Sat',
    'sun': 'Sun',
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool get _canProceedStep1 => _selectedPatientId != null;

  bool get _canProceedStep2 =>
      _selectedDays.isNotEmpty && _day1 != null && _selectedSlotId != null;

  bool get _canProceedStep3 => _selectedTherapistId != null;

  Future<void> _createPlan() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final day1Str =
          '${_day1!.year}-${_day1!.month.toString().padLeft(2, '0')}-${_day1!.day.toString().padLeft(2, '0')}';

      await SchedulingService().createPlan(
        clinicId: widget.clinicId,
        patientId: _selectedPatientId!,
        therapistId: _selectedTherapistId!,
        totalSessions: _totalSessions,
        remainingNoShows: _remainingNoShows,
        scheduleRule: {
          'frequency': _frequency,
          'days': _selectedDays,
          'day1': day1Str,
          'slotId': _selectedSlotId,
        },
        idempotencyKey: const Uuid().v4(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treatment plan created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Treatment Plan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1PatientSelection(),
                _buildStep2ScheduleConfig(),
                _buildStep3TherapistSelection(),
                _buildStep4Confirmation(),
              ],
            ),
          ),
          _buildBottomNav(theme),
        ],
      ),
    );
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            OutlinedButton(
              onPressed: _prevStep,
              child: const Text('Back'),
            ),
          const Spacer(),
          if (_currentStep < 3)
            FilledButton(
              onPressed: _canProceedCurrentStep ? _nextStep : null,
              child: const Text('Next'),
            ),
          if (_currentStep == 3)
            FilledButton(
              onPressed: _isCreating ? null : _createPlan,
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Plan'),
            ),
        ],
      ),
    );
  }

  bool get _canProceedCurrentStep {
    switch (_currentStep) {
      case 0:
        return _canProceedStep1;
      case 1:
        return _canProceedStep2;
      case 2:
        return _canProceedStep3;
      default:
        return true;
    }
  }

  // ─── Step 1: Patient Selection ──────────────────────────────────────────────

  Widget _buildStep1PatientSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Select Patient',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('clinicId', isEqualTo: widget.clinicId)
                .where('role', isEqualTo: 'patient')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No patients found'));
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final name =
                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'
                            .trim();
                    final isSelected = docs[index].id == _selectedPatientId;
                    return Card(
                      color: isSelected
                          ? Theme.of(context)
                              .colorScheme
                              .primaryContainer
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(data['phoneNumber'] ?? ''),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedPatientId = docs[index].id;
                            _selectedPatientName = name;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Schedule Configuration ─────────────────────────────────────────

  Widget _buildStep2ScheduleConfig() {
    final slotsAsync = ref.watch(slotsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Configure Schedule',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Frequency
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(
              labelText: 'Frequency',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'once', child: Text('Once per week')),
              DropdownMenuItem(value: 'twice', child: Text('Twice per week')),
              DropdownMenuItem(value: 'thrice', child: Text('Thrice per week')),
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
            ],
            onChanged: (v) => setState(() => _frequency = v ?? 'thrice'),
          ),
          const SizedBox(height: 16),

          // Days
          const Text('Select Days:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _allDays.map((day) {
              final selected = _selectedDays.contains(day);
              return FilterChip(
                label: Text(_dayLabels[day]!),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selectedDays.add(day);
                    } else {
                      _selectedDays.remove(day);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Day 1
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_day1 == null
                ? 'Select start date'
                : 'Start: ${_day1!.year}-${_day1!.month.toString().padLeft(2, '0')}-${_day1!.day.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _day1 = picked);
            },
          ),
          const SizedBox(height: 16),

          // Slot
          slotsAsync.when(
            data: (slots) => DropdownButtonFormField<String>(
              value: _selectedSlotId,
              decoration: const InputDecoration(
                labelText: 'Time Slot',
                border: OutlineInputBorder(),
              ),
              items: slots
                  .map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.display),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedSlotId = v),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error loading slots: $e'),
          ),
          const SizedBox(height: 16),

          // Total sessions
          TextFormField(
            initialValue: '$_totalSessions',
            decoration: const InputDecoration(
              labelText: 'Total Sessions',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n > 0) setState(() => _totalSessions = n);
            },
          ),
          const SizedBox(height: 16),

          // No-show allowance
          TextFormField(
            initialValue: '$_remainingNoShows',
            decoration: const InputDecoration(
              labelText: 'Allowed No-Shows',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = int.tryParse(v);
              if (n != null && n >= 0) setState(() => _remainingNoShows = n);
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 3: Therapist Selection ────────────────────────────────────────────

  Widget _buildStep3TherapistSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Select Therapist',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Showing therapists available for all scheduled dates:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _TherapistList(
            clinicId: widget.clinicId,
            day1: _day1,
            days: _selectedDays,
            slotId: _selectedSlotId,
            totalSessions: _totalSessions,
            frequency: _frequency,
            patientId: _selectedPatientId,
            selectedTherapistId: _selectedTherapistId,
            onSelected: (id, name) {
              setState(() {
                _selectedTherapistId = id;
                _selectedTherapistName = name;
              });
            },
          )),
        ],
      ),
    );
  }

  // ─── Step 4: Confirmation ───────────────────────────────────────────────────

  Widget _buildStep4Confirmation() {
    final theme = Theme.of(context);
    final day1Str = _day1 != null
        ? '${_day1!.year}-${_day1!.month.toString().padLeft(2, '0')}-${_day1!.day.toString().padLeft(2, '0')}'
        : '-';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Confirm', style: theme.textTheme.titleLarge),
          const SizedBox(height: 24),
          _confirmRow('Patient', _selectedPatientName ?? '-'),
          _confirmRow('Therapist', _selectedTherapistName ?? '-'),
          _confirmRow('Frequency', _frequency),
          _confirmRow('Days', _selectedDays.join(', ')),
          _confirmRow('Start Date', day1Str),
          _confirmRow('Time Slot', _selectedSlotId ?? '-'),
          _confirmRow('Total Sessions', '$_totalSessions'),
          _confirmRow('No-Show Allowance', '$_remainingNoShows'),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// ─── Therapist List Widget ────────────────────────────────────────────────────

class _TherapistList extends StatefulWidget {
  final String clinicId;
  final DateTime? day1;
  final List<String> days;
  final String? slotId;
  final int totalSessions;
  final String frequency;
  final String? patientId;
  final String? selectedTherapistId;
  final void Function(String id, String name) onSelected;

  const _TherapistList({
    required this.clinicId,
    required this.day1,
    required this.days,
    required this.slotId,
    required this.totalSessions,
    required this.frequency,
    required this.patientId,
    required this.selectedTherapistId,
    required this.onSelected,
  });

  @override
  State<_TherapistList> createState() => _TherapistListState();
}

class _TherapistListState extends State<_TherapistList> {
  List<Map<String, dynamic>>? _therapists;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTherapists();
  }

  Future<void> _loadTherapists() async {
    if (widget.day1 == null || widget.days.isEmpty || widget.slotId == null) {
      setState(() {
        _therapists = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final day1Str =
          '${widget.day1!.year}-${widget.day1!.month.toString().padLeft(2, '0')}-${widget.day1!.day.toString().padLeft(2, '0')}';

      final result = await SchedulingService().getAvailableTherapists(
        clinicId: widget.clinicId,
        scheduleRule: {
          'frequency': widget.frequency,
          'days': widget.days,
          'day1': day1Str,
          'slotId': widget.slotId,
        },
        totalSessions: widget.totalSessions,
        patientId: widget.patientId,
      );
      setState(() {
        _therapists =
            List<Map<String, dynamic>>.from(result['therapists'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_therapists == null || _therapists!.isEmpty) {
      return const Center(
        child: Text('No therapists available for this schedule'),
      );
    }

    return ListView.builder(
      itemCount: _therapists!.length,
      itemBuilder: (context, index) {
        final t = _therapists![index];
        final name = '${t['firstName'] ?? ''} ${t['lastName'] ?? ''}'.trim();
        final isSelected = t['id'] == widget.selectedTherapistId;
        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
            ),
            title: Text(name),
            trailing: isSelected ? const Icon(Icons.check_circle) : null,
            onTap: () => widget.onSelected(t['id'] as String, name),
          ),
        );
      },
    );
  }
}
