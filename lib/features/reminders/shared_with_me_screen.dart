import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/shared_reminder.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/empty_state.dart';

class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedReminders = ref.watch(sharedWithMeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared With Me'),
      ),
      body: sharedReminders.isEmpty
          ? const EmptyState(
              icon: Icons.group_outlined,
              title: 'No shared reminders',
              description: 'When someone shares a reminder with you, it will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: sharedReminders.length,
              itemBuilder: (context, index) {
                final reminder = sharedReminders[index];
                final me = reminder.participants.firstWhere((p) => p.userId == 'me', orElse: () => const Participant(userId: 'me', name: 'Me'));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Created by: ${reminder.creatorName}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('MMM d, y').format(reminder.dateTime)} • ${DateFormat.jm().format(reminder.dateTime)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '"${reminder.description!}"',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (me.status == ParticipantStatus.pending)
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  text: 'Decline',
                                  isSecondary: true,
                                  onPressed: () {
                                    _confirmDecline(context, ref, reminder.id);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppButton(
                                  text: 'Accept',
                                  onPressed: () {
                                    ref.read(sharedReminderProvider.notifier).acceptSharedReminder(reminder.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reminder accepted.')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Accepted',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => context.push('/shared-reminder/${reminder.id}'),
                                child: const Text('View Details'),
                              ),
                            ],
                          )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDecline(BuildContext context, WidgetRef ref, String reminderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Reminder?'),
        content: const Text("You won't receive reminders for this shared task."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sharedReminderProvider.notifier).declineSharedReminder(reminderId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder declined.')),
              );
            },
            child: const Text('Decline', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
