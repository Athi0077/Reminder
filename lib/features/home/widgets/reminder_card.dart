import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/reminder.dart';
import '../../../models/shared_reminder.dart';
import '../../../widgets/common/app_card.dart';

class ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context) {
    final timeString = DateFormat.jm().format(reminder.dateTime);
    final isToday = _isToday(reminder.dateTime);
    final dateString = isToday ? 'Today' : DateFormat('MMM d, y').format(reminder.dateTime);

    Color statusColor;
    if (reminder.status == ReminderStatus.completed) {
      statusColor = AppColors.success;
    } else if (reminder.dateTime.isBefore(DateTime.now()) && reminder.status != ReminderStatus.completed) {
      statusColor = AppColors.danger; // Overdue
    } else {
      statusColor = AppColors.primary; // Upcoming
    }

    final bool isShared = reminder is SharedReminder;
    SharedReminder? sharedReminder = isShared ? reminder as SharedReminder : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          if (isShared) {
            context.push('/shared-reminder/${reminder.id}');
          } else {
            context.push('/reminder/${reminder.id}');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(reminder.category),
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            decoration: reminder.status == ReminderStatus.completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeString,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• $dateString • ${reminder.category.displayName}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (isShared && sharedReminder != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.group_outlined, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            _getSharedText(sharedReminder),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ] else if (reminder.status != ReminderStatus.completed) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.notifications_none, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            reminder.alertBefore.displayName,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSharedText(SharedReminder sr) {
    if (sr.createdBy != 'me') {
      return 'Shared by ${sr.creatorName}';
    }
    
    // Created by me
    final others = sr.participants.where((p) => p.userId != 'me').toList();
    if (others.isEmpty) return 'Shared';
    
    if (others.length == 1) {
      return 'Shared with ${others.first.name}';
    } else {
      return 'Shared with ${others.first.name} + ${others.length - 1}';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  IconData _getCategoryIcon(ReminderCategory category) {
    switch (category) {
      case ReminderCategory.personal:
        return Icons.person_outline;
      case ReminderCategory.work:
        return Icons.work_outline;
      case ReminderCategory.study:
        return Icons.menu_book_outlined;
      case ReminderCategory.health:
        return Icons.favorite_border;
      case ReminderCategory.other:
        return Icons.tag;
    }
  }
}
