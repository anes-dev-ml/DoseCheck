import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegimenPlan serialization', () {
    test('round-trips the configured routine', () {
      const plan = RegimenPlan(
        morningTabletCount: 2,
        morningTimeMinutes: 7 * 60 + 45,
        secondTabletCount: 2,
        secondMinimumIntervalMinutes: 390,
        nightInsulinUnits: 7.5,
        nightTimeMinutes: 21 * 60 + 30,
      );

      final restored = RegimenPlan.fromMap(
        Map<String, dynamic>.from(plan.toMap()),
      );

      expect(restored, plan);
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

    test('rejects unknown storage values instead of guessing', () {
      final source = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 8),
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
