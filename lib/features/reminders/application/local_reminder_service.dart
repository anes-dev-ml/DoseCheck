import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalReminderService implements ReminderService {
  LocalReminderService._(this._plugin);

  static const _morningId = 110;
  static const _secondId = 120;
  static const _nightId = 130;
  static const _channelId = 'dosecheck_medication_reminders';

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<ReminderService> create() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return const UnavailableReminderService(ReminderAvailability.unsupported);
    }

    try {
      tz_data.initializeTimeZones();
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));

      final plugin = FlutterLocalNotificationsPlugin();
      const android = AndroidInitializationSettings('ic_stat_dosecheck');
      final ios = IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      final settings = InitializationSettings(android: android, iOS: ios);

      await plugin.initialize(settings: settings);
      return LocalReminderService._(plugin);
    } catch (_) {
      return const UnavailableReminderService(ReminderAvailability.unavailable);
    }
  }

  @override
  ReminderAvailability get availability => ReminderAvailability.available;

  @override
  Future<bool> requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }

    return false;
  }

  @override
  Future<void> sync({
    required bool enabled,
    required RegimenPlan regimen,
    required DoseDayState today,
    required ReminderMessages messages,
    DateTime? now,
  }) async {
    await cancelAll();
    if (!enabled) {
      return;
    }

    final reference = now == null
        ? tz.TZDateTime.now(tz.local)
        : tz.TZDateTime.from(now, tz.local);
    final details = _details(messages);

    await _scheduleDaily(
      id: _morningId,
      title: messages.morningTitle,
      body: messages.morningBody,
      minutesOfDay: regimen.morningTimeMinutes,
      reference: reference,
      details: details,
    );
    await _scheduleDaily(
      id: _nightId,
      title: messages.nightTitle,
      body: messages.nightBody,
      minutesOfDay: regimen.nightTimeMinutes,
      reference: reference,
      details: details,
    );

    final availableAt = today.second.availableAt;
    final shouldScheduleSecond =
        today.morning.event?.type == DoseEventType.taken &&
        today.second.resolution == DoseResolution.pending &&
        availableAt != null &&
        availableAt.isAfter(reference.toLocal());

    if (shouldScheduleSecond) {
      await _plugin.zonedSchedule(
        id: _secondId,
        title: messages.secondTitle,
        body: messages.secondBody,
        scheduledDate: tz.TZDateTime.from(availableAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancel(id: _morningId);
    await _plugin.cancel(id: _secondId);
    await _plugin.cancel(id: _nightId);
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int minutesOfDay,
    required tz.TZDateTime reference,
    required NotificationDetails details,
  }) async {
    var scheduled = tz.TZDateTime(
      tz.local,
      reference.year,
      reference.month,
      reference.day,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );
    if (!scheduled.isAfter(reference)) {
      scheduled = tz.TZDateTime(
        tz.local,
        reference.year,
        reference.month,
        reference.day + 1,
        minutesOfDay ~/ 60,
        minutesOfDay % 60,
      );
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails _details(ReminderMessages messages) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        messages.channelName,
        channelDescription: messages.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );
  }
}

class UnavailableReminderService implements ReminderService {
  const UnavailableReminderService(this.availability);

  @override
  final ReminderAvailability availability;

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> sync({
    required bool enabled,
    required RegimenPlan regimen,
    required DoseDayState today,
    required ReminderMessages messages,
    DateTime? now,
  }) async {}

  @override
  Future<void> cancelAll() async {}
}
