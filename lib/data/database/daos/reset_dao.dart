import 'package:drift/drift.dart';

import '../app_database.dart';

part 'reset_dao.g.dart';

@DriftAccessor(
  tables: [
    Orders,
    OrderItems,
    Payments,
    Transactions,
    StockMovements,
    AuditLogs,
    PrinterLogs,
    Categories,
    Products,
    ProductFavorites,
    Addons,
    ProductAddons,
    Beans,
    ManualBrewMethods,
    Inventory,
    Customers,
  ],
)
class ResetDao extends DatabaseAccessor<AppDatabase> with _$ResetDaoMixin {
  ResetDao(super.db);

  Future<bool> hasOpenOrders() async {
    final order =
        await (select(orders)
              ..where(
                (tbl) =>
                    tbl.orderStatus.isNotIn(const ['completed', 'cancelled']),
              )
              ..limit(1))
            .getSingleOrNull();
    return order != null;
  }

  Future<void> clearTransactionalData() {
    return transaction(() async {
      final orderRows = await select(orders).get();
      final orderIds = orderRows.map((order) => order.id).toList();

      if (orderIds.isNotEmpty) {
        final transactionalMovements =
            await (select(stockMovements)..where(
                  (tbl) =>
                      tbl.referenceId.isIn(orderIds) &
                      tbl.type.isIn(const ['sale', 'sale_reversal']),
                ))
                .get();
        final netChangeByProduct = <String, int>{};
        for (final movement in transactionalMovements) {
          netChangeByProduct[movement.productId] =
              (netChangeByProduct[movement.productId] ?? 0) +
              movement.quantityChange;
        }

        final now = DateTime.now();
        for (final entry in netChangeByProduct.entries) {
          if (entry.value == 0) {
            continue;
          }
          final inventoryRow = await (select(
            inventory,
          )..where((tbl) => tbl.productId.equals(entry.key))).getSingleOrNull();
          if (inventoryRow == null) {
            throw StateError(
              'Persediaan ${entry.key} tidak ditemukan; reset transaksi dibatalkan',
            );
          }
          final restoredQuantity = inventoryRow.quantity - entry.value;
          if (restoredQuantity < 0) {
            throw StateError(
              'Hasil pemulihan stok ${entry.key} tidak valid; reset transaksi dibatalkan',
            );
          }
          await (update(
            inventory,
          )..where((tbl) => tbl.productId.equals(entry.key))).write(
            InventoryCompanion(
              quantity: Value(restoredQuantity),
              updatedAt: Value(now),
            ),
          );
        }

        await (delete(stockMovements)..where(
              (tbl) =>
                  tbl.referenceId.isIn(orderIds) &
                  tbl.type.isIn(const ['sale', 'sale_reversal']),
            ))
            .go();
      }

      await delete(transactions).go();
      await delete(payments).go();
      await delete(orderItems).go();
      await delete(orders).go();
      await attachedDatabase.delete(attachedDatabase.pettyCash).go();
      await (attachedDatabase.delete(attachedDatabase.settings)..where(
            (tbl) => tbl.key.isIn(const [
              'shift_active',
              'shift_cashier_id',
              'shift_cashier_name',
              'shift_start_time',
              'shift_opening_cash',
            ]),
          ))
          .go();
    });
  }

  Future<void> clearSessionLogs() {
    return transaction(() async {
      await delete(auditLogs).go();
      await delete(printerLogs).go();
    });
  }

  Future<void> clearReferenceCache() {
    return transaction(() async {
      await delete(inventory).go();
      await delete(productAddons).go();
      await delete(productFavorites).go();
      await delete(addons).go();
      await delete(beans).go();
      await delete(manualBrewMethods).go();
      await delete(products).go();
      await delete(categories).go();
    });
  }

  Future<void> clearCustomers() {
    return delete(customers).go();
  }
}
