import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../core/api/api_client.dart';
import '../services/socket_service.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationState({
    required this.notifications,
    required this.unreadCount,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  StreamSubscription? _notificationSub;

  NotificationNotifier(this._apiClient, this._socketService)
      : super(NotificationState(notifications: [], unreadCount: 0)) {
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _notificationSub = _socketService.notificationReceivedStream.listen((data) {
      final newNotification = AppNotification.fromJson(data);
      if (!state.notifications.any((n) => n.id == newNotification.id)) {
        state = state.copyWith(
          notifications: [newNotification, ...state.notifications],
          unreadCount: state.unreadCount + 1,
        );
      }
    });
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        final notifications = data.map((json) => AppNotification.fromJson(json)).toList();
        
        final unreadCountResponse = await _apiClient.dio.get('/notifications/unread-count');
        int unreadCount = 0;
        if (unreadCountResponse.data['success']) {
          unreadCount = unreadCountResponse.data['data']['count'];
        }

        state = state.copyWith(notifications: notifications, unreadCount: unreadCount);
      }
    } catch (e) {
      print('Failed to fetch notifications: $e');
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      if (response.data['success']) {
        final count = response.data['data']['count'];
        state = state.copyWith(unreadCount: count);
      }
    } catch (e) {
      print('Failed to fetch unread count: $e');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      final response = await _apiClient.dio.patch('/notifications/$id/read');
      if (response.data['success']) {
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == id) {
            return AppNotification(
              id: n.id,
              type: n.type,
              title: n.title,
              message: n.message,
              read: true,
              createdAt: n.createdAt,
              sender: n.sender,
              relatedId: n.relatedId,
            );
          }
          return n;
        }).toList();
        
        final count = updatedNotifications.where((n) => !n.read).length;
        state = state.copyWith(notifications: updatedNotifications, unreadCount: count);
      }
    } catch (e) {
      print('Failed to mark as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await _apiClient.dio.patch('/notifications/read-all');
      if (response.data['success']) {
        final updatedNotifications = state.notifications.map((n) {
          return AppNotification(
            id: n.id,
            type: n.type,
            title: n.title,
            message: n.message,
            read: true,
            createdAt: n.createdAt,
            sender: n.sender,
            relatedId: n.relatedId,
          );
        }).toList();
        
        state = state.copyWith(notifications: updatedNotifications, unreadCount: 0);
      }
    } catch (e) {
      print('Failed to mark all as read: $e');
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return NotificationNotifier(apiClient, socketService);
});
