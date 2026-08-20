enum DoseSlot {
  morningPills('morning_pills'),
  secondPills('second_pills'),
  nightInsulin('night_insulin');

  const DoseSlot(this.storageKey);

  final String storageKey;

  static DoseSlot fromStorage(String value) {
    return DoseSlot.values.firstWhere(
      (slot) => slot.storageKey == value,
      orElse: () => throw FormatException('Unknown dose slot: $value'),
    );
  }
}
