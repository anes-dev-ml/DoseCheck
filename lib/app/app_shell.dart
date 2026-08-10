import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/features/history/presentation/history_page.dart';
import 'package:dosecheck/features/settings/presentation/settings_page.dart';
import 'package:dosecheck/features/today/presentation/today_page.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.controller,
  });

  final DoseCheckController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TodayPage(controller: widget.controller),
          HistoryPage(controller: widget.controller),
          SettingsPage(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today_rounded),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune_rounded),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
