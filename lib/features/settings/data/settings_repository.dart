import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';

abstract interface class SettingsRepository {
  Future<RegimenPlan> readRegimen();

  Future<void> writeRegimen(RegimenPlan plan);

  Future<AppPreferences> readPreferences();

  Future<void> writePreferences(AppPreferences preferences);

  Future<void> clearAll();
}
