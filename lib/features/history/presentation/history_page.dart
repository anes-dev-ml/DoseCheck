import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/core/design/app_theme.dart';
import 'package:dosecheck/core/time/local_day.dart';
import 'package:dosecheck/core/widgets/content_frame.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key, required this.controller});

  final DoseCheckController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final keys =
        controller.events.map((event) => event.localDayKey).toSet().toList()
          ..sort((a, b) => b.compareTo(a));

    return ContentFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.historyTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 26),
          if (keys.isEmpty)
            _EmptyHistory(l10n: l10n)
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: keys.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, index) {
                  final day = localDayFromKey(keys[index]);
                  final state = controller.stateForDay(day);
                  return _HistoryDayRow(
                    day: day,
                    state: state,
                    onTap: () => _showDayDetails(context, day),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDayDetails(BuildContext context, DateTime day) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final l10n = AppLocalizations.of(context);
            final state = controller.stateForDay(day);
            final material = MaterialLocalizations.of(context);
            final dayKey = localDayKeyFor(day);
            final dayEvents =
                controller.events
                    .where((event) => event.localDayKey == dayKey)
                    .toList()
                  ..sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
            final hasCorrections = dayEvents.any(
              (event) => event.type == DoseEventType.cleared,
            );

            return SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayLabel(context, day),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        material.formatFullDate(day),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 26),
                      _HistoryDoseDetail(
                        title: l10n.morningPills,
                        amount: _historicalAmount(
                          context,
                          state.morning,
                          DoseSlot.morningPills,
                        ),
                        state: state.morning,
                        isBusy: controller.isMutating,
                        onCorrect: state.morning.isResolved
                            ? () => _confirmCorrection(
                                sheetContext,
                                day,
                                DoseSlot.morningPills,
                              )
                            : null,
                      ),
                      const Divider(),
                      _HistoryDoseDetail(
                        title: l10n.secondPills,
                        amount: _historicalAmount(
                          context,
                          state.second,
                          DoseSlot.secondPills,
                        ),
                        state: state.second,
                        isBusy: controller.isMutating,
                        onCorrect: state.second.isResolved
                            ? () => _confirmCorrection(
                                sheetContext,
                                day,
                                DoseSlot.secondPills,
                              )
                            : null,
                      ),
                      const Divider(),
                      _HistoryDoseDetail(
                        title: l10n.nightInsulin,
                        amount: _historicalAmount(
                          context,
                          state.night,
                          DoseSlot.nightInsulin,
                        ),
                        state: state.night,
                        isBusy: controller.isMutating,
                        onCorrect: state.night.isResolved
                            ? () => _confirmCorrection(
                                sheetContext,
                                day,
                                DoseSlot.nightInsulin,
                              )
                            : null,
                      ),
                      if (hasCorrections) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: 38,
                          height: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          l10n.dayDetailsTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final event in dayEvents)
                          _AuditEventRow(event: event),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmCorrection(
    BuildContext context,
    DateTime day,
    DoseSlot slot,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearEntryTitle),
        content: Text(l10n.clearEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.clearEntryAction),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      final result = await controller.correctEntry(day: day, slot: slot);
      if (!context.mounted || result != DoseMutationResult.saved) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.statusUpdated)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.localDataErrorTitle)));
    }
  }
}

class _HistoryDayRow extends StatelessWidget {
  const _HistoryDayRow({
    required this.day,
    required this.state,
    required this.onTap,
  });

