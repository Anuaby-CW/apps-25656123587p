import 'package:drift/drift.dart';

import '../../domain/repositories/settings_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/settings_dao.dart';

class SettingsRepository implements SettingsRepositoryContract {
  SettingsRepository(this._dao);

  final SettingsDao _dao;

  @override
  Future<Map<String, String>> allSettings() => _dao.allSettings();

  @override
  Future<bool> inventoryEnabled() async {
    final value = await _dao.value('inventory_enabled');
    return value != 'false';
  }

  @override
  Future<void> setInventoryEnabled(bool enabled) {
    return _dao.upsert('inventory_enabled', enabled.toString());
  }

  @override
  Future<void> saveOutletSettings({
    required String outletName,
    required String outletAddress,
    required String outletWhatsapp,
    required String outletInstagram,
    required String receiptFooter,
  }) async {
    await _dao.upsert('outlet_name', outletName);
    await _dao.upsert('outlet_address', outletAddress);
    await _dao.upsert('outlet_whatsapp', outletWhatsapp);
    await _dao.upsert('outlet_instagram', outletInstagram);
    await _dao.upsert('receipt_footer', receiptFooter);
  }

  @override
  Future<PrinterSettingRecord> printerSettings() => _dao.printerSettings();

  @override
  Future<void> savePrinter({
    String? printerName,
    String? printerAddress,
    String? paperSize,
    bool? cashDrawerEnabled,
    String? lastConnectionStatus,
  }) {
    return _dao.updatePrinter(
      PrinterSettingsCompanion(
        printerName: printerName == null
            ? const Value.absent()
            : Value(printerName),
        printerAddress: printerAddress == null
            ? const Value.absent()
            : Value(printerAddress),
        paperSize: paperSize == null ? const Value.absent() : Value(paperSize),
        isCashDrawerEnabled: cashDrawerEnabled == null
            ? const Value.absent()
            : Value(cashDrawerEnabled),
        lastConnectionStatus: lastConnectionStatus == null
            ? const Value.absent()
            : Value(lastConnectionStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> saveSetting(String key, String value) {
    return _dao.upsert(key, value);
  }
}
