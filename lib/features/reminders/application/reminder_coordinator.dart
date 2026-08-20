import 'package:dosecheck/app/app_controller.dart';
import 'package:dosecheck/core/time/local_day.dart';
import 'package:dosecheck/features/reminders/application/reminder_service.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ReminderCoordinator extends StatefulWidget {
  const ReminderCoordinator({
    super.key,
    required this.controller,
    required this.service,
    required this.child,
  });

  final DoseCheckController controller;
  final ReminderService service;
  final Widget child;

  @override
  State<ReminderCoordinator> createState() => _ReminderCoordinatorState();
}

class _ReminderCoordinatorState extends State<ReminderCoordinator> {
  bool _syncQueued = false;
  int? _lastFingerprint;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_queueSync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _queueSync());
  }

  @override
  void didUpdateWidget(covariant ReminderCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_queueSync);
      widget.controller.addListener(_queueSync);
      _lastFingerprint = null;
    }
    if (oldWidget.service != widget.service) {
      _lastFingerprint = null;
    }
    _queueSync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _queueSync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_queueSync);
    super.dispose();
  }

  void _queueSync() {
    if (!mounted) {
      return;
    }

    if (widget.controller.isMutating) {
      _lastFingerprint = null;
      return;
    }

    if (_syncQueued) {
      return;
    }

    _syncQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _syncQueued = false;
      if (!mounted || widget.controller.isMutating) {
        if (mounted) {
          _lastFingerprint = null;
        }
        return;
      }
      await _syncIfNeeded();
    });
  }

  Future<void> _syncIfNeeded() async {
    final now = DateTime.now();
    final today = widget.controller.stateForDay(now, now: now);
    final locale = Localizations.localeOf(context).languageCode;
    final fingerprint = Object.hash(
      widget.controller.preferences.remindersEnabled,
      widget.controller.regimen,
      locale,
      localDayKeyFor(now),
      today.morning.event?.id,
      today.second.event?.id,
      today.night.event?.id,
      today.second.availableAt?.millisecondsSinceEpoch,
      widget.service.availability,
    );

    if (_lastFingerprint == fingerprint) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final messages = ReminderMessages(
      channelName: l10n.remindersEnabled,
      channelDescription: l10n.remindersDescription,
      morningTitle: l10n.reminderMorningTitle,
      morningBody: l10n.reminderMorningBody,
      secondTitle: l10n.reminderSecondTitle,
      secondBody: l10n.reminderSecondBody,
      nightTitle: l10n.reminderNightTitle,
      nightBody: l10n.reminderNightBody,
    );

    try {
      await widget.service.sync(
        enabled: widget.controller.preferences.remindersEnabled,
        regimen: widget.controller.regimen,
        today: today,
        messages: messages,
        now: now,
      );
      if (mounted) {
        _lastFingerprint = fingerprint;
      }
    } catch (_) {
      // A failed device sync must not be cached as successful. A later state or
      // dependency change will retry the same reminder plan.
      if (mounted) {
        _lastFingerprint = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
