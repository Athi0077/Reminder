import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_provider.dart';
import '../../widgets/common/app_button.dart';

class ReminderDetailsScreen extends ConsumerWidget {
  final String reminderId;

  const ReminderDetailsScreen({super.key, required this.reminderId});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('Are you sure you want to delete this reminder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(reminderProvider.notifier).deleteReminder(reminderId);
              Navigator.pop(context); // Close dialog
              context.go('/home'); // Go home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reminder deleted.')),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderList = ref.watch(reminderProvider);
    final reminder = reminderList.cast<Reminder?>().firstWhere(
          (r) => r?.id == reminderId,
          orElse: () => null,
        );

    if (reminder == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Reminder not found')),
      );
    }

    final isCompleted = reminder.status == ReminderStatus.completed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/edit-reminder/$reminderId'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reminder.category.displayName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Completed',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              reminder.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
            ),
            if (reminder.description != null && reminder.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                reminder.description!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            const SizedBox(height: 32),
            _buildInfoRow(
              context,
              Icons.calendar_today_outlined,
              'Date',
              DateFormat('EEEE, MMMM d, yyyy').format(reminder.dateTime),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.access_time,
              'Time',
              DateFormat.jm().format(reminder.dateTime),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.notifications_none,
              'Alert',
              reminder.alertBefore.displayName,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.repeat,
              'Repeat',
              reminder.repeat.displayName,
            ),
            const SizedBox(height: 48),
            if (!isCompleted)
              AppButton(
                text: 'Mark as Done',
                onPressed: () {
                  ref.read(reminderProvider.notifier).markAsCompleted(reminderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reminder completed 🎉')),
                  );
                  context.pop(); // Go back
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
