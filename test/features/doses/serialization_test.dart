import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegimenPlan serialization', () {
    test('round-trips the configured routine', () {
      final plan = RegimenPlan(
        morningTabletCount: 2,
        morningTimeMinutes: 7 * 60 + 45,
        secondTabletCount: 2,
        secondMinimumIntervalMinutes: 6 * 60,
        nightInsulinUnits: 7.5,
        nightTimeMinutes: 21 * 60 + 30,
      );

      final restored = RegimenPlan.fromMap(
        Map<String, dynamic>.from(plan.toMap()),
      );

      expect(restored, plan);
    });

    test('rejects an invalid schedule at runtime', () {
      expect(
        () => RegimenPlan(
          morningTabletCount: 2,
          morningTimeMinutes: -1,
          secondTabletCount: 2,
          secondMinimumIntervalMinutes: 6 * 60,
          nightInsulinUnits: 8,
          nightTimeMinutes: 22 * 60,
        ),
        throwsArgumentError,
      );
    });

    test('rejects interval precision the editor cannot represent', () {
      expect(
        () => RegimenPlan(
          morningTabletCount: 2,
          morningTimeMinutes: 8 * 60,
          secondTabletCount: 2,
          secondMinimumIntervalMinutes: 390,
          nightInsulinUnits: 8,
          nightTimeMinutes: 22 * 60,
        ),
        throwsArgumentError,
      );
    });

    test('rejects unsupported persisted interval precision', () {
      final stored = const RegimenPlan.initial().toMap();
      stored['second_minimum_interval_minutes'] = 390;

      expect(
        () => RegimenPlan.fromMap(Map<String, dynamic>.from(stored)),
        throwsFormatException,
      );
    });
  });

  group('DoseEvent serialization', () {
    test('round-trips UTC time, slot, status, and amount', () {
      final source = DoseEvent.create(
        slot: DoseSlot.nightInsulin,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 22, 14),
        amount: 8,
      );

      final restored = DoseEvent.fromMap(
        Map<String, dynamic>.from(source.toMap()),
      );

      expect(restored, source);
      expect(restored.occurredAtUtc.isUtc, isTrue);
    });

    test('rejects a persisted timestamp without timezone information', () {
      final stored = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 8),
        amount: 2,
      ).toMap();
      stored['occurred_at_utc'] = '2026-08-10T12:00:00.000';

      expect(
        () => DoseEvent.fromMap(Map<String, dynamic>.from(stored)),
        throwsFormatException,
      );
    });

    test('stores a whole-number pill amount on taken entries', () {
      final source = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 8),
        amount: 2,
      );

      expect(source.amount, 2);
      expect(
        () => DoseEvent.create(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: DateTime(2026, 8, 10, 8),
          amount: 1.5,
        ),
        throwsArgumentError,
      );
    });

    test('rejects unknown storage values instead of guessing', () {
      final source = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 8),
        amount: 2,
      ).toMap();

      expect(
        () => DoseEvent.fromMap(
          Map<String, dynamic>.from(source)..['slot'] = 'unknown_slot',
        ),
        throwsFormatException,
      );
    });
  });
}
