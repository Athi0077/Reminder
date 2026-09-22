import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/notification_provider.dart';
import '../../providers/friends_provider.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../core/constants/app_colors.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text('No notifications yet'),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final bool isUnread = !notification.read;

                return InkWell(
                  onTap: () {
                    if (isUnread) {
                      ref.read(notificationProvider.notifier).markAsRead(notification.id);
                    }
                  },
                  child: Container(
                    color: isUnread ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: notification.sender?['avatar'] != null
                              ? NetworkImage(notification.sender!['avatar'])
                              : null,
                          child: notification.sender?['avatar'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeago.format(notification.createdAt),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                              ),
                              if ((notification.type == 'friend_request' || notification.type == 'reminder_shared') && isUnread)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (notification.relatedId != null) {
                                            if (notification.type == 'friend_request') {
                                              await ref.read(friendRequestsProvider.notifier).acceptFriendRequest(notification.relatedId!);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request accepted')));
                                            } else if (notification.type == 'reminder_shared') {
                                              await ref.read(sharedReminderProvider.notifier).acceptSharedReminder(notification.relatedId!);
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shared reminder accepted')));
                                            }
                                            ref.read(notificationProvider.notifier).markAsRead(notification.id);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(80, 36),
                                        ),
                                        child: const Text('Accept'),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () async {
                                          if (notification.relatedId != null) {
                                            if (notification.type == 'friend_request') {
                                              await ref.read(friendRequestsProvider.notifier).rejectFriendRequest(notification.relatedId!);
                                            } else if (notification.type == 'reminder_shared') {
                                              await ref.read(sharedReminderProvider.notifier).declineSharedReminder(notification.relatedId!);
                                            }
                                            ref.read(notificationProvider.notifier).markAsRead(notification.id);
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(80, 36),
                                        ),
                                        child: const Text('Decline'),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
