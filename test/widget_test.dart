import 'package:dosecheck/app/app.dart';
import 'package:dosecheck/app/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_repositories.dart';

void main() {
  testWidgets('DoseCheck exposes its three primary destinations', (tester) async {
    final controller = await DoseCheckController.load(
      doseRepository: InMemoryDoseRepository(),
      settingsRepository: InMemorySettingsRepository(),
    );

    await tester.pumpWidget(DoseCheckApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.textContaining('button this many times'), findsNothing);
  });
}
