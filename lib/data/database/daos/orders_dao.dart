import 'package:drift/drift.dart';

import '../app_database.dart';

class OrdersDao {
  OrdersDao(this._db);

  final AppDatabase _db;

  AppDatabase get database => _db;

  Stream<List<OrderRecord>> watchOrders() {
    return (_db.select(
      _db.orders,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).watch();
  }

  Future<List<OrderRecord>> listOrders() {
    return (_db.select(
      _db.orders,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
  }

  Future<OrderRecord?> findOrder(String id) {
    return (_db.select(
      _db.orders,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<List<OrderItemRecord>> items(String orderId) {
    return (_db.select(
      _db.orderItems,
    )..where((tbl) => tbl.orderId.equals(orderId))).get();
  }

  Future<PaymentRecord?> payment(String orderId) {
    return (_db.select(
      _db.payments,
    )..where((tbl) => tbl.orderId.equals(orderId))).getSingleOrNull();
  }

  Future<TransactionRecord?> transactionRecord(String orderId) {
    return (_db.select(
      _db.transactions,
    )..where((tbl) => tbl.orderId.equals(orderId))).getSingleOrNull();
  }

  Future<int> countOrdersForPrefix(String prefix) {
    final count = _db.orders.id.count();
    final query = _db.selectOnly(_db.orders)
      ..addColumns([count])
      ..where(_db.orders.orderNumber.like('$prefix%'));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<int> countTransactionsForPrefix(String prefix) {
    final count = _db.transactions.id.count();
    final query = _db.selectOnly(_db.transactions)
      ..addColumns([count])
      ..where(_db.transactions.transactionNumber.like('$prefix%'));
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  Future<void> updateOrder(String id, OrdersCompanion companion) {
    return (_db.update(
      _db.orders,
    )..where((tbl) => tbl.id.equals(id))).write(companion);
  }
}
