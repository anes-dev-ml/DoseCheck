import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const plan = RegimenPlan.initial();
  final day = DateTime(2026, 8, 10);

  DoseEvent event(
    DoseSlot slot,
    DoseEventType type,
    int hour, {
    int minute = 0,
    double? amount,
  }) {
    final recordedAmount = type == DoseEventType.taken
        ? amount ?? (slot == DoseSlot.nightInsulin ? 8 : 2)
        : null;

    return DoseEvent.create(
      slot: slot,
      type: type,
      occurredAt: DateTime(2026, 8, 10, hour, minute),
      amount: recordedAmount,
    );
  }

  group('DoseDayState', () {
    test('starts with three pending entries', () {
      final state = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 8),
        events: const [],
      );

      expect(state.loggedCount, 0);
      expect(state.morning.resolution, DoseResolution.pending);
      expect(state.second.resolution, DoseResolution.pending);
      expect(state.second.isActionLocked, isTrue);
      expect(state.night.resolution, DoseResolution.pending);
    });

    test('unlocks the second entry only after the configured interval', () {
      final morning = event(
        DoseSlot.morningPills,
        DoseEventType.taken,
        9,
        minute: 17,
      );

      final before = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 15, 16),
        events: [morning],
      );
      final atBoundary = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 15, 17),
        events: [morning],
      );

      expect(before.second.isActionLocked, isTrue);
      expect(before.second.availableAt, DateTime(2026, 8, 10, 15, 17));
      expect(atBoundary.second.isActionLocked, isFalse);
    });

    test('does not derive a second-dose time from an uncertain morning', () {
      final state = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 16),
        events: [event(DoseSlot.morningPills, DoseEventType.uncertain, 9)],
      );

      expect(state.morning.resolution, DoseResolution.uncertain);
      expect(state.second.isActionLocked, isTrue);
      expect(state.second.availableAt, isNull);
      expect(state.hasUncertainty, isTrue);
    });

    test('a clear event resets only its slot to pending', () {
      final events = [
        event(DoseSlot.morningPills, DoseEventType.taken, 8),
        event(DoseSlot.nightInsulin, DoseEventType.taken, 21, amount: 8),
        event(DoseSlot.morningPills, DoseEventType.cleared, 9),
      ];

      final state = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 22),
        events: events.reversed,
      );

      expect(state.morning.resolution, DoseResolution.pending);
      expect(state.night.resolution, DoseResolution.taken);
      expect(state.loggedCount, 1);
    });

    test('a later event after a correction becomes the current state', () {
      final state = DoseDayState.derive(
        plan: plan,
        day: day,
        now: DateTime(2026, 8, 10, 10),
        events: [
          event(DoseSlot.morningPills, DoseEventType.taken, 8),
          event(DoseSlot.morningPills, DoseEventType.cleared, 8, minute: 30),
          event(DoseSlot.morningPills, DoseEventType.uncertain, 9),
        ],
      );

      expect(state.morning.resolution, DoseResolution.uncertain);
      expect(state.morning.event?.type, DoseEventType.uncertain);
    });

    test(
      'an existing second entry is displayed even without a morning event',
      () {
        final state = DoseDayState.derive(
          plan: plan,
          day: day,
          now: DateTime(2026, 8, 10, 18),
          events: [event(DoseSlot.secondPills, DoseEventType.taken, 16)],
        );

        expect(state.second.resolution, DoseResolution.taken);
        expect(state.second.isActionLocked, isFalse);
        expect(state.loggedCount, 1);
      },
    );
  });
}
