import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as ap;

class TherapistHomeScreen extends StatefulWidget {
  final UserModel user;
  const TherapistHomeScreen({super.key, required this.user});

  @override
  State<TherapistHomeScreen> createState() => _TherapistHomeScreenState();
}

class _TherapistHomeScreenState extends State<TherapistHomeScreen> {
  Future<void> _signOut() async {
    await context.read<ap.AuthProvider>().signOut();
  }

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${widget.user.firstName}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Today: $_todayStr',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Today\'s Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _TherapistSessions(
                clinicId: widget.user.clinicId,
                therapistId: widget.user.uid,
                date: _todayStr,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upcoming Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _UpcomingSessions(
                clinicId: widget.user.clinicId,
                therapistId: widget.user.uid,
                afterDate: _todayStr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TherapistSessions extends StatelessWidget {
  final String clinicId;
  final String therapistId;
  final String date;
  const _TherapistSessions({
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
              'No sessions today',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
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

class _UpcomingSessions extends StatelessWidget {
  final String clinicId;
  final String therapistId;
  final String afterDate;
  const _UpcomingSessions({
    required this.clinicId,
    required this.therapistId,
    required this.afterDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clinicId', isEqualTo: clinicId)
          .where('therapistId', isEqualTo: therapistId)
          .where('date', isGreaterThan: afterDate)
          .where('status', whereIn: ['scheduled', 'rescheduled'])
          .orderBy('date')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No upcoming sessions',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Text('${data['sessionNo']}'),
                ),
                title: Text('${data['date']}'),
                subtitle: Text(
                    'Patient: ${data['patientId']} • Slot: ${data['slotId']}'),
              ),
            );
          },
        );
      },
    );
  }
}
