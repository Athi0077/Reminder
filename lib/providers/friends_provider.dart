import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/friend.dart';
import '../core/api/api_client.dart';
import '../services/socket_service.dart';

class FriendsNotifier extends StateNotifier<List<Friend>> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  StreamSubscription? _acceptedSub;

  FriendsNotifier(this._apiClient, this._socketService) : super([]) {
    fetchFriends();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _acceptedSub = _socketService.friendRequestAcceptedStream.listen((data) {
      final newFriend = Friend(
        id: data['receiverId'],
        name: data['receiverName'],
        email: data['receiverEmail'],
        avatar: data['receiverAvatar'],
        isOnline: false,
      );
      addFriend(newFriend);
    });
  }

  @override
  void dispose() {
    _acceptedSub?.cancel();
    super.dispose();
  }

  Future<void> fetchFriends() async {
    try {
      final response = await _apiClient.dio.get('/friends');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        state = data.map((json) => Friend(
          id: json['id'],
          name: json['name'],
          email: json['email'],
          avatar: json['avatar'],
          isOnline: false, // Since backend doesn't track this yet
        )).toList();
      }
    } catch (e) {
      print('Failed to fetch friends: $e');
    }
  }

  void addFriend(Friend friend) {
    if (!state.any((f) => f.id == friend.id)) {
      state = [...state, friend];
    }
  }

  Future<void> removeFriend(String id) async {
    try {
      final response = await _apiClient.dio.delete('/friends/$id');
      if (response.data['success']) {
        state = state.where((f) => f.id != id).toList();
      }
    } catch (e) {
      print('Failed to remove friend: $e');
    }
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, List<Friend>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return FriendsNotifier(apiClient, socketService);
});

class FriendRequestsNotifier extends StateNotifier<List<FriendRequest>> {
  final ApiClient _apiClient;
  final Ref _ref;
  final SocketService _socketService;
  StreamSubscription? _receivedSub;

  FriendRequestsNotifier(this._apiClient, this._ref, this._socketService) : super([]) {
    fetchRequests();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _receivedSub = _socketService.friendRequestReceivedStream.listen((data) {
      final newRequest = FriendRequest(
        id: data['_id'],
        senderId: data['sender']['_id'] ?? data['sender']['id'],
        receiverId: 'me',
        status: _parseStatus(data['status']),
        createdAt: DateTime.parse(data['createdAt']),
      );
      if (!state.any((r) => r.id == newRequest.id)) {
        state = [newRequest, ...state];
      }
    });
  }

  @override
  void dispose() {
    _receivedSub?.cancel();
    super.dispose();
  }

  Future<void> fetchRequests() async {
    try {
      final response = await _apiClient.dio.get('/friends/requests');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        state = data.map((json) => FriendRequest(
          id: json['id'],
          senderId: json['sender']['_id'] ?? json['sender']['id'],
          receiverId: 'me', // Since we fetched it, we are the receiver
          status: _parseStatus(json['status']),
          createdAt: DateTime.parse(json['createdAt']),
        )).toList();
      }
    } catch (e) {
      print('Failed to fetch friend requests: $e');
    }
  }

  FriendRequestStatus _parseStatus(String status) {
    switch (status) {
      case 'accepted': return FriendRequestStatus.accepted;
      case 'rejected': return FriendRequestStatus.rejected;
      default: return FriendRequestStatus.pending;
    }
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      await _apiClient.dio.post('/friends/request', data: {
        'receiverId': targetUserId,
      });
      // Optionally fetch requests again or just show success
    } catch (e) {
      print('Failed to send request: $e');
      throw Exception('Failed to send request');
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      final response = await _apiClient.dio.patch('/friends/requests/$requestId/accept');
      if (response.data['success']) {
        state = state.where((r) => r.id != requestId).toList();
        // Fetch friends list to update it
        _ref.read(friendsProvider.notifier).fetchFriends();
      }
    } catch (e) {
      print('Failed to accept request: $e');
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      final response = await _apiClient.dio.patch('/friends/requests/$requestId/reject');
      if (response.data['success']) {
        state = state.where((r) => r.id != requestId).toList();
      }
    } catch (e) {
      print('Failed to reject request: $e');
    }
  }
}

final friendRequestsProvider = StateNotifierProvider<FriendRequestsNotifier, List<FriendRequest>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return FriendRequestsNotifier(apiClient, ref, socketService);
});

// For real API search
final friendSearchProvider = FutureProvider.family<List<Friend>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.dio.get('/friends/search', queryParameters: {'query': query});
    if (response.data['success']) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Friend(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        avatar: json['avatar'],
      )).toList();
    }
    return [];
  } catch (e) {
    print('Failed to search friends: $e');
    return [];
  }
});
