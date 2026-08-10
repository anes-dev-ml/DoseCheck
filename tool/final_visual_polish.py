from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "lib" / "features" / "today" / "presentation" / "today_page.dart"
source = path.read_text(encoding="utf-8")

replacements = {
    "const DoseCheckMark(size: 28)": "const DoseCheckMark(size: 31)",
    "const SizedBox(height: 38),\n            Text(\n              l10n.todayGreeting": "const SizedBox(height: 32),\n            Text(\n              l10n.todayGreeting",
    "const SizedBox(height: 36),\n            _DoseTimelineEntry(": "const SizedBox(height: 26),\n            _DoseTimelineEntry(",
    "const SizedBox(width: 12),\n                      ExcludeSemantics(\n                        child: Image.asset(\n                          artworkAsset,\n                          width: 52,\n                          height: 52,\n                          fit: BoxFit.contain,\n                        ),\n                      ),": "const SizedBox(width: 8),\n                      ExcludeSemantics(\n                        child: Opacity(\n                          opacity: theme.brightness == Brightness.dark ? 0.78 : 0.88,\n                          child: Image.asset(\n                            artworkAsset,\n                            width: 64,\n                            height: 64,\n                            fit: BoxFit.contain,\n                          ),\n                        ),\n                      ),",
    "padding: EdgeInsets.only(bottom: isLast ? 8 : 31),": "padding: EdgeInsets.only(bottom: isLast ? 8 : 24),",
}

for before, after in replacements.items():
    if before not in source:
        raise SystemExit(f"Could not find expected visual polish target:\n{before}")
    source = source.replace(before, after, 1)

path.write_text(source, encoding="utf-8")
print("Final Today visual polish applied.")
