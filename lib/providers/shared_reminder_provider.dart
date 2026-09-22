import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../models/shared_reminder.dart';
import '../core/api/api_client.dart';
import '../services/notification_service.dart';
import '../services/socket_service.dart';
import 'dart:async';
import 'auth_provider.dart';

class SharedReminderNotifier extends StateNotifier<List<SharedReminder>> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  StreamSubscription? _newSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _updateSub;

  SharedReminderNotifier(this._apiClient, this._socketService) : super([]) {
    fetchSharedWithMe();
    fetchSharedByMe();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    _newSub = _socketService.newEventCreatedStream.listen((data) {
      final newReminder = _parseSharedReminder(data);
      if (!state.any((r) => r.id == newReminder.id)) {
        state = [...state, newReminder];
      }
    });

    _statusSub = _socketService.eventStatusUpdatedStream.listen((data) {
      _updateReminderInState(data);
    });

    _updateSub = _socketService.eventUpdatedStream.listen((data) {
      _updateReminderInState(data);
    });
  }

  void _updateReminderInState(Map<String, dynamic> data) {
    final updatedReminder = _parseSharedReminder(data);
    final index = state.indexWhere((r) => r.id == updatedReminder.id);
    if (index >= 0) {
      final newState = [...state];
      newState[index] = updatedReminder;
      state = newState;
    } else {
      state = [...state, updatedReminder];
    }
  }

  @override
  void dispose() {
    _newSub?.cancel();
    _statusSub?.cancel();
    _updateSub?.cancel();
    super.dispose();
  }

  Future<void> fetchSharedWithMe() async {
    try {
      final response = await _apiClient.dio.get('/reminders/shared/with-me');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        final parsed = data.map((json) => _parseSharedReminder(json)).toList();
        
        // Merge with existing state (avoiding duplicates)
        final existingIds = parsed.map((e) => e.id).toSet();
        final currentByMe = state.where((r) => !existingIds.contains(r.id)).toList();
        state = [...currentByMe, ...parsed];
      }
    } catch (e) {
      print('Failed to fetch shared with me: $e');
    }
  }

  Future<void> fetchSharedByMe() async {
    try {
      final response = await _apiClient.dio.get('/reminders/shared/by-me');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        final parsed = data.map((json) => _parseSharedReminder(json)).toList();
        
        final existingIds = parsed.map((e) => e.id).toSet();
        final currentWithMe = state.where((r) => !existingIds.contains(r.id)).toList();
        state = [...currentWithMe, ...parsed];
      }
    } catch (e) {
      print('Failed to fetch shared by me: $e');
    }
  }

  SharedReminder _parseSharedReminder(Map<String, dynamic> json) {
    return SharedReminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      alertBefore: _parseAlert(json['alertBefore']),
      repeat: _parseRepeat(json['repeat']),
      category: _parseCategory(json['category']),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'] is Map ? json['createdBy']['_id'] ?? json['createdBy']['id'] : json['createdBy'],
      creatorName: json['creatorName'] ?? 'Unknown',
      status: _parseStatus(json['status']),
      participants: (json['participants'] as List).map((p) => Participant(
        userId: p['userId'],
        name: p['name'] ?? 'User',
        status: _parseParticipantStatus(p['status']),
      )).toList(),
    );
  }

  ReminderAlert _parseAlert(String val) {
    return ReminderAlert.values.firstWhere((e) => e.name == val, orElse: () => ReminderAlert.tenMinutesBefore);
  }

  ReminderRepeat _parseRepeat(String val) {
    return ReminderRepeat.values.firstWhere((e) => e.name == val, orElse: () => ReminderRepeat.doesNotRepeat);
  }

  ReminderCategory _parseCategory(String val) {
    return ReminderCategory.values.firstWhere((e) => e.name == val, orElse: () => ReminderCategory.personal);
  }

  ReminderStatus _parseStatus(String val) {
    return ReminderStatus.values.firstWhere((e) => e.name == val, orElse: () => ReminderStatus.upcoming);
  }

  ParticipantStatus _parseParticipantStatus(String val) {
    return ParticipantStatus.values.firstWhere((e) => e.name == val, orElse: () => ParticipantStatus.pending);
  }

  Duration _getDurationFromAlert(ReminderAlert alert) {
    switch (alert) {
      case ReminderAlert.atTimeOfEvent: return Duration.zero;
      case ReminderAlert.fiveMinutesBefore: return const Duration(minutes: 5);
      case ReminderAlert.tenMinutesBefore: return const Duration(minutes: 10);
      case ReminderAlert.fifteenMinutesBefore: return const Duration(minutes: 15);
      case ReminderAlert.thirtyMinutesBefore: return const Duration(minutes: 30);
      case ReminderAlert.oneHourBefore: return const Duration(hours: 1);
      case ReminderAlert.oneDayBefore: return const Duration(days: 1);
    }
  }

  Future<void> createSharedReminder(SharedReminder reminder, List<String> participantIds) async {
    try {
      final response = await _apiClient.dio.post('/reminders/shared', data: {
        'title': reminder.title,
        'description': reminder.description,
        'dateTime': reminder.dateTime.toIso8601String(),
        'alertBefore': reminder.alertBefore.name,
        'repeat': reminder.repeat.name,
        'category': reminder.category.name,
        'participants': participantIds.map((id) => {'userId': id}).toList(),
      });

      if (response.data['success']) {
        fetchSharedByMe();
        
        final newReminder = _parseSharedReminder(response.data['data']);
        NotificationService().scheduleReminder(
          id: newReminder.id.hashCode,
          title: 'Shared: ${newReminder.title}',
          body: newReminder.description ?? 'You have a shared reminder',
          scheduledDate: newReminder.dateTime.subtract(_getDurationFromAlert(newReminder.alertBefore)),
        );
      }
    } catch (e) {
      print('Failed to create shared reminder: $e');
      throw Exception('Failed to save shared reminder. Please try again.');
    }
  }

  Future<void> updateSharedReminder(SharedReminder updatedReminder) async {
    // Only creator can update
    try {
      final response = await _apiClient.dio.put('/reminders/${updatedReminder.id}', data: {
        'title': updatedReminder.title,
        'description': updatedReminder.description,
        'dateTime': updatedReminder.dateTime.toIso8601String(),
        'alertBefore': updatedReminder.alertBefore.name,
        'repeat': updatedReminder.repeat.name,
        'category': updatedReminder.category.name,
      });

      if (response.data['success']) {
        fetchSharedByMe();
      }
    } catch (e) {
      print('Failed to update shared reminder: $e');
      throw Exception('Failed to update shared reminder.');
    }
  }

  Future<void> deleteSharedReminder(String id) async {
    try {
      final response = await _apiClient.dio.delete('/reminders/$id');
      if (response.data['success']) {
        state = state.where((r) => r.id != id).toList();
      }
    } catch (e) {
      print('Failed to delete shared reminder: $e');
      throw Exception('Failed to delete shared reminder.');
    }
  }

  Future<void> acceptSharedReminder(String id) async {
    try {
      final response = await _apiClient.dio.patch('/reminders/shared/$id/accept');
      if (response.data['success']) {
        fetchSharedWithMe();
      }
    } catch (e) {
      print('Failed to accept shared reminder: $e');
    }
  }

  Future<void> declineSharedReminder(String id) async {
    try {
      final response = await _apiClient.dio.patch('/reminders/shared/$id/decline');
      if (response.data['success']) {
        fetchSharedWithMe();
      }
    } catch (e) {
      print('Failed to decline shared reminder: $e');
    }
  }

  Future<void> completeSharedParticipant(String id) async {
    try {
      final response = await _apiClient.dio.patch('/reminders/shared/$id/complete');
      if (response.data['success']) {
        fetchSharedWithMe();
      }
    } catch (e) {
      print('Failed to complete shared reminder: $e');
    }
  }
}

final sharedReminderProvider = StateNotifierProvider<SharedReminderNotifier, List<SharedReminder>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return SharedReminderNotifier(apiClient, socketService);
});

final sharedWithMeProvider = Provider<List<SharedReminder>>((ref) {
  final reminders = ref.watch(sharedReminderProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.userId;
  
  return reminders.where((r) => r.createdBy != userId && r.status != ReminderStatus.completed).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
});

final sharedByMeProvider = Provider<List<SharedReminder>>((ref) {
  final reminders = ref.watch(sharedReminderProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.userId;
  
  return reminders.where((r) => r.createdBy == userId && r.status != ReminderStatus.completed).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
});
