import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder.dart';
import '../core/api/api_client.dart';
import '../services/notification_service.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  final ApiClient _apiClient;

  ReminderNotifier(this._apiClient) : super([]) {
    fetchReminders();
  }

  Future<void> fetchReminders() async {
    try {
      final response = await _apiClient.dio.get('/reminders');
      if (response.data['success']) {
        final List<dynamic> data = response.data['data'];
        state = data.map((json) => _parseReminder(json)).toList();
      }
    } catch (e) {
      print('Failed to fetch reminders: $e');
    }
  }

  Reminder _parseReminder(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dateTime: DateTime.parse(json['dateTime']),
      alertBefore: _parseAlert(json['alertBefore']),
      repeat: _parseRepeat(json['repeat']),
      category: _parseCategory(json['category']),
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
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

  Future<void> addReminder(Reminder reminder) async {
    try {
      final response = await _apiClient.dio.post('/reminders', data: {
        'title': reminder.title,
        'description': reminder.description,
        'dateTime': reminder.dateTime.toIso8601String(),
        'alertBefore': reminder.alertBefore.name,
        'repeat': reminder.repeat.name,
        'category': reminder.category.name,
      });

      if (response.data['success']) {
        final newReminder = _parseReminder(response.data['data']);
        state = [...state, newReminder];
        
        NotificationService().scheduleReminder(
          id: newReminder.id.hashCode,
          title: newReminder.title,
          body: newReminder.description ?? 'You have a reminder',
          scheduledDate: newReminder.dateTime.subtract(_getDurationFromAlert(newReminder.alertBefore)),
        );
      }
    } catch (e) {
      print('Failed to add reminder: $e');
      throw Exception('Failed to save reminder. Please try again.');
    }
  }

  Future<void> updateReminder(Reminder updatedReminder) async {
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
        final parsed = _parseReminder(response.data['data']);
        state = [
          for (final reminder in state)
            if (reminder.id == parsed.id) parsed else reminder,
        ];
      }
    } catch (e) {
      print('Failed to update reminder: $e');
      throw Exception('Failed to update reminder. Please try again.');
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      final response = await _apiClient.dio.delete('/reminders/$id');
      if (response.data['success']) {
        state = state.where((reminder) => reminder.id != id).toList();
      }
    } catch (e) {
      print('Failed to delete reminder: $e');
      throw Exception('Failed to delete reminder. Please try again.');
    }
  }

  Future<void> markAsCompleted(String id) async {
    try {
      final response = await _apiClient.dio.patch('/reminders/$id/complete');
      if (response.data['success']) {
        final parsed = _parseReminder(response.data['data']);
        state = [
          for (final reminder in state)
            if (reminder.id == parsed.id) parsed else reminder,
        ];
      }
    } catch (e) {
      print('Failed to complete reminder: $e');
      throw Exception('Failed to complete reminder. Please try again.');
    }
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReminderNotifier(apiClient);
});

final upcomingRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(reminderProvider);
  final now = DateTime.now();
  
  return reminders.where((r) {
    if (r.status == ReminderStatus.completed) return false;
    if (r.dateTime.isBefore(now) && r.status != ReminderStatus.overdue) {
      return true; 
    }
    return r.status == ReminderStatus.upcoming;
  }).toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
});

final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  final reminders = ref.watch(reminderProvider);
  return reminders.where((r) => r.status == ReminderStatus.completed).toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
});
