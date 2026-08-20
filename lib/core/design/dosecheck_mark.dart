import 'package:dosecheck/core/design/app_assets.dart';
import 'package:flutter/material.dart';

class DoseCheckMark extends StatelessWidget {
  const DoseCheckMark({super.key, this.size = 32, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      child: Image.asset(
        AppAssets.brandMark,
        width: size,
        height: size,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}
