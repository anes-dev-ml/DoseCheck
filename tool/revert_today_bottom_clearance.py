from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'lib' / 'features' / 'today' / 'presentation' / 'today_page.dart'
source = path.read_text(encoding='utf-8')
before = "    return ContentFrame(\n      padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),\n      child: SingleChildScrollView(\n"
after = "    return ContentFrame(\n      child: SingleChildScrollView(\n"
if before not in source:
    raise SystemExit('Today bottom-clearance override not found')
path.write_text(source.replace(before, after, 1), encoding='utf-8')
print('Restored natural Today layout.')
