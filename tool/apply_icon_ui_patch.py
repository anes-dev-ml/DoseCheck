from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "lib" / "features" / "today" / "presentation" / "today_page.dart"
source = path.read_text(encoding="utf-8")

if "app_assets.dart" not in source:
    source = source.replace(
        "import 'package:dosecheck/core/design/app_theme.dart';\n",
        "import 'package:dosecheck/core/design/app_assets.dart';\n"
        "import 'package:dosecheck/core/design/app_theme.dart';\n",
        1,
    )

replacements = {
    "            _DoseTimelineEntry(\n              state: state.morning,":
        "            _DoseTimelineEntry(\n              state: state.morning,\n              artworkAsset: AppAssets.dosePills,",
    "            _DoseTimelineEntry(\n              state: state.second,":
        "            _DoseTimelineEntry(\n              state: state.second,\n              artworkAsset: AppAssets.dosePills,",
    "            _DoseTimelineEntry(\n              state: state.night,":
        "            _DoseTimelineEntry(\n              state: state.night,\n              artworkAsset: AppAssets.doseInsulinNight,",
    "    required this.state,\n    required this.title,":
        "    required this.state,\n    required this.artworkAsset,\n    required this.title,",
    "  final DoseSlotState state;\n  final String title;":
        "  final DoseSlotState state;\n  final String artworkAsset;\n  final String title;",
}
for before, after in replacements.items():
    if before in source:
        source = source.replace(before, after, 1)

old_block = """                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 3),
                  Text(amount, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 3),
                  Text(detail, style: theme.textTheme.bodyMedium),
"""
new_block = """                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 3),
                            Text(amount, style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ExcludeSemantics(
                        child: Image.asset(
                          artworkAsset,
                          width: 52,
                          height: 52,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(detail, style: theme.textTheme.bodyMedium),
"""
if old_block in source:
    source = source.replace(old_block, new_block, 1)

required_markers = [
    "AppAssets.dosePills",
    "AppAssets.doseInsulinNight",
    "final String artworkAsset;",
    "Image.asset(\n                          artworkAsset,",
]
missing = [marker for marker in required_markers if marker not in source]
if missing:
    raise SystemExit(f"Today icon patch incomplete: {missing}")

path.write_text(source, encoding="utf-8")
print("Today timeline artwork integrated.")