  final DateTime day;
  final DoseDayState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dayLabel(context, day),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.historyDayLogged(state.loggedCount, 3),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            _MiniStatus(resolution: state.morning.resolution),
            const SizedBox(width: 7),
            _MiniStatus(resolution: state.second.resolution),
            const SizedBox(width: 7),
            _MiniStatus(resolution: state.night.resolution),
            const SizedBox(width: 12),
            Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: theme.colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDoseDetail extends StatelessWidget {
  const _HistoryDoseDetail({
    required this.title,
    required this.amount,
    required this.state,
    required this.isBusy,
    required this.onCorrect,
  });

  final String title;
  final String? amount;
  final DoseSlotState state;
  final bool isBusy;
  final VoidCallback? onCorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _MiniStatus(resolution: state.resolution, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                if (amount != null) ...[
                  const SizedBox(height: 2),
                  Text(amount!, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 3),
                Text(
                  _stateDetail(context, state),
                  style: theme.textTheme.bodyMedium,
                ),
                if (onCorrect != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: isBusy ? null : onCorrect,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      minimumSize: const Size(48, 40),
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    child: Text(l10n.clearEntry),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditEventRow extends StatelessWidget {
  const _AuditEventRow({required this.event});

  final DoseEvent event;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(event.occurredAtUtc.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    final slotTitle = _slotTitle(l10n, event.slot);
    final status = _eventStatusLabel(l10n, event.type);
    final amount = _eventAmount(context, event);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(time, style: theme.textTheme.labelMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slotTitle, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  amount == null ? status : '$status · $amount',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          Text(
            l10n.historyEmptyTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.historyEmptyBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _MiniStatus extends StatelessWidget {
  const _MiniStatus({required this.resolution, this.size = 16});

  final DoseResolution resolution;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (resolution) {
      DoseResolution.taken => theme.colorScheme.primary,
      DoseResolution.uncertain =>
        theme.brightness == Brightness.light
            ? AppColors.amber
            : const Color(0xFFE0B56D),
      DoseResolution.missed => theme.colorScheme.error,
      DoseResolution.pending => theme.colorScheme.outline,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolution == DoseResolution.pending
            ? Colors.transparent
            : color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 1.25),
      ),
      alignment: Alignment.center,
      child: resolution == DoseResolution.taken
          ? Icon(Icons.check_rounded, size: size * 0.68, color: color)
          : resolution == DoseResolution.uncertain
          ? Icon(Icons.question_mark_rounded, size: size * 0.62, color: color)
          : resolution == DoseResolution.missed
          ? Icon(Icons.remove_rounded, size: size * 0.68, color: color)
          : null,
    );
  }
}

String _dayLabel(BuildContext context, DateTime day) {
  final l10n = AppLocalizations.of(context);
  final now = DateTime.now();
  if (localDayKeyFor(day) == localDayKeyFor(now)) {
    return l10n.todayLabel;
  }

  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (localDayKeyFor(day) == localDayKeyFor(yesterday)) {
    return l10n.yesterdayLabel;
  }

  return MaterialLocalizations.of(context).formatMediumDate(day);
}

String _stateDetail(BuildContext context, DoseSlotState state) {
  final l10n = AppLocalizations.of(context);
  final event = state.event;
  if (event == null) {
    return l10n.pending;
  }

  final time = MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(event.occurredAtUtc.toLocal()),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );

  return switch (state.resolution) {
    DoseResolution.taken => l10n.takenAt(time),
    DoseResolution.missed => l10n.missedAt(time),
    DoseResolution.uncertain => l10n.uncertainAt(time),
    DoseResolution.pending => l10n.pending,
  };
}

String? _historicalAmount(
  BuildContext context,
  DoseSlotState state,
  DoseSlot slot,
) {
  if (state.resolution != DoseResolution.taken || state.event?.amount == null) {
    return null;
  }

  final amount = state.event!.amount!;
  final l10n = AppLocalizations.of(context);
  return switch (slot) {
    DoseSlot.morningPills ||
    DoseSlot.secondPills => l10n.tabletsAmount(amount.round()),
    DoseSlot.nightInsulin => l10n.insulinUnits(amount),
  };
}

String _slotTitle(AppLocalizations l10n, DoseSlot slot) {
  return switch (slot) {
    DoseSlot.morningPills => l10n.morningPills,
    DoseSlot.secondPills => l10n.secondPills,
    DoseSlot.nightInsulin => l10n.nightInsulin,
  };
}

String _eventStatusLabel(AppLocalizations l10n, DoseEventType type) {
  return switch (type) {
    DoseEventType.taken => l10n.taken,
    DoseEventType.missed => l10n.missed,
    DoseEventType.uncertain => l10n.uncertain,
    DoseEventType.cleared => l10n.cleared,
  };
}

String? _eventAmount(BuildContext context, DoseEvent event) {
  final amount = event.amount;
  if (amount == null) {
    return null;
  }

  final l10n = AppLocalizations.of(context);
  return switch (event.slot) {
    DoseSlot.morningPills ||
    DoseSlot.secondPills => l10n.tabletsAmount(amount.round()),
    DoseSlot.nightInsulin => l10n.insulinUnits(amount),
  };
}
