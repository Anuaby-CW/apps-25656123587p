import 'package:drift/drift.dart';

import '../app_database.dart';

class AuditDao {
  AuditDao(this._db);

  final AppDatabase _db;

  Future<void> insert(AuditLogsCompanion companion) async {
    await _db.transaction(() async {
      // 1. Hapus log dari hari-hari sebelumnya (berganti hari hapus otomatis)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      await (_db.delete(_db.auditLogs)
            ..where((tbl) => tbl.createdAt.isSmallerThanValue(todayStart)))
          .go();

      // 2. Masukkan log aktivitas baru
      await _db.into(_db.auditLogs).insert(companion);

      // 3. Batasi maksimal hanya menyimpan 9 log terbaru (setiap 10 log hapus permanen otomatis)
      final logs = await (_db.select(_db.auditLogs)
            ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
          .get();
      if (logs.length >= 10) {
        final cutoffTime = logs[9].createdAt; // Indeks 9 adalah log ke-10
        await (_db.delete(_db.auditLogs)
              ..where((tbl) => tbl.createdAt.isSmallerOrEqualValue(cutoffTime)))
            .go();
      }
    });
  }

  Future<List<AuditLogRecord>> recent({int limit = 100}) {
    return (_db.select(_db.auditLogs)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
          ..limit(limit))
        .get();
  }
}
