import '../../domain/repositories/reset_repository_contract.dart';
import '../database/seed_data.dart';
import '../database/daos/reset_dao.dart';

class ResetRepository implements ResetRepositoryContract {
  ResetRepository(this._dao, this._seedData);

  final ResetDao _dao;
  final SeedData _seedData;

  @override
  Future<void> resetSelected({
    required bool transactionalData,
    required bool sessionLogs,
    required bool referenceData,
    required bool customers,
  }) {
    return _dao.transaction(() async {
      if (referenceData && !transactionalData && await _dao.hasOpenOrders()) {
        throw StateError(
          'Selesaikan pesanan aktif atau pilih juga Riwayat Transaksi sebelum mereset katalog',
        );
      }
      if (transactionalData) await _dao.clearTransactionalData();
      if (sessionLogs) await _dao.clearSessionLogs();
      if (referenceData) await _seedData.resetCatalogToBundledDefaults();
      if (customers) await _dao.clearCustomers();
    });
  }

  @override
  Future<void> clearTransactionalData() => _dao.clearTransactionalData();

  @override
  Future<void> clearSessionLogs() => _dao.clearSessionLogs();

  @override
  Future<void> clearReferenceCache() =>
      _seedData.resetCatalogToBundledDefaults();

  @override
  Future<void> clearCustomers() => _dao.clearCustomers();
}
