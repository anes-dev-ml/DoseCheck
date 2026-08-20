import 'package:dosecheck/features/doses/domain/dose_event.dart';

abstract interface class DoseRepository {
  Future<List<DoseEvent>> readAll();

  Future<void> append(DoseEvent event);

  Future<void> clearAll();
}
