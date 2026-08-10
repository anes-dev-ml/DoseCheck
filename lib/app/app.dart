import 'package:dosecheck/app/app_runtime.dart';
import 'package:dosecheck/app/app_shell.dart';
import 'package:dosecheck/core/design/app_theme.dart';
import 'package:dosecheck/features/reminders/application/reminder_coordinator.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DoseCheckApp extends StatelessWidget {
  const DoseCheckApp({super.key, required this.runtime});

  final DoseCheckRuntime runtime;

  @override
  Widget build(BuildContext context) {
    final controller = runtime.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final languageCode = controller.preferences.languageCode;

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          locale: languageCode == null ? null : Locale(languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReminderCoordinator(
            controller: controller,
            service: runtime.reminders,
            child: AppShell(
              controller: controller,
              reminders: runtime.reminders,
            ),
          ),
        );
      },
    );
  }
}
