import 'package:dosecheck/core/time/local_day.dart';
import 'package:dosecheck/features/doses/domain/dose_slot.dart';

enum DoseEventType {
  taken('taken'),
  uncertain('uncertain'),
  missed('missed'),
  cleared('cleared');

  const DoseEventType(this.storageKey);

  final String storageKey;

  static DoseEventType fromStorage(String value) {
    return DoseEventType.values.firstWhere(
      (type) => type.storageKey == value,
      orElse: () => throw FormatException('Unknown dose event type: $value'),
    );
  }
}

class DoseEvent {
  const DoseEvent._({
    required this.id,
    required this.localDayKey,
    required this.slot,
    required this.type,
    required this.occurredAtUtc,
    this.amount,
  });

  static const int schemaVersion = 1;

  final String id;
  final String localDayKey;
  final DoseSlot slot;
  final DoseEventType type;
  final DateTime occurredAtUtc;
  final double? amount;

  factory DoseEvent.create({
    required DoseSlot slot,
    required DoseEventType type,
    required DateTime occurredAt,
    DateTime? forDay,
    double? amount,
  }) {
    _validateAmount(slot: slot, type: type, amount: amount);

    final utc = occurredAt.toUtc();
    return DoseEvent._(
      id: '${slot.storageKey}-${utc.microsecondsSinceEpoch}-${type.storageKey}',
      localDayKey: localDayKeyFor(forDay ?? occurredAt),
      slot: slot,
      type: type,
      occurredAtUtc: utc,
      amount: amount,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'schema_version': schemaVersion,
      'id': id,
      'local_day_key': localDayKey,
      'slot': slot.storageKey,
      'type': type.storageKey,
      'occurred_at_utc': occurredAtUtc.toIso8601String(),
      'amount': amount,
    };
  }

  factory DoseEvent.fromMap(Map<String, dynamic> map) {
    final rawVersion = map['schema_version'] ?? 1;
    if (rawVersion is! int || rawVersion != schemaVersion) {
      throw FormatException('Unsupported dose event schema version: $rawVersion');
    }

    final id = map['id'];
    final day = map['local_day_key'];
    final slotValue = map['slot'];
    final typeValue = map['type'];
    final occurredAt = map['occurred_at_utc'];
    final rawAmount = map['amount'];

    if (id is! String ||
        day is! String ||
        slotValue is! String ||
        typeValue is! String ||
        occurredAt is! String) {
      throw const FormatException('Invalid dose event payload');
    }

    localDayFromKey(day);

    final parsedTime = DateTime.tryParse(occurredAt);
    if (parsedTime == null) {
      throw const FormatException('Invalid dose event timestamp');
    }

    if (rawAmount != null && rawAmount is! num) {
      throw const FormatException('Invalid dose event amount');
    }

    final slot = DoseSlot.fromStorage(slotValue);
    final type = DoseEventType.fromStorage(typeValue);
    final amount = (rawAmount as num?)?.toDouble();

    try {
      _validateAmount(slot: slot, type: type, amount: amount);
    } on ArgumentError catch (error) {
      throw FormatException('Invalid dose event amount: ${error.message}');
    }

    return DoseEvent._(
      id: id,
      localDayKey: day,
      slot: slot,
      type: type,
      occurredAtUtc: parsedTime.toUtc(),
      amount: amount,
    );
  }

  static void _validateAmount({
    required DoseSlot slot,
    required DoseEventType type,
    required double? amount,
  }) {
    if (type == DoseEventType.taken && amount == null) {
      throw ArgumentError.notNull('amount');
    }

    if (type != DoseEventType.taken && amount != null) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Only a taken event may store an amount.',
      );
    }

    if (amount == null) {
      return;
    }

    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Must be a positive finite number.',
      );
    }

    if (slot != DoseSlot.nightInsulin && amount != amount.roundToDouble()) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Tablet amounts must be whole numbers.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return other is DoseEvent &&
        other.id == id &&
        other.localDayKey == localDayKey &&
        other.slot == slot &&
        other.type == type &&
        other.occurredAtUtc == occurredAtUtc &&
        other.amount == amount;
  }

  @override
  int get hashCode => Object.hash(
        id,
        localDayKey,
        slot,
        type,
        occurredAtUtc,
        amount,
      );
}
