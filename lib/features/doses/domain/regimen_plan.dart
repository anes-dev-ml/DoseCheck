class RegimenPlan {
  const RegimenPlan._({
    required this.morningTabletCount,
    required this.morningTimeMinutes,
    required this.secondTabletCount,
    required this.secondMinimumIntervalMinutes,
    required this.nightInsulinUnits,
    required this.nightTimeMinutes,
  });

  factory RegimenPlan({
    required int morningTabletCount,
    required int morningTimeMinutes,
    required int secondTabletCount,
    required int secondMinimumIntervalMinutes,
    required double nightInsulinUnits,
    required int nightTimeMinutes,
  }) {
    _validatePositive(morningTabletCount, 'morningTabletCount');
    _validateMinutesOfDay(morningTimeMinutes, 'morningTimeMinutes');
    _validatePositive(secondTabletCount, 'secondTabletCount');
    _validateWholeHourInterval(secondMinimumIntervalMinutes);
    if (!nightInsulinUnits.isFinite || nightInsulinUnits <= 0) {
      throw ArgumentError.value(
        nightInsulinUnits,
        'nightInsulinUnits',
        'Must be a positive finite number.',
      );
    }
    _validateMinutesOfDay(nightTimeMinutes, 'nightTimeMinutes');

    return RegimenPlan._(
      morningTabletCount: morningTabletCount,
      morningTimeMinutes: morningTimeMinutes,
      secondTabletCount: secondTabletCount,
      secondMinimumIntervalMinutes: secondMinimumIntervalMinutes,
      nightInsulinUnits: nightInsulinUnits,
      nightTimeMinutes: nightTimeMinutes,
    );
  }

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
    final rawVersion = map['schema_version'] ?? 1;
    if (rawVersion is! int || rawVersion != schemaVersion) {
      throw FormatException('Unsupported regimen schema version: $rawVersion');
    }

    try {
      return RegimenPlan(
        morningTabletCount: _readInt(map, 'morning_tablet_count'),
        morningTimeMinutes: _readInt(map, 'morning_time_minutes'),
        secondTabletCount: _readInt(map, 'second_tablet_count'),
        secondMinimumIntervalMinutes: _readInt(
          map,
          'second_minimum_interval_minutes',
        ),
        nightInsulinUnits: _readNumber(map, 'night_insulin_units').toDouble(),
        nightTimeMinutes: _readInt(map, 'night_time_minutes'),
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid regimen value: ${error.message}');
    }
  }

  static void _validatePositive(int value, String name) {
    if (value <= 0) {
      throw ArgumentError.value(value, name, 'Must be greater than zero.');
    }
  }

  static void _validateWholeHourInterval(int value) {
    _validatePositive(value, 'secondMinimumIntervalMinutes');
    if (value % 60 != 0) {
      throw ArgumentError.value(
        value,
        'secondMinimumIntervalMinutes',
        'Must be a whole number of hours.',
      );
    }
  }

  static void _validateMinutesOfDay(int value, String name) {
    if (value < 0 || value >= 24 * 60) {
      throw ArgumentError.value(value, name, 'Must be between 0 and 1439.');
    }
  }

  static int _readInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('Missing or invalid regimen field: $key');
  }

  static num _readNumber(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is num && value.isFinite) {
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
