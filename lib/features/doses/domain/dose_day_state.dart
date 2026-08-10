import 'package:dosecheck/core/time/local_day.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';

enum DoseResolution { pending, taken, missed, uncertain }

class DoseSlotState {
  const DoseSlotState({
    required this.slot,
    required this.resolution,
    required this.isActionLocked,
    this.event,
    this.availableAt,
  });

  final DoseSlot slot;
  final DoseResolution resolution;
  final bool isActionLocked;
  final DoseEvent? event;
  final DateTime? availableAt;

  bool get isResolved => resolution != DoseResolution.pending;
}

class DoseDayState {
  const DoseDayState._({
    required this.localDayKey,
    required this.morning,
    required this.second,
    required this.night,
  });

  final String localDayKey;
  final DoseSlotState morning;
  final DoseSlotState second;
  final DoseSlotState night;

  Iterable<DoseSlotState> get slots => [morning, second, night];

  int get loggedCount => slots.where((state) => state.isResolved).length;
  int get takenCount =>
      slots.where((state) => state.resolution == DoseResolution.taken).length;
  bool get hasUncertainty =>
      slots.any((state) => state.resolution == DoseResolution.uncertain);
  bool get hasMissed =>
      slots.any((state) => state.resolution == DoseResolution.missed);
  bool get hasPending =>
      slots.any((state) => state.resolution == DoseResolution.pending);
  bool get allResolved => !hasPending;
  bool get allTaken => takenCount == slots.length;

  DoseSlotState stateFor(DoseSlot slot) {
    return switch (slot) {
      DoseSlot.morningPills => morning,
      DoseSlot.secondPills => second,
      DoseSlot.nightInsulin => night,
    };
  }

  factory DoseDayState.derive({
    required RegimenPlan plan,
    required DateTime day,
    required DateTime now,
    required Iterable<DoseEvent> events,
  }) {
    final key = localDayKeyFor(day);
    final relevantEvents =
        events.where((event) => event.localDayKey == key).toList()
          ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));

    final morningEvent = _latestEffectiveEvent(
      relevantEvents,
      DoseSlot.morningPills,
    );
    final secondEvent = _latestEffectiveEvent(
      relevantEvents,
      DoseSlot.secondPills,
    );
    final nightEvent = _latestEffectiveEvent(
      relevantEvents,
      DoseSlot.nightInsulin,
    );

    final morning = DoseSlotState(
      slot: DoseSlot.morningPills,
      resolution: _resolutionFor(morningEvent),
      event: morningEvent,
      isActionLocked: false,
    );

    DateTime? secondAvailableAt;
    var isSecondLocked = false;

    if (secondEvent == null) {
      if (morningEvent?.type == DoseEventType.taken) {
        secondAvailableAt = morningEvent!.occurredAtUtc.toLocal().add(
          plan.secondMinimumInterval,
        );
        isSecondLocked = now.toLocal().isBefore(secondAvailableAt);
      } else {
        isSecondLocked = true;
      }
    }

    final second = DoseSlotState(
      slot: DoseSlot.secondPills,
      resolution: _resolutionFor(secondEvent),
      event: secondEvent,
      isActionLocked: isSecondLocked,
      availableAt: secondAvailableAt,
    );

    final night = DoseSlotState(
      slot: DoseSlot.nightInsulin,
      resolution: _resolutionFor(nightEvent),
      event: nightEvent,
      isActionLocked: false,
    );

    return DoseDayState._(
      localDayKey: key,
      morning: morning,
      second: second,
      night: night,
    );
  }
}

DoseEvent? _latestEffectiveEvent(Iterable<DoseEvent> events, DoseSlot slot) {
  DoseEvent? effective;

  for (final event in events) {
    if (event.slot != slot) {
      continue;
    }

    if (event.type == DoseEventType.cleared) {
      effective = null;
    } else {
      effective = event;
    }
  }

  return effective;
}

DoseResolution _resolutionFor(DoseEvent? event) {
  if (event == null) {
    return DoseResolution.pending;
  }

  return switch (event.type) {
    DoseEventType.taken => DoseResolution.taken,
    DoseEventType.missed => DoseResolution.missed,
    DoseEventType.uncertain => DoseResolution.uncertain,
    DoseEventType.cleared => DoseResolution.pending,
  };
}
