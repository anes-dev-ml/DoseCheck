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
  const DoseEvent({
    required this.id,
    required this.localDayKey,
    required this.slot,
    required this.type,
    required this.occurredAtUtc,
    this.amount,
  }) : assert(occurredAtUtc.isUtc);

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
    double? amount,
  }) {
    final utc = occurredAt.toUtc();
    return DoseEvent(
      id: '${slot.storageKey}-${utc.microsecondsSinceEpoch}-${type.storageKey}',
      localDayKey: localDayKeyFor(occurredAt),
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
    final version = map['schema_version'] as int? ?? 1;
    if (version != schemaVersion) {
      throw FormatException('Unsupported dose event schema version: $version');
    }

    final id = map['id'];
    final day = map['local_day_key'];
    final slot = map['slot'];
    final type = map['type'];
    final occurredAt = map['occurred_at_utc'];
    final amount = map['amount'];

    if (id is! String ||
        day is! String ||
        slot is! String ||
        type is! String ||
        occurredAt is! String) {
      throw const FormatException('Invalid dose event payload');
    }

    final parsedTime = DateTime.tryParse(occurredAt);
    if (parsedTime == null) {
      throw const FormatException('Invalid dose event timestamp');
    }

    if (amount != null && amount is! num) {
      throw const FormatException('Invalid dose event amount');
    }

    return DoseEvent(
      id: id,
      localDayKey: day,
      slot: DoseSlot.fromStorage(slot),
      type: DoseEventType.fromStorage(type),
      occurredAtUtc: parsedTime.toUtc(),
      amount: (amount as num?)?.toDouble(),
    );
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
