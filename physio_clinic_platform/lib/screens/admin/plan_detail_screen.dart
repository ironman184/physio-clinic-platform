import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/session_model.dart';
import '../../providers/scheduling_providers.dart';
import '../../services/scheduling_service.dart';

class PlanDetailScreen extends ConsumerWidget {
  final String planId;
  final String clinicId;
  const PlanDetailScreen({
    super.key,
    required this.planId,
    required this.clinicId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(planSessionsProvider(planId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Details')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          // Calculate plan summary from sessions
          final completed =
              sessions.where((s) => s.status == 'completed').length;
          final cancelled =
              sessions.where((s) => s.status == 'cancelled').length;
          final noShow =
              sessions.where((s) => s.status == 'no_show').length;
          final scheduled = sessions
              .where((s) =>
                  s.status == 'scheduled' || s.status == 'rescheduled')
              .length;

          return Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan: $planId',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _StatChip(
                            label: 'Scheduled', count: scheduled, color: Colors.blue),
                        _StatChip(
                            label: 'Completed', count: completed, color: Colors.green),
                        _StatChip(
                            label: 'Cancelled', count: cancelled, color: Colors.orange),
                        _StatChip(
                            label: 'No-Show', count: noShow, color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              // Session list
              Expanded(
                child: sessions.isEmpty
                    ? const Center(child: Text('No sessions'))
                    : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return _SessionTile(
                            session: session,
                            clinicId: clinicId,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 10,
        child: Text(
          '$count',
          style: const TextStyle(fontSize: 10, color: Colors.white),
        ),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel session;
  final String clinicId;
  const _SessionTile({required this.session, required this.clinicId});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.orange;
      case 'no_show':
        return Colors.red;
      case 'rescheduled':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _statusColor(session.status).withAlpha(30),
          child: Text(
            '${session.sessionNo}',
            style: TextStyle(
              fontSize: 12,
              color: _statusColor(session.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          session.date,
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: Text('Slot: ${session.slotId}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor(session.status).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.status,
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(session.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (session.isModifiable) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text('Mark Completed'),
                  ),
                  const PopupMenuItem(
                    value: 'no_show',
                    child: Text('Mark No-Show'),
                  ),
                  const PopupMenuItem(
                    value: 'reschedule',
                    child: Text('Reschedule'),
                  ),
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel'),
                  ),
                ],
                onSelected: (action) =>
                    _handleAction(context, action, session),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    String action,
    SessionModel session,
  ) async {
    final service = SchedulingService();

    switch (action) {
      case 'complete':
        await _confirmAndExecute(
          context,
          title: 'Mark Completed?',
          message: 'Mark session #${session.sessionNo} as completed?',
          onConfirm: () => service.markSession(
            sessionId: session.id,
            status: 'completed',
            clinicId: clinicId,
          ),
        );
      case 'no_show':
        await _confirmAndExecute(
          context,
          title: 'Mark No-Show?',
          message:
              'Mark session #${session.sessionNo} as no-show? A replacement session will be added.',
          onConfirm: () => service.markSession(
            sessionId: session.id,
            status: 'no_show',
            clinicId: clinicId,
          ),
        );
      case 'cancel':
        final reason = await _showReasonDialog(context);
        if (reason != null && context.mounted) {
          try {
            await service.cancelSession(
              sessionId: session.id,
              reason: reason,
              clinicId: clinicId,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session cancelled')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        }
      case 'reschedule':
        await _showRescheduleDialog(context, session);
    }
  }

  Future<void> _confirmAndExecute(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await onConfirm();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Done')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<String?> _showReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason for cancellation',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRescheduleDialog(
    BuildContext context,
    SessionModel session,
  ) async {
    DateTime? newDate;
    // Simple reschedule: pick new date, keep same slot
    newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null && context.mounted) {
      final dateStr =
          '${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
      try {
        await SchedulingService().rescheduleSession(
          sessionId: session.id,
          newDate: dateStr,
          newSlotId: session.slotId, // Keep same slot
          clinicId: clinicId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session rescheduled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
