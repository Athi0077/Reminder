import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermission() async {
    if (kIsWeb) return;
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
 
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    if (scheduledDate.isBefore(DateTime.now())) return;
    
    // Check settings
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
    
    if (!notificationsEnabled) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'remindly_channel_id',
          'Remindly Alerts',
          channelDescription: 'Channel for reminder alerts',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          enableVibration: vibrationEnabled,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int id) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> showImmediateNotification(String title, String body) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS)) return;
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'remindly_channel_id',
      'Remindly Alerts',
      channelDescription: 'Channel for reminder alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
