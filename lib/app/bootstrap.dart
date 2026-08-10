import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/features/doses/data/hive_dose_repository.dart';
import 'package:dosecheck/features/settings/data/hive_settings_repository.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

const _eventsBoxName = 'dosecheck_events_v1';
const _settingsBoxName = 'dosecheck_settings_v1';

Future<DoseCheckController> bootstrapDoseCheck() async {
  await Hive.initFlutter();

  final eventsBox = await Hive.openBox<dynamic>(_eventsBoxName);
  final settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);

  return DoseCheckController.load(
    doseRepository: HiveDoseRepository(eventsBox),
    settingsRepository: HiveSettingsRepository(settingsBox),
  );
}
