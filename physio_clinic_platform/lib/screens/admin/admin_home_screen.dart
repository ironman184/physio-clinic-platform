import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../providers/scheduling_providers.dart';
import 'create_plan_screen.dart';
import 'plan_detail_screen.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  final UserModel user;
  const AdminHomeScreen({super.key, required this.user});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Set clinicId for Riverpod providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clinicIdProvider.notifier).state = widget.user.clinicId;
    });
  }

  Future<void> _signOut() async {
    await context.read<ap.AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clinicId = widget.user.clinicId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: _signOut,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePlanScreen(clinicId: clinicId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${widget.user.fullName}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Clinic: $clinicId',
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
              flex: 1,
              child: _TodaySessionsList(clinicId: clinicId),
            ),
            const SizedBox(height: 16),
            Text(
              'Active Treatment Plans',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: _ActivePlansList(clinicId: clinicId),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySessionsList extends StatelessWidget {
  final String clinicId;
  const _TodaySessionsList({required this.clinicId});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sessions')
          .where('clinicId', isEqualTo: clinicId)
          .where('date', isEqualTo: dateStr)
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
                leading: const CircleAvatar(
                  child: Icon(Icons.event),
                ),
                title: Text('Session #${data['sessionNo']}'),
                subtitle: Text('Slot: ${data['slotId']}'),
                trailing: Chip(
                  label: Text(
                    data['status'],
                    style: const TextStyle(fontSize: 12),
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

class _ActivePlansList extends StatelessWidget {
  final String clinicId;
  const _ActivePlansList({required this.clinicId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('treatmentPlans')
          .where('clinicId', isEqualTo: clinicId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
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
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final completed = data['completedSessions'] ?? 0;
            final total = data['totalSessions'] ?? 0;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text('${index + 1}'),
                ),
                title: Text('Patient: ${data['patientId']}'),
                subtitle: Text('Progress: $completed / $total sessions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanDetailScreen(
                      planId: docs[index].id,
                      clinicId: clinicId,
                    ),
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
