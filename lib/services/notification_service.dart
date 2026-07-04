import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _plugin.initialize(settings);
  }

  Future<void> showTimerNotification(String recipeName, int minutes) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        'Cooking Timer',
        channelDescription: 'Cooking timer notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true),
    );
    await _plugin.show(
      0,
      '⏰ Timer Complete!',
      '$recipeName is ready! ($minutes min)',
      details,
    );
  }

  Future<void> showMealReminderNotification(String mealType, String recipeName) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'meal_channel',
        'Meal Reminders',
        channelDescription: 'Meal planning reminders',
        importance: Importance.defaultImportance,
      ),
      iOS: DarwinNotificationDetails(presentAlert: true),
    );
    await _plugin.show(
      1,
      '🍽️ Meal Reminder',
      'Time for $mealType: $recipeName',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
