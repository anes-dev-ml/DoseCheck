import 'package:dosecheck/core/design/dosecheck_mark.dart';
import 'package:dosecheck/core/widgets/content_frame.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final now = DateTime.now();

    return ContentFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const DoseCheckMark(size: 28),
              const SizedBox(width: 10),
              Text(l10n.appName, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 38),
          Text(l10n.todayGreeting, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            material.formatFullDate(now),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
