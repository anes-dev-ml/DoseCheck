import 'package:dosecheck/app/app.dart';
import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/app/app_runtime.dart';
import 'package:dosecheck/features/reminders/application/local_reminder_service.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_repositories.dart';

void main() {
  testWidgets('DoseCheck exposes its three primary destinations', (tester) async {
    final controller = await DoseCheckController.load(
      doseRepository: InMemoryDoseRepository(),
      settingsRepository: InMemorySettingsRepository(),
    );
    final runtime = DoseCheckRuntime(
      controller: controller,
      reminders: const UnavailableReminderService(
        ReminderAvailability.unsupported,
      ),
    );

    await tester.pumpWidget(DoseCheckApp(runtime: runtime));
    await tester.pump();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('button this many times'), findsNothing);
  });
}
