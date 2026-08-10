import 'dart:async';

import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_repositories.dart';

void main() {
  Future<DoseCheckController> createController({
    InMemoryDoseRepository? doseRepository,
    InMemorySettingsRepository? settingsRepository,
  }) {
    return DoseCheckController.load(
      doseRepository: doseRepository ?? InMemoryDoseRepository(),
      settingsRepository: settingsRepository ?? InMemorySettingsRepository(),
    );
  }

  group('DoseCheckController', () {
    test(
      'does not expose a taken state before persistence completes',
      () async {
        final repository = InMemoryDoseRepository();
        final barrier = Completer<void>();
        repository.appendBarrier = barrier;
        final controller = await createController(doseRepository: repository);
        final now = DateTime(2026, 8, 10, 8, 12);

        final write = controller.record(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: now,
        );

        expect(controller.isMutating, isTrue);
        expect(
          controller.stateForDay(now, now: now).morning.resolution,
          DoseResolution.pending,
        );

        barrier.complete();
        expect(await write, DoseMutationResult.saved);
        expect(
          controller.stateForDay(now, now: now).morning.resolution,
          DoseResolution.taken,
        );
        expect(repository.events.single.amount, 2);
      },
    );

    test('rapid duplicate logging cannot create a second event', () async {
      final repository = InMemoryDoseRepository();
      final controller = await createController(doseRepository: repository);
      final now = DateTime(2026, 8, 10, 8);

      expect(
        await controller.record(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: now,
        ),
        DoseMutationResult.saved,
      );
      expect(
        await controller.record(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: now.add(const Duration(minutes: 1)),
        ),
        DoseMutationResult.alreadyResolved,
      );
      expect(repository.events, hasLength(1));
    });

    test('does not expose a failed write as a successful check-in', () async {
      final repository = InMemoryDoseRepository()
        ..appendError = StateError('disk unavailable');
      final controller = await createController(doseRepository: repository);
      final now = DateTime(2026, 8, 10, 8);

      await expectLater(
        controller.record(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: now,
        ),
        throwsStateError,
      );

      expect(repository.events, isEmpty);
      expect(
        controller.stateForDay(now, now: now).morning.resolution,
        DoseResolution.pending,
      );
    });

    test(
      'keeps the second entry unavailable before the configured interval',
      () async {
        final controller = await createController();
        final morning = DateTime(2026, 8, 10, 9);

        await controller.record(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: morning,
        );

        expect(
          await controller.record(
            slot: DoseSlot.secondPills,
            type: DoseEventType.taken,
            occurredAt: morning.add(const Duration(hours: 5, minutes: 59)),
          ),
          DoseMutationResult.unavailable,
        );
        expect(
          await controller.record(
            slot: DoseSlot.secondPills,
            type: DoseEventType.taken,
            occurredAt: morning.add(const Duration(hours: 6)),
          ),
          DoseMutationResult.saved,
        );
      },
    );

    test('historical correction keeps its real correction timestamp', () async {
      final yesterday = DateTime(2026, 8, 9);
      final today = DateTime(2026, 8, 10, 10);
      final original = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 9, 8),
        amount: 2,
      );
      final repository = InMemoryDoseRepository(initialEvents: [original]);
      final controller = await createController(doseRepository: repository);

      expect(
        await controller.correctEntry(
          day: yesterday,
          slot: DoseSlot.morningPills,
          correctedAt: today,
        ),
        DoseMutationResult.saved,
      );

      expect(repository.events, hasLength(2));
      final correction = repository.events.last;
      expect(correction.localDayKey, original.localDayKey);
      expect(correction.occurredAtUtc, today.toUtc());
      expect(correction.type, DoseEventType.cleared);
      expect(
        controller.stateForDay(yesterday, now: today).morning.resolution,
        DoseResolution.pending,
      );
    });
  });
}
