import 'package:drift/drift.dart';

import '../app_database.dart';

class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> allSettings() async {
    final rows = await _db.select(_db.settings).get();
    return {for (final row in rows) row.key: row.value};
  }

  Future<String?> value(String key) async {
    final row = await (_db.select(
      _db.settings,
    )..where((tbl) => tbl.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> upsert(String key, String value) {
    return _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(id: 'setting_$key', key: key, value: value),
        );
  }

  Future<void> openShift({
    required String cashierId,
    required String cashierName,
    required DateTime startTime,
    required int openingCash,
  }) {
    return _db.transaction(() async {
      await upsert('shift_cashier_id', cashierId);
      await upsert('shift_cashier_name', cashierName);
      await upsert('shift_start_time', startTime.toIso8601String());
      await upsert('shift_opening_cash', openingCash.toString());
      // Ditulis terakhir agar shift tidak pernah terlihat aktif sebelum seluruh
      // metadata pemilik dan rekonsiliasi tersimpan.
      await upsert('shift_active', 'true');
    });
  }

  Future<void> closeShift() => upsert('shift_active', 'false');

  Future<PrinterSettingRecord> printerSettings() async {
    final existing = await (_db.select(
      _db.printerSettings,
    )..where((tbl) => tbl.id.equals(1))).getSingleOrNull();
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now();
    await _db
        .into(_db.printerSettings)
        .insert(
          PrinterSettingsCompanion.insert(updatedAt: now),
          mode: InsertMode.insertOrIgnore,
        );
    return (_db.select(
      _db.printerSettings,
    )..where((tbl) => tbl.id.equals(1))).getSingle();
  }

  Future<void> updatePrinter(PrinterSettingsCompanion companion) {
    return (_db.update(
      _db.printerSettings,
    )..where((tbl) => tbl.id.equals(1))).write(companion);
  }
}
