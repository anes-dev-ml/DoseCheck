import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/core/design/app_assets.dart';
import 'package:dosecheck/features/history/presentation/history_page.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:dosecheck/features/settings/presentation/settings_page.dart';
import 'package:dosecheck/features/today/presentation/today_page.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.controller,
    required this.reminders,
  });

  final DoseCheckController controller;
  final ReminderService reminders;

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
          SettingsPage(
            controller: widget.controller,
            reminders: widget.reminders,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: [
          NavigationDestination(
            icon: const _NavigationAssetIcon(asset: AppAssets.navToday),
            selectedIcon: const _NavigationAssetIcon(
              asset: AppAssets.navToday,
              selected: true,
            ),
            label: l10n.navToday,
          ),
          NavigationDestination(
            icon: const _NavigationAssetIcon(asset: AppAssets.navHistory),
            selectedIcon: const _NavigationAssetIcon(
              asset: AppAssets.navHistory,
              selected: true,
            ),
            label: l10n.navHistory,
          ),
          NavigationDestination(
            icon: const _NavigationAssetIcon(asset: AppAssets.navSettings),
            selectedIcon: const _NavigationAssetIcon(
              asset: AppAssets.navSettings,
              selected: true,
            ),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}

class _NavigationAssetIcon extends StatelessWidget {
  const _NavigationAssetIcon({required this.asset, this.selected = false});

  final String asset;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: selected ? 1 : 0.62,
      duration: const Duration(milliseconds: 160),
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Image.asset(
          asset,
          width: 25,
          height: 25,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
