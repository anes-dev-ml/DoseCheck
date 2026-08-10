import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
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
