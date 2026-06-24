import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<void> scheduleDailyReminders({
    required int morningHour,
    required int morningMinute,
    required int eveningHour,
    required int eveningMinute,
  }) async {
    await _plugin.cancelAll();
    await _scheduleDaily(
      id: 1,
      title: 'حان وقت أذكار الصباح ☀️',
      body: 'ابدأ يومك بذكر الله',
      hour: morningHour,
      minute: morningMinute,
    );
    await _scheduleDaily(
      id: 2,
      title: 'حان وقت أذكار المساء 🌙',
      body: 'اختم يومك بذكر الله',
      hour: eveningHour,
      minute: eveningMinute,
    );
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'adhkar_daily', 'أذكاري اليومية',
          channelDescription: 'تذكير يومي بأذكار الصباح والمساء',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
