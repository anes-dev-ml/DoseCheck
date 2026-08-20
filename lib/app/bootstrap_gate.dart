import 'package:dosecheck/app/app.dart';
import 'package:dosecheck/app/app_runtime.dart';
import 'package:dosecheck/app/bootstrap.dart';
import 'package:dosecheck/core/design/app_theme.dart';
import 'package:dosecheck/core/design/dosecheck_mark.dart';
import 'package:dosecheck/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class DoseCheckBootstrapGate extends StatefulWidget {
  const DoseCheckBootstrapGate({super.key});

  @override
  State<DoseCheckBootstrapGate> createState() => _DoseCheckBootstrapGateState();
}

class _DoseCheckBootstrapGateState extends State<DoseCheckBootstrapGate> {
  late Future<DoseCheckRuntime> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = bootstrapDoseCheck();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = bootstrapDoseCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DoseCheckRuntime>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return DoseCheckApp(runtime: snapshot.requireData);
        }

        return _BootstrapMaterialApp(
          hasError: snapshot.hasError,
          onRetry: _retry,
        );
      },
    );
  }
}

class _BootstrapMaterialApp extends StatelessWidget {
  const _BootstrapMaterialApp({required this.hasError, required this.onRetry});

  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: hasError
                        ? _BootstrapError(l10n: l10n, onRetry: onRetry)
                        : _BootstrapLoading(l10n: l10n),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const DoseCheckMark(size: 42),
        const SizedBox(height: 22),
        Text(l10n.loading, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

class _BootstrapError extends StatelessWidget {
  const _BootstrapError({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DoseCheckMark(size: 42),
        const SizedBox(height: 28),
        Text(
          l10n.localDataErrorTitle,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 10),
        Text(
          l10n.localDataErrorBody,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
      ],
    );
  }
}
