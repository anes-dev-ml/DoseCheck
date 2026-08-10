from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "lib" / "features" / "today" / "presentation" / "today_page.dart"
source = path.read_text(encoding="utf-8")

before = """    return ContentFrame(
      child: SingleChildScrollView(
"""
after = """    return ContentFrame(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
      child: SingleChildScrollView(
"""

if before not in source:
    raise SystemExit("Could not find Today ContentFrame target")

source = source.replace(before, after, 1)
path.write_text(source, encoding="utf-8")
print("Added Today-only bottom navigation clearance.")
