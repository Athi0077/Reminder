import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';

class SettingsState {
  final bool notificationsEnabled;
  final String reminderSound;
  final bool vibrationEnabled;
  final String defaultAlertTime;

  SettingsState({
    required this.notificationsEnabled,
    required this.reminderSound,
    required this.vibrationEnabled,
    required this.defaultAlertTime,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    String? reminderSound,
    bool? vibrationEnabled,
    String? defaultAlertTime,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderSound: reminderSound ?? this.reminderSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultAlertTime: defaultAlertTime ?? this.defaultAlertTime,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsNotifier(apiClient);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final ApiClient _apiClient;

  SettingsNotifier(this._apiClient) : super(SettingsState(
    notificationsEnabled: true,
    reminderSound: 'Default',
    vibrationEnabled: true,
    defaultAlertTime: '10 minutes before',
  )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await _apiClient.dio.get('/users/me/notification-settings');
      if (response.data['success']) {
        final data = response.data['data'];
        state = SettingsState(
          notificationsEnabled: data['enabled'] ?? true,
          reminderSound: data['sound'] == true ? 'Default' : 'None',
          vibrationEnabled: data['vibration'] ?? true,
          defaultAlertTime: '${data['defaultAlertMinutes'] ?? 10} minutes before',
        );
      }
    } catch (e) {
      print('Failed to load settings from API, falling back to local: $e');
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
        reminderSound: prefs.getString('reminderSound') ?? 'Default',
        vibrationEnabled: prefs.getBool('vibrationEnabled') ?? true,
        defaultAlertTime: prefs.getString('defaultAlertTime') ?? '10 minutes before',
      );
    }
  }

  Future<void> updateSettings(SettingsState newState) async {
    state = newState;
    
    // Save locally as fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', newState.notificationsEnabled);
    await prefs.setString('reminderSound', newState.reminderSound);
    await prefs.setBool('vibrationEnabled', newState.vibrationEnabled);
    await prefs.setString('defaultAlertTime', newState.defaultAlertTime);

    // Save to backend
    try {
      await _apiClient.dio.patch('/users/me/notification-settings', data: {
        'enabled': newState.notificationsEnabled,
        'sound': newState.reminderSound != 'None',
        'vibration': newState.vibrationEnabled,
        'defaultAlertMinutes': int.tryParse(newState.defaultAlertTime.split(' ')[0]) ?? 10,
      });
    } catch (e) {
      print('Failed to sync settings to API: $e');
    }
  }
}
