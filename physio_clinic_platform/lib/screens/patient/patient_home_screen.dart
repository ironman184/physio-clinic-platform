import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as ap;

class PatientHomeScreen extends StatelessWidget {
  final UserModel user;
  const PatientHomeScreen({super.key, required this.user});

  String get _todayStr {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Treatment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => context.read<ap.AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.firstName}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Active plans section
            Text(
              'Active Plans',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: _PatientPlans(
                clinicId: user.clinicId,
                patientId: user.uid,
              ),
            ),
            const SizedBox(height: 24),

            // Upcoming sessions
            Text(
              'Upcoming Sessions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _PatientUpcomingSessions(
                clinicId: user.clinicId,
                patientId: user.uid,
                fromDate: _todayStr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientPlans extends StatelessWidget {
  final String clinicId;
  final String patientId;
  const _PatientPlans({required this.clinicId, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatmentPlans')
          .where('clinicId', isEqualTo: clinicId)
          .where('patientId', isEqualTo: patientId)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No active plans',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final completed = data['completedSessions'] ?? 0;
            final total = data['totalSessions'] ?? 0;
            return Container(
              width: 200,
              margin: const EdgeInsets.only(right: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Plan',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: total > 0 ? completed / total : 0,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completed / $total sessions completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _PatientUpcomingSessions extends StatelessWidget {
  final String clinicId;
  final String patientId;
  final String fromDate;
  const _PatientUpcomingSessions({
    required this.clinicId,
    required this.patientId,
    required this.fromDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clinicId', isEqualTo: clinicId)
          .where('patientId', isEqualTo: patientId)
          .where('date', isGreaterThanOrEqualTo: fromDate)
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
                  child: Text('${data['sessionNo']}'),
                ),
                title: Text('${data['date']}'),
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
