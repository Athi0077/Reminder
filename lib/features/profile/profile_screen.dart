import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_loader.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final profile = userState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userState.isLoading && profile == null
          ? const AppLoader()
          : profile == null
              ? const Center(child: Text('Failed to load profile.'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(userProvider.notifier).fetchProfile(),
                  child: ListView(
                    padding: const EdgeInsets.all(24.0),
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: profile['avatar'] != null
                                  ? NetworkImage(profile['avatar'])
                                  : null,
                              child: profile['avatar'] == null
                                  ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              profile['name'] ?? 'User',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile['email'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/profile/edit'),
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Statistics
                      Text(
                        'Statistics',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            context,
                            'Total Reminders',
                            profile['stats']?['totalReminders']?.toString() ?? '0',
                            Icons.list_alt,
                          ),
                          _buildStatCard(
                            context,
                            'Completed',
                            profile['stats']?['completedReminders']?.toString() ?? '0',
                            Icons.check_circle_outline,
                          ),
                          _buildStatCard(
                            context,
                            'Shared',
                            profile['stats']?['sharedReminders']?.toString() ?? '0',
                            Icons.share_outlined,
                          ),
                          _buildStatCard(
                            context,
                            'Friends',
                            profile['stats']?['friendsCount']?.toString() ?? '0',
                            Icons.people_outline,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
