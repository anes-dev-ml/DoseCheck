import 'dart:async';

import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';
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
      expect(controller.isMutating, isFalse);
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

    test('failed regimen persistence leaves the active regimen unchanged', () async {
      final settings = InMemorySettingsRepository();
      final controller = await createController(settingsRepository: settings);
      final original = controller.regimen;
      final updated = original.copyWith(morningTabletCount: 3);
      settings.writeError = StateError('settings unavailable');

      await expectLater(controller.updateRegimen(updated), throwsStateError);

      expect(controller.regimen, original);
      expect(settings.regimen, original);
      expect(controller.isMutating, isFalse);
    });

    test(
      'failed preference persistence leaves the active preferences unchanged',
      () async {
        final settings = InMemorySettingsRepository();
        final controller = await createController(settingsRepository: settings);
        const original = AppPreferences.initial();
        settings.writeError = StateError('settings unavailable');

        await expectLater(controller.updateLanguage('fr'), throwsStateError);

        expect(controller.preferences, original);
        expect(settings.preferences, original);
        expect(controller.isMutating, isFalse);
      },
    );

    test('reset never clears dose history when settings reset fails', () async {
      final original = DoseEvent.create(
        slot: DoseSlot.morningPills,
        type: DoseEventType.taken,
        occurredAt: DateTime(2026, 8, 10, 8),
        amount: 2,
      );
      final doseRepository = InMemoryDoseRepository(initialEvents: [original]);
      final regimen = const RegimenPlan.initial().copyWith(
        morningTabletCount: 3,
      );
      final preferences = AppPreferences(
        languageCode: 'fr',
        remindersEnabled: true,
      );
      final settingsRepository = InMemorySettingsRepository(
        regimen: regimen,
        preferences: preferences,
      )..clearError = StateError('settings reset failed');
      final controller = await createController(
        doseRepository: doseRepository,
        settingsRepository: settingsRepository,
      );

      await expectLater(controller.resetLocalData(), throwsStateError);

      expect(doseRepository.events, [original]);
      expect(controller.events, [original]);
      expect(controller.regimen, regimen);
      expect(controller.preferences, preferences);
      expect(controller.isMutating, isFalse);
    });

    test(
      'failed history clear reloads the partial persisted reset safely',
      () async {
        final original = DoseEvent.create(
          slot: DoseSlot.morningPills,
          type: DoseEventType.taken,
          occurredAt: DateTime(2026, 8, 10, 8),
          amount: 2,
        );
        final doseRepository = InMemoryDoseRepository(initialEvents: [original])
          ..clearError = StateError('history reset failed');
        final settingsRepository = InMemorySettingsRepository(
          regimen: const RegimenPlan.initial().copyWith(
            morningTabletCount: 3,
          ),
          preferences: AppPreferences(
            languageCode: 'fr',
            remindersEnabled: true,
          ),
        );
        final controller = await createController(
          doseRepository: doseRepository,
          settingsRepository: settingsRepository,
        );

        await expectLater(controller.resetLocalData(), throwsStateError);

        expect(doseRepository.events, [original]);
        expect(controller.events, [original]);
        expect(controller.regimen, const RegimenPlan.initial());
        expect(controller.preferences, const AppPreferences.initial());
        expect(controller.isMutating, isFalse);
      },
    );
  });
}
