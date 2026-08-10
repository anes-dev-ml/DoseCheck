String localDayKey(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime localDayFromKey(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw FormatException('Invalid local day key: $value');
  }

  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw FormatException('Invalid local day key: $value');
  }

  final parsed = DateTime(year, month, day);
  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    throw FormatException('Invalid local day key: $value');
  }

  return parsed;
}

DateTime startOfLocalDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

DateTime atMinutesOfDay(DateTime day, int minutes) {
  if (minutes < 0 || minutes >= 24 * 60) {
    throw RangeError.range(minutes, 0, (24 * 60) - 1, 'minutes');
  }

  final local = day.toLocal();
  return DateTime(
    local.year,
    local.month,
    local.day,
    minutes ~/ 60,
    minutes % 60,
  );
}
