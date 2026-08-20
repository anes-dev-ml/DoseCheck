import 'package:dosecheck/features/doses/data/dose_repository.dart';
import 'package:dosecheck/features/doses/domain/dose_event.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

class HiveDoseRepository implements DoseRepository {
  const HiveDoseRepository(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<DoseEvent>> readAll() async {
    final events = <DoseEvent>[];

    for (final value in _box.values) {
      if (value is! Map) {
        throw const FormatException('Invalid value in the dose event store');
      }

      events.add(DoseEvent.fromMap(Map<String, dynamic>.from(value)));
    }

    events.sort((a, b) => a.occurredAtUtc.compareTo(b.occurredAtUtc));
    return List.unmodifiable(events);
  }

  @override
  Future<void> append(DoseEvent event) async {
    await _box.add(event.toMap());
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
