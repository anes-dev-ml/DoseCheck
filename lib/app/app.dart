import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/app/app_shell.dart';
import 'package:dosecheck/core/design/app_theme.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DoseCheckApp extends StatelessWidget {
  const DoseCheckApp({
    super.key,
    required this.controller,
  });

  final DoseCheckController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final languageCode = controller.preferences.languageCode;

        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          locale: languageCode == null ? null : Locale(languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppShell(controller: controller),
        );
      },
    );
  }
}
