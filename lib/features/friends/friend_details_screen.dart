import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/friends_provider.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_card.dart';

class FriendDetailsScreen extends ConsumerWidget {
  final String friendId;

  const FriendDetailsScreen({super.key, required this.friendId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final friend = friends.cast().firstWhere(
          (f) => f.id == friendId,
          orElse: () => null,
        );

    if (friend == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Friend not found')),
      );
    }

    final sharedReminders = ref.watch(sharedReminderProvider).where((r) {
      return (r.createdBy == 'me' && r.participants.any((p) => p.userId == friend.id)) ||
             (r.createdBy == friend.id && r.participants.any((p) => p.userId == 'me'));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          friend.name[0],
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 40,
                          ),
                        ),
                      ),
                      if (friend.isOnline)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    friend.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    friend.email,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Friend since 2026',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '${sharedReminders.length}',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Shared Reminders'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '12',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: AppColors.success,
                              ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Completed Together'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            AppButton(
              text: 'Create Shared Reminder',
              onPressed: () {
                // Route to create shared reminder and pre-select friend if possible
                context.push('/create-shared-reminder?friendId=${friend.id}');
              },
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem(
              context,
              '${friend.name} accepted:',
              'Team Meeting',
              '2 minutes ago',
              Icons.check_circle_outline,
              AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              context,
              '${friend.name} completed:',
              'Project Review',
              '1 hour ago',
              Icons.done_all,
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, String action, String task, String time, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  task,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
