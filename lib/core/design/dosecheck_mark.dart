import 'package:dosecheck/core/design/app_assets.dart';
import 'package:flutter/material.dart';

class DoseCheckMark extends StatelessWidget {
  const DoseCheckMark({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'DoseCheck',
      image: true,
      child: Image.asset(
        AppAssets.brandMark,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
