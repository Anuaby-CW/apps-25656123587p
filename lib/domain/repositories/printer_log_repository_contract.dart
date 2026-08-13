/// Domain contract for PrinterLogRepository. Concrete implementation in data layer.
library;

import '../../data/database/app_database.dart';

abstract class PrinterLogRepositoryContract {
  Future<void> record({
    required String eventType,
    String? printerName,
    String? printerAddress,
    required String status,
    required String message,
  });

  Future<List<PrinterLogRecord>> recent({int limit = 30});
}
