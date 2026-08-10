import 'package:dosecheck/app/app.dart';
import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/app/app_runtime.dart';
import 'package:dosecheck/features/reminders/application/local_reminder_service.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:dosecheck/features/settings/domain/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/in_memory_repositories.dart';

void main() {
  Future<DoseCheckRuntime> runtimeFor(String languageCode) async {
    final controller = await DoseCheckController.load(
      doseRepository: InMemoryDoseRepository(),
      settingsRepository: InMemorySettingsRepository(
        preferences: AppPreferences(
          languageCode: languageCode,
          remindersEnabled: false,
        ),
      ),
    );

    return DoseCheckRuntime(
      controller: controller,
      reminders: const UnavailableReminderService(
        ReminderAvailability.unsupported,
      ),
    );
  }

  Future<TextDirection> directionFor(
    WidgetTester tester,
    String languageCode,
    String todayLabel,
  ) async {
    await tester.pumpWidget(
      DoseCheckApp(runtime: await runtimeFor(languageCode)),
    );
    await tester.pump();

    expect(find.text(todayLabel), findsWidgets);
    final context = tester.element(find.text(todayLabel).first);
    return Directionality.of(context);
  }

  testWidgets('English uses left-to-right layout', (tester) async {
    expect(await directionFor(tester, 'en', 'Today'), TextDirection.ltr);
  });

  testWidgets('French uses left-to-right layout', (tester) async {
    expect(await directionFor(tester, 'fr', 'Aujourd’hui'), TextDirection.ltr);
  });

  testWidgets('Arabic uses right-to-left layout', (tester) async {
    expect(await directionFor(tester, 'ar', 'اليوم'), TextDirection.rtl);
  });
}
