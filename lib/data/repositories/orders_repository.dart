import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/order_models.dart';
import '../../domain/repositories/orders_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/orders_dao.dart';
import '../database/daos/users_dao.dart';

class OrdersRepository implements OrdersRepositoryContract {
  OrdersRepository(this._ordersDao, this._usersDao);

  final OrdersDao _ordersDao;
  final UsersDao _usersDao;

  @override
  Stream<List<OrderRecord>> watchOrders() => _ordersDao.watchOrders();

  @override
  Future<OrderDetail> detail(String orderId) async {
    final order = await _ordersDao.findOrder(orderId);
    if (order == null) {
      throw StateError('Pesanan tidak ditemukan');
    }
    final items = await _ordersDao.items(orderId);
    final payment = await _ordersDao.payment(orderId);
    final transaction = await _ordersDao.transactionRecord(orderId);
    final cashier = await _usersDao.findById(order.cashierUserId);
    return OrderDetail(
      order: order,
      items: items,
      payment: payment,
      transaction: transaction,
      cashier: cashier,
    );
  }

  @override
  Future<void> markReady(String orderId) async {
    await _ordersDao.database.transaction(() async {
      final order = await _requireOrder(orderId);
      if (order.orderStatus != OrderStatus.preparing.name) {
        throw StateError(
          'Hanya pesanan yang sedang disiapkan dapat ditandai siap',
        );
      }
      await _ordersDao.updateOrder(
        orderId,
        OrdersCompanion(
          orderStatus: Value(OrderStatus.ready.name),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> complete(String orderId) async {
    await _ordersDao.database.transaction(() async {
      final order = await _requireOrder(orderId);
      if (order.orderStatus != OrderStatus.ready.name) {
        throw StateError('Hanya pesanan siap yang dapat diselesaikan');
      }
      if (order.paymentStatus != PaymentStatus.paid.name) {
        throw StateError('Pesanan harus lunas sebelum diselesaikan');
      }
      final now = DateTime.now();
      await _ordersDao.updateOrder(
        orderId,
        OrdersCompanion(
          orderStatus: Value(OrderStatus.completed.name),
          updatedAt: Value(now),
          completedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> cancel(String orderId) async {
    final db = _ordersDao.database;
    await db.transaction(() async {
      final order = await _requireOrder(orderId);
      if (order.paymentStatus != PaymentStatus.unpaid.name) {
        throw StateError(
          'Pesanan lunas tidak dapat dibatalkan. Gunakan proses pengembalian dana.',
        );
      }
      if (order.orderStatus != OrderStatus.preparing.name &&
          order.orderStatus != OrderStatus.ready.name) {
        throw StateError('Status pesanan tidak dapat dibatalkan');
      }

      final movements =
          await (db.select(db.stockMovements)..where(
                (tbl) =>
                    tbl.referenceId.equals(orderId) &
                    tbl.type.isIn(const ['sale', 'sale_reversal']),
              ))
              .get();
      if (movements.any((movement) => movement.type == 'sale_reversal')) {
        throw StateError('Stok pesanan sudah pernah dikembalikan');
      }

      final restoreByProduct = <String, int>{};
      for (final movement in movements.where(
        (movement) => movement.type == 'sale' && movement.quantityChange < 0,
      )) {
        restoreByProduct[movement.productId] =
            (restoreByProduct[movement.productId] ?? 0) -
            movement.quantityChange;
      }

      final now = DateTime.now();
      for (final entry in restoreByProduct.entries) {
        final inventory = await (db.select(
          db.inventory,
        )..where((tbl) => tbl.productId.equals(entry.key))).getSingleOrNull();
        if (inventory == null) {
          throw StateError(
            'Persediaan produk tidak ditemukan; pembatalan dibatalkan untuk menjaga konsistensi stok',
          );
        }
        final quantityAfter = inventory.quantity + entry.value;
        await (db.update(
          db.inventory,
        )..where((tbl) => tbl.productId.equals(entry.key))).write(
          InventoryCompanion(
            quantity: Value(quantityAfter),
            updatedAt: Value(now),
          ),
        );
        await db
            .into(db.stockMovements)
            .insert(
              StockMovementsCompanion.insert(
                id: IdGenerator.create(),
                productId: entry.key,
                type: 'sale_reversal',
                quantityChange: entry.value,
                quantityAfter: quantityAfter,
                referenceId: Value(orderId),
                notes: const Value(
                  'Stok dikembalikan karena pesanan dibatalkan',
                ),
                createdAt: now,
              ),
            );
      }

      await _ordersDao.updateOrder(
        orderId,
        OrdersCompanion(
          orderStatus: Value(OrderStatus.cancelled.name),
          updatedAt: Value(now),
          cancelledAt: Value(now),
        ),
      );
    });
  }

  Future<OrderRecord> _requireOrder(String orderId) async {
    final order = await _ordersDao.findOrder(orderId);
    if (order == null) {
      throw StateError('Pesanan tidak ditemukan');
    }
    return order;
  }
}
