import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/shared_reminder_provider.dart';
class SummaryCards extends ConsumerWidget {
  const SummaryCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allReminders = ref.watch(reminderProvider);
    final myRemindersCount = allReminders.length;
    final sharedWithMeCount = ref.watch(sharedWithMeProvider).length;
    final completedCount = ref.watch(completedRemindersProvider).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 768) {
          return Row(
            children: [
              Expanded(child: _buildCard(context, 'My Reminders', myRemindersCount.toString(), Icons.layers_outlined, AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildCard(context, 'Shared With Me', sharedWithMeCount.toString(), Icons.group_outlined, AppColors.warning)),
              const SizedBox(width: 16),
              Expanded(child: _buildCard(context, 'Completed', completedCount.toString(), Icons.check_circle_outline, AppColors.success)),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildCard(context, 'My Reminders', myRemindersCount.toString(), Icons.layers_outlined, AppColors.primary)),
                const SizedBox(width: 16),
                Expanded(child: _buildCard(context, 'Shared With Me', sharedWithMeCount.toString(), Icons.group_outlined, AppColors.warning)),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(context, 'Completed', completedCount.toString(), Icons.check_circle_outline, AppColors.success),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                count,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
