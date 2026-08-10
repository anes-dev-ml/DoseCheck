import 'package:dosecheck/core/design/app_assets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all runtime icon assets are packaged and non-empty', () async {
    const assets = <String>[
      AppAssets.brandMark,
      AppAssets.navToday,
      AppAssets.navHistory,
      AppAssets.navSettings,
      AppAssets.dosePills,
      AppAssets.doseInsulinNight,
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
