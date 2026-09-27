import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models.dart';

abstract interface class LifeNotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<void> schedule(LifeItem item);
  Future<void> cancel(String itemId);
}

class LocalLifeNotificationService implements LifeNotificationService {
  LocalLifeNotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return android ?? ios ?? true;
  }

  @override
  Future<void> schedule(LifeItem item) async {
    final due = DateTime(
      item.dueAt.year,
      item.dueAt.month,
      item.dueAt.day,
      9,
    ).subtract(Duration(days: item.reminderDaysBefore));
    if (!due.isAfter(DateTime.now())) {
      await cancel(item.id);
      return;
    }
    await _plugin.zonedSchedule(
      id: _notificationId(item.id),
      title: '${item.title} 일정이 다가와요',
      body: item.reminderDaysBefore == 0
          ? '오늘 처리할 일정입니다.'
          : '${item.reminderDaysBefore}일 뒤 예정입니다.',
      scheduledDate: tz.TZDateTime.from(due, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'life_due_dates',
          '생활 일정',
          channelDescription: '등록한 생활 항목의 예정일을 알려줍니다.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: item.id,
    );
  }

  @override
  Future<void> cancel(String itemId) =>
      _plugin.cancel(id: _notificationId(itemId));
}

int _notificationId(String value) {
  var hash = 17;
  for (final unit in value.codeUnits) {
    hash = 0x1fffffff & (hash * 37 + unit);
  }
  return hash;
}
