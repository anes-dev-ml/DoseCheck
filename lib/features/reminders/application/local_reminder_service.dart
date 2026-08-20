import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
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
  Future<void> _operationTail = Future<void>.value();
  int? _lastSuccessfulFingerprint;

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
  }) {
    return _enqueue(
      () => _syncNow(
        enabled: enabled,
        regimen: regimen,
        today: today,
        messages: messages,
        now: now,
      ),
    );
  }

  Future<void> _syncNow({
    required bool enabled,
    required RegimenPlan regimen,
    required DoseDayState today,
    required ReminderMessages messages,
    DateTime? now,
  }) async {
    final reference = now == null
        ? tz.TZDateTime.now(tz.local)
        : tz.TZDateTime.from(now, tz.local);
    final plan = ReminderSchedulePlan.build(
      enabled: enabled,
      regimen: regimen,
      today: today,
      now: reference,
    );
    final fingerprint = Object.hashAll([
      plan.enabled,
      plan.morningDayOffset,
      plan.nightDayOffset,
      plan.secondAt?.microsecondsSinceEpoch,
      regimen.morningTimeMinutes,
      regimen.nightTimeMinutes,
      messages.channelName,
      messages.channelDescription,
      messages.morningTitle,
      messages.morningBody,
      messages.secondTitle,
      messages.secondBody,
      messages.nightTitle,
      messages.nightBody,
    ]);

    if (_lastSuccessfulFingerprint == fingerprint) {
      return;
    }

    _lastSuccessfulFingerprint = null;
    await _cancelOwned();
    if (!plan.enabled) {
      _lastSuccessfulFingerprint = fingerprint;
      return;
    }

    final details = _details(messages);

    await _scheduleDaily(
      id: _morningId,
      title: messages.morningTitle,
      body: messages.morningBody,
      minutesOfDay: regimen.morningTimeMinutes,
      reference: reference,
      details: details,
      dayOffset: plan.morningDayOffset,
    );
    await _scheduleDaily(
      id: _nightId,
      title: messages.nightTitle,
      body: messages.nightBody,
      minutesOfDay: regimen.nightTimeMinutes,
      reference: reference,
      details: details,
      dayOffset: plan.nightDayOffset,
    );

    final secondAt = plan.secondAt;
    if (secondAt != null) {
      await _plugin.zonedSchedule(
        id: _secondId,
        title: messages.secondTitle,
        body: messages.secondBody,
        scheduledDate: tz.TZDateTime.from(secondAt, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    _lastSuccessfulFingerprint = fingerprint;
  }

  @override
  Future<void> cancelAll() {
    return _enqueue(() async {
      _lastSuccessfulFingerprint = null;
      await _cancelOwned();
    });
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _operationTail.then((_) => operation());
    _operationTail = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return next;
  }

  Future<void> _cancelOwned() async {
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
    required int dayOffset,
  }) async {
    final scheduled = tz.TZDateTime(
      tz.local,
      reference.year,
      reference.month,
      reference.day + dayOffset,
      minutesOfDay ~/ 60,
      minutesOfDay % 60,
    );

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
