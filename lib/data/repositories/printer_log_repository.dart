import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/repositories/printer_log_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/printer_log_dao.dart';

class PrinterLogRepository implements PrinterLogRepositoryContract {
  PrinterLogRepository(this._dao);

  final PrinterLogDao _dao;

  @override
  Future<void> record({
    required String eventType,
    String? printerName,
    String? printerAddress,
    required String status,
    required String message,
  }) {
    return _dao.insert(
      PrinterLogsCompanion.insert(
        id: IdGenerator.create(),
        eventType: eventType,
        printerName: Value(printerName),
        printerAddress: Value(printerAddress),
        status: status,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<List<PrinterLogRecord>> recent({int limit = 30}) {
    return _dao.recent(limit: limit);
  }
}
