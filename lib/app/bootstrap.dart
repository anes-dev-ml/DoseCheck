import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/app/app_runtime.dart';
import 'package:dosecheck/features/doses/data/hive_dose_repository.dart';
import 'package:dosecheck/features/reminders/application/local_reminder_service.dart';
import 'package:dosecheck/features/settings/data/hive_settings_repository.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const _eventsBoxName = 'dosecheck_events_v1';
const _settingsBoxName = 'dosecheck_settings_v1';

Future<DoseCheckRuntime> bootstrapDoseCheck() async {
  await Hive.initFlutter();

  final eventsBox = await Hive.openBox<dynamic>(_eventsBoxName);
  final settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

  final controller = await DoseCheckController.load(
    doseRepository: HiveDoseRepository(eventsBox),
    settingsRepository: HiveSettingsRepository(settingsBox),
  );

  final reminders = await LocalReminderService.create();

  return DoseCheckRuntime(
    controller: controller,
    reminders: reminders,
  );
}
