import 'dart:async';

import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/core/design/app_theme.dart';
import 'package:dosecheck/core/design/dosecheck_mark.dart';
import 'package:dosecheck/core/widgets/content_frame.dart';
import 'package:dosecheck/features/doses/domain/dose_day_state.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class TodayPage extends StatefulWidget {
  const TodayPage({
    super.key,
    required this.controller,
  });

  final DoseCheckController controller;

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  Timer? _refreshTimer;
  DateTime? _scheduledRefresh;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final now = DateTime.now();
    final state = widget.controller.stateForDay(now, now: now);

    _scheduleNextRefresh(now, state);

    return ContentFrame(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const DoseCheckMark(size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.appName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 38),
            Text(
              l10n.todayGreeting,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              material.formatFullDate(now),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            _DaySummary(state: state, l10n: l10n),
            const SizedBox(height: 36),
            _DoseTimelineEntry(
              state: state.morning,
              title: l10n.morningPills,
              amount: _amountFor(
                context,
                state.morning,
                DoseSlot.morningPills,
              ),
              detail: _detailFor(
                context,
                state.morning,
                DoseSlot.morningPills,
              ),
              isLast: false,
              isBusy: widget.controller.isMutating,
              onTaken: () => _recordTaken(DoseSlot.morningPills),
              onOtherStatus: () => _recordOtherStatus(DoseSlot.morningPills),
            ),
            _DoseTimelineEntry(
              state: state.second,
              title: l10n.secondPills,
              amount: _amountFor(
                context,
                state.second,
                DoseSlot.secondPills,
              ),
              detail: _detailFor(
                context,
                state.second,
                DoseSlot.secondPills,
              ),
              isLast: false,
              isBusy: widget.controller.isMutating,
              onTaken: () => _recordTaken(DoseSlot.secondPills),
              onOtherStatus: () => _recordOtherStatus(DoseSlot.secondPills),
            ),
            _DoseTimelineEntry(
              state: state.night,
              title: l10n.nightInsulin,
              amount: _amountFor(
                context,
                state.night,
                DoseSlot.nightInsulin,
              ),
              detail: _detailFor(
                context,
                state.night,
                DoseSlot.nightInsulin,
              ),
              isLast: true,
              isBusy: widget.controller.isMutating,
              onTaken: () => _recordTaken(DoseSlot.nightInsulin),
              onOtherStatus: () => _recordOtherStatus(DoseSlot.nightInsulin),
            ),
          ],
        ),
      ),
    );
  }

  String _amountFor(
    BuildContext context,
    DoseSlotState state,
    DoseSlot slot,
  ) {
    final l10n = AppLocalizations.of(context);
    final recorded = state.resolution == DoseResolution.taken
        ? state.event?.amount
        : null;

    return switch (slot) {
      DoseSlot.morningPills => l10n.tabletsAmount(
          recorded?.round() ?? widget.controller.regimen.morningTabletCount,
        ),
      DoseSlot.secondPills => l10n.tabletsAmount(
          recorded?.round() ?? widget.controller.regimen.secondTabletCount,
        ),
      DoseSlot.nightInsulin => l10n.insulinUnits(
          recorded ?? widget.controller.regimen.nightInsulinUnits,
        ),
    };
  }

  String _detailFor(
    BuildContext context,
    DoseSlotState state,
    DoseSlot slot,
  ) {
    final l10n = AppLocalizations.of(context);
    final event = state.event;

    if (event != null) {
      final time = _formatTime(context, event.occurredAtUtc.toLocal());
      return switch (state.resolution) {
        DoseResolution.taken => l10n.takenAt(time),
        DoseResolution.missed => l10n.missedAt(time),
        DoseResolution.uncertain => l10n.uncertainAt(time),
        DoseResolution.pending => l10n.pending,
      };
    }

    if (slot == DoseSlot.secondPills && state.isActionLocked) {
      final availableAt = state.availableAt;
      if (availableAt == null) {
        return l10n.waitingForMorning;
      }
      return l10n.availableAt(_formatTime(context, availableAt));
    }

    if (slot == DoseSlot.secondPills) {
      return l10n.minimumIntervalLabel(
        widget.controller.regimen.secondMinimumIntervalMinutes ~/ 60,
      );
    }

    return l10n.pending;
  }

  String _formatTime(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  Future<void> _recordTaken(DoseSlot slot) async {
    double? amount;
    if (slot == DoseSlot.nightInsulin) {
      amount = await _showInsulinSheet();
      if (amount == null || !mounted) {
        return;
      }
    }

    await _performRecord(
      slot: slot,
      type: DoseEventType.taken,
      amount: amount,
    );
  }

  Future<void> _recordOtherStatus(DoseSlot slot) async {
    final type = await showModalBottomSheet<DoseEventType>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.logOptions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DoseEventType.uncertain,
                  ),
                  child: Text(l10n.markUncertain),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DoseEventType.missed,
                  ),
                  child: Text(l10n.markMissed),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (type == null || !mounted) {
      return;
    }
    await _performRecord(slot: slot, type: type);
  }

  Future<double?> _showInsulinSheet() {
    var amount = widget.controller.regimen.nightInsulinUnits;

    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.insulinConfirmTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.insulinConfirmBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Semantics(
                          label: l10n.decreaseUnits,
                          button: true,
                          child: IconButton.outlined(
                            onPressed: amount > 0.5
                                ? () => setSheetState(() => amount -= 0.5)
                                : null,
                            icon: const Icon(Icons.remove_rounded),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                l10n.insulinUnits(amount),
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.unitsLabel,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: l10n.increaseUnits,
                          button: true,
                          child: IconButton.outlined(
                            onPressed: () =>
                                setSheetState(() => amount += 0.5),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, amount),
                        child: Text(l10n.confirm),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performRecord({
    required DoseSlot slot,
    required DoseEventType type,
    double? amount,
  }) async {
    try {
      final result = await widget.controller.record(
        slot: slot,
        type: type,
        amount: amount,
      );
      if (!mounted) {
        return;
      }

      if (result == DoseMutationResult.alreadyResolved) {
        await _showAlreadyLogged(slot);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).localDataErrorTitle)),
      );
    }
  }

  Future<void> _showAlreadyLogged(DoseSlot slot) async {
    final l10n = AppLocalizations.of(context);
    final current = widget.controller
        .stateForDay(DateTime.now())
        .stateFor(slot)
        .event;
    if (current == null) {
      return;
    }

    final time = _formatTime(context, current.occurredAtUtc.toLocal());
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.alreadyLoggedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.alreadyLoggedBody(time)),
            const SizedBox(height: 10),
            Text(l10n.alreadyLoggedHint),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _scheduleNextRefresh(DateTime now, DoseDayState state) {
    final local = now.toLocal();
    var target = DateTime(local.year, local.month, local.day + 1);
    final availableAt = state.second.availableAt;
    if (availableAt != null &&
        availableAt.isAfter(local) &&
        availableAt.isBefore(target)) {
      target = availableAt;
    }

    if (_scheduledRefresh == target) {
      return;
    }

    _refreshTimer?.cancel();
    _scheduledRefresh = target;
    final delay = target.difference(local) + const Duration(milliseconds: 150);
    _refreshTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _scheduledRefresh = null;
      });
    });
  }
}

