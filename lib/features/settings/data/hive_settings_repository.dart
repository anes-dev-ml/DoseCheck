import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/settings/data/settings_repository.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HiveSettingsRepository implements SettingsRepository {
  const HiveSettingsRepository(this._box);

  static const _regimenKey = 'regimen';
  static const _preferencesKey = 'preferences';

  final Box<dynamic> _box;

  @override
  Future<RegimenPlan> readRegimen() async {
    final value = _box.get(_regimenKey);
    if (value == null) {
      return const RegimenPlan.initial();
    }
    if (value is! Map) {
      throw const FormatException('Invalid regimen value in settings store');
    }

    return RegimenPlan.fromMap(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> writeRegimen(RegimenPlan plan) async {
    await _box.put(_regimenKey, plan.toMap());
    await _box.flush();
  }

  @override
  Future<AppPreferences> readPreferences() async {
    final value = _box.get(_preferencesKey);
    if (value == null) {
      return const AppPreferences.initial();
    }
    if (value is! Map) {
      throw const FormatException('Invalid preferences value in settings store');
    }

    return AppPreferences.fromMap(Map<String, dynamic>.from(value));
  }

  @override
  Future<void> writePreferences(AppPreferences preferences) async {
    await _box.put(_preferencesKey, preferences.toMap());
    await _box.flush();
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
    await _box.flush();
  }
}
