import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const regimen = RegimenPlan.initial();
  final day = DateTime(2026, 8, 10);

  DoseEvent event(
    DoseSlot slot,
    DoseEventType type,
    DateTime occurredAt, {
    double? amount,
  }) {
    return DoseEvent.create(
      slot: slot,
      type: type,
      occurredAt: occurredAt,
      amount: type == DoseEventType.taken
          ? amount ?? (slot == DoseSlot.nightInsulin ? 8 : 2)
          : null,
    );
  }

  DoseDayState stateAt(DateTime now, [List<DoseEvent> events = const []]) {
    return DoseDayState.derive(
      plan: regimen,
      day: day,
      now: now,
      events: events,
    );
  }

  group('ReminderSchedulePlan', () {
    test('disabled reminders produce no actionable schedule', () {
      final now = DateTime(2026, 8, 10, 7);
      final plan = ReminderSchedulePlan.build(
        enabled: false,
        regimen: regimen,
        today: stateAt(now),
        now: now,
      );

      expect(plan.enabled, isFalse);
      expect(plan.secondAt, isNull);
    });

    test('daily reminders start today only when their time is still ahead', () {
      final morning = DateTime(2026, 8, 10, 7, 59);
      final beforeMorning = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(morning),
        now: morning,
      );
      expect(beforeMorning.morningDayOffset, 0);
      expect(beforeMorning.nightDayOffset, 0);

      final afterMorning = DateTime(2026, 8, 10, 8, 1);
      final afterMorningPlan = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(afterMorning),
        now: afterMorning,
      );
      expect(afterMorningPlan.morningDayOffset, 1);
      expect(afterMorningPlan.nightDayOffset, 0);
    });

    test('an already resolved daily slot starts again tomorrow', () {
      final now = DateTime(2026, 8, 10, 7);
      final events = [
        event(
          DoseSlot.morningPills,
          DoseEventType.taken,
          DateTime(2026, 8, 10, 6, 45),
        ),
        event(
          DoseSlot.nightInsulin,
          DoseEventType.missed,
          DateTime(2026, 8, 10, 6, 50),
        ),
      ];
      final plan = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(now, events),
        now: now,
      );

      expect(plan.morningDayOffset, 1);
      expect(plan.nightDayOffset, 1);
    });

    test('second reminder follows a confirmed morning taken event', () {
      final morning = event(
        DoseSlot.morningPills,
        DoseEventType.taken,
        DateTime(2026, 8, 10, 9, 17),
      );
      final now = DateTime(2026, 8, 10, 12);
      final plan = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(now, [morning]),
        now: now,
      );

      expect(plan.secondAt, DateTime(2026, 8, 10, 15, 17));
    });

    test('uncertain or missed morning never creates a second reminder', () {
      for (final type in [DoseEventType.uncertain, DoseEventType.missed]) {
        final morning = event(
          DoseSlot.morningPills,
          type,
          DateTime(2026, 8, 10, 9),
        );
        final now = DateTime(2026, 8, 10, 12);
        final plan = ReminderSchedulePlan.build(
          enabled: true,
          regimen: regimen,
          today: stateAt(now, [morning]),
          now: now,
        );

        expect(plan.secondAt, isNull, reason: 'morning type: $type');
      }
    });

    test('resolved second entry never keeps a second reminder', () {
      final events = [
        event(
          DoseSlot.morningPills,
          DoseEventType.taken,
          DateTime(2026, 8, 10, 8),
        ),
        event(
          DoseSlot.secondPills,
          DoseEventType.taken,
          DateTime(2026, 8, 10, 14),
        ),
      ];
      final now = DateTime(2026, 8, 10, 14, 1);
      final plan = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(now, events),
        now: now,
      );

      expect(plan.secondAt, isNull);
    });

    test('a second reminder is not scheduled once its time is due or past', () {
      final morning = event(
        DoseSlot.morningPills,
        DoseEventType.taken,
        DateTime(2026, 8, 10, 9, 17),
      );
      final atBoundary = DateTime(2026, 8, 10, 15, 17);
      final plan = ReminderSchedulePlan.build(
        enabled: true,
        regimen: regimen,
        today: stateAt(atBoundary, [morning]),
        now: atBoundary,
      );

      expect(plan.secondAt, isNull);
    });
  });
}
