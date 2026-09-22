import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/shared_reminder_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/summary_cards.dart';
import 'widgets/reminder_card.dart';
import '../../providers/notification_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final upcomingPersonal = ref.watch(upcomingRemindersProvider);
    final sharedByMe = ref.watch(sharedByMeProvider);
    final sharedWithMe = ref.watch(sharedWithMeProvider);
    final userState = ref.watch(userProvider);
    final notificationState = ref.watch(notificationProvider);
    final profile = userState.profile;
    
    final allUpcoming = [...upcomingPersonal, ...sharedByMe, ...sharedWithMe]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final todayString = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: profile?['avatar'] != null ? NetworkImage(profile!['avatar']) : null,
                              child: profile?['avatar'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi ${profile?['name']?.split(' ')[0] ?? 'User'} 👋',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  "Let's make sure nothing gets forgotten.",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () async {
                                await context.push('/notifications');
                                ref.read(notificationProvider.notifier).fetchUnreadCount();
                              },
                              icon: const Icon(Icons.notifications_none),
                            ),
                            if (notificationState.unreadCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${notificationState.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      todayString,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const SummaryCards(),
                    const SizedBox(height: 32),
                    const SizedBox(height: 32),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Create',
                            icon: Icons.add_alarm,
                            onTap: () => context.push('/create-reminder'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Share',
                            icon: Icons.share_outlined,
                            onTap: () => context.push('/create-shared-reminder'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            title: 'Friend',
                            icon: Icons.person_add_outlined,
                            onTap: () => context.push('/add-friend'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () => context.push('/calendar'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (allUpcoming.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Nothing scheduled 🎉',
                  description: 'Your day is clear.\nTap + to create a reminder.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return ReminderCard(reminder: allUpcoming[index]);
                    },
                    childCount: allUpcoming.length,
                  ),
                ),
              ),
            // Bottom padding for FAB
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-reminder'),
        backgroundColor: AppColors.primary,
        tooltip: 'Create Reminder',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
