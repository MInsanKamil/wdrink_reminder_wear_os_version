import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationHelper {
  static final _notification = FlutterLocalNotificationsPlugin();

  static init() async {
    await _notification.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
    );
    tz.initializeTimeZones();
  }

  static scheduleNotification(
    String title,
    String body,
    tz.TZDateTime scheduledTime,
  ) async {
    var androidDetails = const AndroidNotificationDetails(
      "important_notification",
      "My Channel",
      sound: RawResourceAndroidNotificationSound('notification'),
      playSound: true,
      importance: Importance.max,
      priority: Priority.high,
    );
    var notificationDetails = NotificationDetails(android: androidDetails);
    await _notification.zonedSchedule(
      scheduledTime.hashCode, // Unique ID for each notification
      title,
      body,
      scheduledTime,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static cancelAllNotifications() async {
    await _notification.cancelAll();
  }
}
