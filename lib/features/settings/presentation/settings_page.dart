import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/core/widgets/content_frame.dart';
import 'package:dosecheck/features/doses/domain/regimen_plan.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.controller,
  });

  final DoseCheckController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plan = controller.regimen;

    return ContentFrame(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            _SectionTitle(l10n.routineSection),
            const SizedBox(height: 8),
            _SettingsRow(
              title: l10n.morningPills,
              value: '${l10n.tabletsAmount(plan.morningTabletCount)} · '
                  '${_formatMinutes(context, plan.morningTimeMinutes)}',
            ),
            const Divider(),
            _SettingsRow(
              title: l10n.secondPills,
              value: '${l10n.tabletsAmount(plan.secondTabletCount)} · '
                  '${l10n.minimumIntervalLabel(plan.secondMinimumIntervalMinutes ~/ 60)}',
            ),
            const Divider(),
            _SettingsRow(
              title: l10n.nightInsulin,
              value: '${l10n.insulinUnits(plan.nightInsulinUnits)} · '
                  '${_formatMinutes(context, plan.nightTimeMinutes)}',
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: controller.isMutating
                  ? null
                  : () => _showRoutineEditor(context),
              child: Text(l10n.editRoutine),
            ),
            const SizedBox(height: 38),
            _SectionTitle(l10n.languageSection),
            const SizedBox(height: 8),
            _LanguageRow(
              label: l10n.languageSystem,
              selected: controller.preferences.languageCode == null,
              onTap: () => _changeLanguage(context, null),
            ),
            const Divider(),
            _LanguageRow(
              label: l10n.languageEnglish,
              selected: controller.preferences.languageCode == 'en',
              onTap: () => _changeLanguage(context, 'en'),
            ),
            const Divider(),
            _LanguageRow(
              label: l10n.languageFrench,
              selected: controller.preferences.languageCode == 'fr',
              onTap: () => _changeLanguage(context, 'fr'),
            ),
            const Divider(),
            _LanguageRow(
              label: l10n.languageArabic,
              selected: controller.preferences.languageCode == 'ar',
              onTap: () => _changeLanguage(context, 'ar'),
            ),
            const SizedBox(height: 38),
            _SectionTitle(l10n.aboutSection),
            const SizedBox(height: 14),
            _InformationBlock(
              title: l10n.safetyTitle,
              body: l10n.safetyBody,
            ),
            const SizedBox(height: 22),
            _InformationBlock(
              title: l10n.privacyTitle,
              body: l10n.privacyBody,
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: controller.isMutating
                  ? null
                  : () => _confirmReset(context),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              ),
              child: Text(l10n.resetData),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _showRoutineEditor(BuildContext context) async {
    final source = controller.regimen;
    var morningCount = source.morningTabletCount;
    var morningMinutes = source.morningTimeMinutes;
    var secondCount = source.secondTabletCount;
    var intervalHours = source.secondMinimumIntervalMinutes ~/ 60;
    var insulinUnits = source.nightInsulinUnits;
    var nightMinutes = source.nightTimeMinutes;

    final updated = await showModalBottomSheet<RegimenPlan>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final l10n = AppLocalizations.of(context);

            Future<void> chooseTime({required bool morning}) async {
              final current = morning ? morningMinutes : nightMinutes;
              final selected = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: current ~/ 60,
                  minute: current % 60,
                ),
              );
              if (selected == null || !context.mounted) {
                return;
              }
              setSheetState(() {
                final minutes = (selected.hour * 60) + selected.minute;
                if (morning) {
                  morningMinutes = minutes;
                } else {
                  nightMinutes = minutes;
                }
              });
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.routineEditorTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.routineEditorNote,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 26),
                      _EditorStepper(
                        label: l10n.morningQuantityLabel,
                        value: l10n.tabletsAmount(morningCount),
                        canDecrease: morningCount > 1,
                        onDecrease: () =>
                            setSheetState(() => morningCount -= 1),
                        onIncrease: () =>
                            setSheetState(() => morningCount += 1),
                      ),
                      const Divider(height: 26),
                      _TimeEditorRow(
                        label: l10n.morningTimeLabel,
                        value: _formatMinutes(context, morningMinutes),
                        onTap: () => chooseTime(morning: true),
                      ),
                      const Divider(height: 26),
                      _EditorStepper(
                        label: l10n.secondQuantityLabel,
                        value: l10n.tabletsAmount(secondCount),
                        canDecrease: secondCount > 1,
                        onDecrease: () =>
                            setSheetState(() => secondCount -= 1),
                        onIncrease: () =>
                            setSheetState(() => secondCount += 1),
                      ),
                      const Divider(height: 26),
                      _EditorStepper(
                        label: l10n.intervalHoursLabel,
                        value: l10n.hoursShort(intervalHours),
                        canDecrease: intervalHours > 1,
                        onDecrease: () =>
                            setSheetState(() => intervalHours -= 1),
                        onIncrease: () =>
                            setSheetState(() => intervalHours += 1),
                      ),
                      const Divider(height: 26),
                      _EditorStepper(
                        label: l10n.insulinDefaultLabel,
                        value: l10n.insulinUnits(insulinUnits),
                        canDecrease: insulinUnits > 0.5,
                        onDecrease: () =>
                            setSheetState(() => insulinUnits -= 0.5),
                        onIncrease: () =>
                            setSheetState(() => insulinUnits += 0.5),
                      ),
                      const Divider(height: 26),
                      _TimeEditorRow(
                        label: l10n.nightTimeLabel,
                        value: _formatMinutes(context, nightMinutes),
                        onTap: () => chooseTime(morning: false),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              sheetContext,
                              RegimenPlan(
                                morningTabletCount: morningCount,
                                morningTimeMinutes: morningMinutes,
                                secondTabletCount: secondCount,
                                secondMinimumIntervalMinutes:
                                    intervalHours * 60,
                                nightInsulinUnits: insulinUnits,
                                nightTimeMinutes: nightMinutes,
                              ),
                            );
                          },
                          child: Text(l10n.save),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (updated == null || !context.mounted) {
      return;
    }

    try {
      await controller.updateRegimen(updated);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).settingsSaved)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).localDataErrorTitle)),
      );
    }
  }

  Future<void> _changeLanguage(BuildContext context, String? code) async {
    if (controller.isMutating || controller.preferences.languageCode == code) {
      return;
    }

    try {
      await controller.updateLanguage(code);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).localDataErrorTitle)),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetDataTitle),
        content: Text(l10n.resetDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.resetAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await controller.resetLocalData();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).dataResetSuccess)),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).localDataErrorTitle)),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.bodyLarge),
          ),
          const SizedBox(width: 20),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.bodyLarge),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationBlock extends StatelessWidget {
  const _InformationBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 5),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _EditorStepper extends StatelessWidget {
  const _EditorStepper({
    required this.label,
    required this.value,
    required this.canDecrease,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final bool canDecrease;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton.outlined(
          onPressed: canDecrease ? onDecrease : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: onIncrease,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _TimeEditorRow extends StatelessWidget {
  const _TimeEditorRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
            Icon(
              Icons.schedule_rounded,
              size: 19,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMinutes(BuildContext context, int minutes) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
