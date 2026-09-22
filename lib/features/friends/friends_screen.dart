import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/friend.dart';
import '../../providers/friends_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/app_button.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final requests = ref.watch(friendRequestsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Friends'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => context.push('/add-friend'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'My Friends'),
              Tab(text: 'Requests (${requests.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Friends Tab
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search friends...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                if (friends.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.people_outline,
                      title: 'No friends yet',
                      description: 'Add friends to start sharing reminders.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildFriendCard(context, friends[index]);
                        },
                        childCount: friends.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
            // Requests Tab
            CustomScrollView(
              slivers: [
                if (requests.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.person_add_disabled,
                      title: 'No pending requests',
                      description: 'You have no incoming friend requests.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(24.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return _buildRequestCard(context, ref, requests[index]);
                        },
                        childCount: requests.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, WidgetRef ref, FriendRequest request) {
    // We should parse the actual sender from the request if the provider stores it.
    // For now we assume the provider parses sender name if available.
    // If not, we just show a generic message.
    final name = 'Someone'; // We can enhance the model to include sender details

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$name sent you a friend request.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Decline',
                    isSecondary: true,
                    onPressed: () async {
                      await ref.read(friendRequestsProvider.notifier).rejectFriendRequest(request.id);
                      ref.read(notificationProvider.notifier).fetchUnreadCount();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Accept',
                    onPressed: () async {
                      await ref.read(friendRequestsProvider.notifier).acceptFriendRequest(request.id);
                      ref.read(notificationProvider.notifier).fetchUnreadCount();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request accepted! 🎉')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Friend friend) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => context.push('/friends/${friend.id}'),
        borderRadius: BorderRadius.circular(20),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      friend.name[0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (friend.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      friend.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (friend.status.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        friend.status,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
