import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';

class DoseCheckRuntime {
  const DoseCheckRuntime({
    required this.controller,
    required this.reminders,
  });

  final DoseCheckController controller;
  final ReminderService reminders;
}
