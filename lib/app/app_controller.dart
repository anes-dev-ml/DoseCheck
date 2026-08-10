import 'package:dosecheck/features/doses/data/dose_repository.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/settings/data/settings_repository.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';
import 'package:flutter/foundation.dart';

enum DoseMutationResult { saved, alreadyResolved, unavailable, busy }

class DoseCheckController extends ChangeNotifier {
  DoseCheckController._({
    required DoseRepository doseRepository,
    required SettingsRepository settingsRepository,
    required List<DoseEvent> events,
    required RegimenPlan regimen,
    required AppPreferences preferences,
  }) : _doseRepository = doseRepository,
       _settingsRepository = settingsRepository,
       _events = events,
       _regimen = regimen,
       _preferences = preferences;

  final DoseRepository _doseRepository;
  final SettingsRepository _settingsRepository;

  List<DoseEvent> _events;
  RegimenPlan _regimen;
  AppPreferences _preferences;
  bool _isMutating = false;

  static Future<DoseCheckController> load({
    required DoseRepository doseRepository,
    required SettingsRepository settingsRepository,
  }) async {
    final events = await doseRepository.readAll();
    final regimen = await settingsRepository.readRegimen();
    final preferences = await settingsRepository.readPreferences();

    return DoseCheckController._(
      doseRepository: doseRepository,
      settingsRepository: settingsRepository,
      events: List.of(events),
      regimen: regimen,
      preferences: preferences,
    );
  }

  List<DoseEvent> get events => List.unmodifiable(_events);
  RegimenPlan get regimen => _regimen;
  AppPreferences get preferences => _preferences;
  bool get isMutating => _isMutating;

  DoseDayState stateForDay(DateTime day, {DateTime? now}) {
    return DoseDayState.derive(
      plan: _regimen,
      day: day,
      now: now ?? DateTime.now(),
      events: _events,
    );
  }

  Future<DoseMutationResult> record({
    required DoseSlot slot,
    required DoseEventType type,
    double? amount,
    DateTime? occurredAt,
  }) async {
    if (type == DoseEventType.cleared) {
      throw ArgumentError.value(
        type,
        'type',
        'Use correctEntry for corrections.',
      );
    }
    if (_isMutating) {
      return DoseMutationResult.busy;
    }

    final timestamp = occurredAt ?? DateTime.now();
    final current = stateForDay(timestamp, now: timestamp).stateFor(slot);
    if (current.isResolved) {
      return DoseMutationResult.alreadyResolved;
    }
    if (current.isActionLocked) {
      return DoseMutationResult.unavailable;
    }

    final recordedAmount = _recordedAmountFor(
      slot: slot,
      type: type,
      suppliedAmount: amount,
    );
    final event = DoseEvent.create(
      slot: slot,
      type: type,
      occurredAt: timestamp,
      amount: recordedAmount,
    );

    _setMutating(true);
    try {
      await _doseRepository.append(event);
      _events = [..._events, event];
      return DoseMutationResult.saved;
    } finally {
      _setMutating(false);
    }
  }

  Future<DoseMutationResult> correctEntry({
    required DateTime day,
    required DoseSlot slot,
    DateTime? correctedAt,
  }) async {
    if (_isMutating) {
      return DoseMutationResult.busy;
    }

    final timestamp = correctedAt ?? DateTime.now();
    final current = stateForDay(day, now: timestamp).stateFor(slot);
    if (!current.isResolved) {
      return DoseMutationResult.alreadyResolved;
    }

    final event = DoseEvent.create(
      slot: slot,
      type: DoseEventType.cleared,
      occurredAt: timestamp,
      forDay: day,
    );

    _setMutating(true);
    try {
      await _doseRepository.append(event);
      _events = [..._events, event];
      return DoseMutationResult.saved;
    } finally {
      _setMutating(false);
    }
  }

  Future<void> updateRegimen(RegimenPlan plan) async {
    if (_isMutating || plan == _regimen) {
      return;
    }

    _setMutating(true);
    try {
      await _settingsRepository.writeRegimen(plan);
      _regimen = plan;
    } finally {
      _setMutating(false);
    }
  }

  Future<void> updateLanguage(String? languageCode) async {
    if (_isMutating || languageCode == _preferences.languageCode) {
      return;
    }

    final next = languageCode == null
        ? _preferences.copyWith(clearLanguageCode: true)
        : _preferences.copyWith(languageCode: languageCode);

    _setMutating(true);
    try {
      await _settingsRepository.writePreferences(next);
      _preferences = next;
    } finally {
      _setMutating(false);
    }
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    if (_isMutating || enabled == _preferences.remindersEnabled) {
      return;
    }

    final next = _preferences.copyWith(remindersEnabled: enabled);
    _setMutating(true);
    try {
      await _settingsRepository.writePreferences(next);
      _preferences = next;
    } finally {
      _setMutating(false);
    }
  }

  Future<void> resetLocalData() async {
    if (_isMutating) {
      return;
    }

    _setMutating(true);
    try {
      await _doseRepository.clearAll();
      await _settingsRepository.clearAll();
      _events = [];
      _regimen = const RegimenPlan.initial();
      _preferences = const AppPreferences.initial();
    } catch (_) {
      await _bestEffortReload();
      rethrow;
    } finally {
      _setMutating(false);
    }
  }

  double? _recordedAmountFor({
    required DoseSlot slot,
    required DoseEventType type,
    required double? suppliedAmount,
  }) {
    if (type != DoseEventType.taken) {
      if (suppliedAmount != null) {
        throw ArgumentError.value(
          suppliedAmount,
          'amount',
          'Only taken entries may include an amount.',
        );
      }
      return null;
    }

    return switch (slot) {
      DoseSlot.morningPills => _regimen.morningTabletCount.toDouble(),
      DoseSlot.secondPills => _regimen.secondTabletCount.toDouble(),
      DoseSlot.nightInsulin =>
        suppliedAmount ?? (throw ArgumentError.notNull('amount')),
    };
  }

  Future<void> _bestEffortReload() async {
    try {
      final events = await _doseRepository.readAll();
      final regimen = await _settingsRepository.readRegimen();
      final preferences = await _settingsRepository.readPreferences();
      _events = List.of(events);
      _regimen = regimen;
      _preferences = preferences;
    } catch (_) {
      // The original storage error remains the useful failure for the caller.
    }
  }

  void _setMutating(bool value) {
    if (_isMutating == value) {
      return;
    }
    _isMutating = value;
    notifyListeners();
  }
}
