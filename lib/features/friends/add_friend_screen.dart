import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/friends_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../models/friend.dart';

class AddFriendScreen extends ConsumerStatefulWidget {
  const AddFriendScreen({super.key});

  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  final _searchController = TextEditingController();
  List<Friend> _searchResults = [];
  final Set<String> _sentRequests = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    // Simulate searching
    final allUsers = await ref.read(friendSearchProvider(query).future);
    final results = allUsers.where((u) => u.name.toLowerCase().contains(query.toLowerCase()) || u.email.toLowerCase().contains(query.toLowerCase())).toList();
    
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Search for people to add'
                            : 'No results found',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        final isSent = _sentRequests.contains(user.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    user.name[0],
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      Text(
                                        user.email,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSent)
                                  const Chip(
                                    label: Text('Request Sent', style: TextStyle(color: AppColors.success)),
                                    backgroundColor: Color(0x1A16A34A), // Success with alpha
                                    side: BorderSide.none,
                                  )
                                else
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await ref.read(friendRequestsProvider.notifier).sendFriendRequest(user.id);
                                        setState(() {
                                          _sentRequests.add(user.id);
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Friend request sent successfully.')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Failed to send request. You may already have a pending request.')),
                                        );
                                      }
                                    },
                                    child: const Text('Send Request'),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
