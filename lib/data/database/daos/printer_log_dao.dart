import 'package:drift/drift.dart';

import '../app_database.dart';

class PrinterLogDao {
  PrinterLogDao(this._db);

  final AppDatabase _db;

  Future<void> insert(PrinterLogsCompanion companion) async {
    await _db.transaction(() async {
      // 1. Hapus log dari hari-hari sebelumnya (berganti hari hapus otomatis)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      await (_db.delete(_db.printerLogs)
            ..where((tbl) => tbl.createdAt.isSmallerThanValue(todayStart)))
          .go();

      // 2. Masukkan log printer baru
      await _db.into(_db.printerLogs).insert(companion);

      // 3. Batasi maksimal hanya menyimpan 4 log terbaru (setiap 5 log hapus permanen otomatis)
      final logs = await (_db.select(_db.printerLogs)
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();
      if (logs.length >= 5) {
        final cutoffTime = logs[4].createdAt; // Indeks 4 adalah log ke-5
        await (_db.delete(_db.printerLogs)
              ..where((tbl) => tbl.createdAt.isSmallerOrEqualValue(cutoffTime)))
            .go();
      }
    });
  }

  Future<List<PrinterLogRecord>> recent({int limit = 30}) {
    return (_db.select(_db.printerLogs)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit))
        .get();
  }
}
