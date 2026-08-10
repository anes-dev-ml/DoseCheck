class RegimenPlan {
  const RegimenPlan({
    required this.morningTabletCount,
    required this.morningTimeMinutes,
    required this.secondTabletCount,
    required this.secondMinimumIntervalMinutes,
    required this.nightInsulinUnits,
    required this.nightTimeMinutes,
  })  : assert(morningTabletCount > 0),
        assert(secondTabletCount > 0),
        assert(morningTimeMinutes >= 0 && morningTimeMinutes < 24 * 60),
        assert(nightTimeMinutes >= 0 && nightTimeMinutes < 24 * 60),
        assert(secondMinimumIntervalMinutes > 0),
        assert(nightInsulinUnits > 0);

  const RegimenPlan.initial()
      : morningTabletCount = 2,
        morningTimeMinutes = 8 * 60,
        secondTabletCount = 2,
        secondMinimumIntervalMinutes = 6 * 60,
        nightInsulinUnits = 8,
        nightTimeMinutes = 22 * 60;

  static const int schemaVersion = 1;

  final int morningTabletCount;
  final int morningTimeMinutes;
  final int secondTabletCount;
  final int secondMinimumIntervalMinutes;
  final double nightInsulinUnits;
  final int nightTimeMinutes;

  Duration get secondMinimumInterval =>
      Duration(minutes: secondMinimumIntervalMinutes);

  RegimenPlan copyWith({
    int? morningTabletCount,
    int? morningTimeMinutes,
    int? secondTabletCount,
    int? secondMinimumIntervalMinutes,
    double? nightInsulinUnits,
    int? nightTimeMinutes,
  }) {
    return RegimenPlan(
      morningTabletCount: morningTabletCount ?? this.morningTabletCount,
      morningTimeMinutes: morningTimeMinutes ?? this.morningTimeMinutes,
      secondTabletCount: secondTabletCount ?? this.secondTabletCount,
      secondMinimumIntervalMinutes:
          secondMinimumIntervalMinutes ?? this.secondMinimumIntervalMinutes,
      nightInsulinUnits: nightInsulinUnits ?? this.nightInsulinUnits,
      nightTimeMinutes: nightTimeMinutes ?? this.nightTimeMinutes,
    );
  }

  Map<String, Object> toMap() {
    return {
      'schema_version': schemaVersion,
      'morning_tablet_count': morningTabletCount,
      'morning_time_minutes': morningTimeMinutes,
      'second_tablet_count': secondTabletCount,
      'second_minimum_interval_minutes': secondMinimumIntervalMinutes,
      'night_insulin_units': nightInsulinUnits,
      'night_time_minutes': nightTimeMinutes,
    };
  }

  factory RegimenPlan.fromMap(Map<String, dynamic> map) {
    final version = map['schema_version'] as int? ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported regimen schema version: $version');
    }

    return RegimenPlan(
      morningTabletCount: _readInt(map, 'morning_tablet_count'),
      morningTimeMinutes: _readInt(map, 'morning_time_minutes'),
      secondTabletCount: _readInt(map, 'second_tablet_count'),
      secondMinimumIntervalMinutes:
          _readInt(map, 'second_minimum_interval_minutes'),
      nightInsulinUnits: _readNumber(map, 'night_insulin_units').toDouble(),
      nightTimeMinutes: _readInt(map, 'night_time_minutes'),
    );
  }

  static int _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw FormatException('Missing or invalid regimen field: $key');
  }

  static num _readNumber(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num) {
      return value;
    }
    throw FormatException('Missing or invalid regimen field: $key');
  }

  @override
  bool operator ==(Object other) {
    return other is RegimenPlan &&
        other.morningTabletCount == morningTabletCount &&
        other.morningTimeMinutes == morningTimeMinutes &&
        other.secondTabletCount == secondTabletCount &&
        other.secondMinimumIntervalMinutes == secondMinimumIntervalMinutes &&
        other.nightInsulinUnits == nightInsulinUnits &&
        other.nightTimeMinutes == nightTimeMinutes;
  }

  @override
  int get hashCode => Object.hash(
        morningTabletCount,
        morningTimeMinutes,
        secondTabletCount,
        secondMinimumIntervalMinutes,
        nightInsulinUnits,
        nightTimeMinutes,
      );
}
