import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminders and alerts'),
            value: settings.notificationsEnabled,
            onChanged: (value) {
              settingsNotifier.updateSettings(settings.copyWith(notificationsEnabled: value));
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Reminder Sound'),
            subtitle: Text(settings.reminderSound),
            enabled: settings.notificationsEnabled,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showSoundPicker(context, settings, settingsNotifier);
            },
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            value: settings.vibrationEnabled,
            onChanged: settings.notificationsEnabled 
                ? (value) {
                    settingsNotifier.updateSettings(settings.copyWith(vibrationEnabled: value));
                  }
                : null,
          ),
          const Divider(),
          ListTile(
            title: const Text('Default Alert Time'),
            subtitle: Text(settings.defaultAlertTime),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDefaultAlertPicker(context, settings, settingsNotifier);
            },
          ),
        ],
      ),
    );
  }

  void _showSoundPicker(BuildContext context, SettingsState settings, SettingsNotifier notifier) {
    final sounds = ['Default', 'Gentle', 'Classic', 'Urgent'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Reminder Sound', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...sounds.map((sound) => RadioListTile<String>(
                title: Text(sound),
                value: sound,
                groupValue: settings.reminderSound,
                onChanged: (value) {
                  notifier.updateSettings(settings.copyWith(reminderSound: value!));
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDefaultAlertPicker(BuildContext context, SettingsState settings, SettingsNotifier notifier) {
    final options = [
      'At time',
      '5 minutes before',
      '10 minutes before',
      '15 minutes before',
      '30 minutes before',
      '1 hour before',
      '1 day before'
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Default Alert Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...options.map((option) => RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: settings.defaultAlertTime,
                onChanged: (value) {
                  notifier.updateSettings(settings.copyWith(defaultAlertTime: value!));
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
