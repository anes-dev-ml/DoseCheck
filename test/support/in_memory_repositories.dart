import 'dart:async';

import 'package:dosecheck/features/doses/data/dose_repository.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/settings/data/settings_repository.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';

class InMemoryDoseRepository implements DoseRepository {
  InMemoryDoseRepository({List<DoseEvent>? initialEvents})
      : events = [...?initialEvents];

  final List<DoseEvent> events;
  Completer<void>? appendBarrier;
  Object? appendError;

  @override
  Future<List<DoseEvent>> readAll() async => List.unmodifiable(events);

  @override
  Future<void> append(DoseEvent event) async {
    final barrier = appendBarrier;
    if (barrier != null) {
      await barrier.future;
    }
    final error = appendError;
    if (error != null) {
      throw error;
    }
    events.add(event);
  }

  @override
  Future<void> clearAll() async {
    events.clear();
  }
}

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository({
    RegimenPlan? regimen,
    AppPreferences? preferences,
  })  : regimen = regimen ?? const RegimenPlan.initial(),
        preferences = preferences ?? const AppPreferences.initial();

  RegimenPlan regimen;
  AppPreferences preferences;
  Object? writeError;

  @override
  Future<RegimenPlan> readRegimen() async => regimen;

  @override
  Future<void> writeRegimen(RegimenPlan plan) async {
    final error = writeError;
    if (error != null) {
      throw error;
    }
    regimen = plan;
  }

  @override
  Future<AppPreferences> readPreferences() async => preferences;

  @override
  Future<void> writePreferences(AppPreferences value) async {
    final error = writeError;
    if (error != null) {
      throw error;
    }
    preferences = value;
  }

  @override
  Future<void> clearAll() async {
    regimen = const RegimenPlan.initial();
    preferences = const AppPreferences.initial();
  }
}
