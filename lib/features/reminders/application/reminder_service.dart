import 'package:dosecheck/core/time/local_day.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';

class ReminderMessages {
  const ReminderMessages({
    required this.channelName,
    required this.channelDescription,
    required this.morningTitle,
    required this.morningBody,
    required this.secondTitle,
    required this.secondBody,
    required this.nightTitle,
    required this.nightBody,
  });

  final String channelName;
  final String channelDescription;
  final String morningTitle;
  final String morningBody;
  final String secondTitle;
  final String secondBody;
  final String nightTitle;
  final String nightBody;
}

class ReminderSchedulePlan {
  const ReminderSchedulePlan._({
    required this.enabled,
    required this.morningDayOffset,
    required this.nightDayOffset,
    required this.secondAt,
  });

  factory ReminderSchedulePlan.build({
    required bool enabled,
    required RegimenPlan regimen,
    required DoseDayState today,
    required DateTime now,
  }) {
    if (!enabled) {
      return const ReminderSchedulePlan._(
        enabled: false,
        morningDayOffset: 0,
        nightDayOffset: 0,
        secondAt: null,
      );
    }

    final localNow = now.toLocal();
    final currentMinutes = (localNow.hour * 60) + localNow.minute;

    int dayOffset({required int minutesOfDay, required bool resolved}) {
      if (resolved || minutesOfDay <= currentMinutes) {
        return 1;
      }
      return 0;
    }

    final secondAvailableAt = today.second.availableAt;
    final staysOnTrackedDay =
        secondAvailableAt != null &&
        localDayKeyFor(secondAvailableAt) == today.localDayKey;
    final secondAt =
        today.morning.event?.type == DoseEventType.taken &&
            today.second.resolution == DoseResolution.pending &&
            staysOnTrackedDay &&
            secondAvailableAt.isAfter(localNow)
        ? secondAvailableAt
        : null;

    return ReminderSchedulePlan._(
      enabled: true,
      morningDayOffset: dayOffset(
        minutesOfDay: regimen.morningTimeMinutes,
        resolved: today.morning.isResolved,
      ),
      nightDayOffset: dayOffset(
        minutesOfDay: regimen.nightTimeMinutes,
        resolved: today.night.isResolved,
      ),
      secondAt: secondAt,
    );
  }

  final bool enabled;
  final int morningDayOffset;
  final int nightDayOffset;
  final DateTime? secondAt;
}

enum ReminderAvailability { available, unsupported, unavailable }

abstract interface class ReminderService {
  ReminderAvailability get availability;

  Future<bool> requestPermission();

  Future<void> sync({
    required bool enabled,
    required RegimenPlan regimen,
    required DoseDayState today,
    required ReminderMessages messages,
    DateTime? now,
  });

  Future<void> cancelAll();
}