class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.state,
    required this.l10n,
  });

  final DoseDayState state;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, message) = state.hasUncertainty
        ? (_warningColor(theme), l10n.uncertaintyPresent)
        : state.hasMissed
            ? (theme.colorScheme.error, l10n.missed)
            : state.hasPending
                ? (theme.colorScheme.primary, l10n.needsAttention)
                : (theme.colorScheme.primary, l10n.allResolved);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 45,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.loggedProgress(state.loggedCount, 3),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 3),
              Text(message, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoseTimelineEntry extends StatelessWidget {
  const _DoseTimelineEntry({
    required this.state,
    required this.title,
    required this.amount,
    required this.detail,
    required this.isLast,
    required this.isBusy,
    required this.onTaken,
    required this.onOtherStatus,
  });

  final DoseSlotState state;
  final String title;
  final String amount;
  final String detail;
  final bool isLast;
  final bool isBusy;
  final VoidCallback onTaken;
  final VoidCallback onOtherStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canAct = !state.isResolved && !state.isActionLocked && !isBusy;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                _StatusMark(resolution: state.resolution),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: theme.dividerColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 31),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(amount, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 3),
                  Text(detail, style: theme.textTheme.bodyMedium),
                  if (!state.isResolved && !state.isActionLocked) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: canAct ? onTaken : null,
                          child: Text(l10n.logTaken),
                        ),
                        TextButton(
                          onPressed: canAct ? onOtherStatus : null,
                          child: Text(l10n.logOptions),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMark extends StatelessWidget {
  const _StatusMark({required this.resolution});

  final DoseResolution resolution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (resolution) {
      DoseResolution.taken => theme.colorScheme.primary,
      DoseResolution.uncertain => _warningColor(theme),
      DoseResolution.missed => theme.colorScheme.error,
      DoseResolution.pending => theme.colorScheme.outline,
    };

    final icon = switch (resolution) {
      DoseResolution.taken => Icons.check_rounded,
      DoseResolution.uncertain => Icons.question_mark_rounded,
      DoseResolution.missed => Icons.remove_rounded,
      DoseResolution.pending => null,
    };

    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: resolution == DoseResolution.pending
            ? Colors.transparent
            : color.withValues(alpha: 0.14),
        border: Border.all(color: color, width: 1.4),
      ),
      alignment: Alignment.center,
      child: icon == null ? null : Icon(icon, size: 13, color: color),
    );
  }
}

Color _warningColor(ThemeData theme) {
  return theme.brightness == Brightness.light
      ? AppColors.amber
      : const Color(0xFFE0B56D);
}
