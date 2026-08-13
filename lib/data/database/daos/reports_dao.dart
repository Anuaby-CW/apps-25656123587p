import 'package:drift/drift.dart';

import '../app_database.dart';

class ReportsDao {
  ReportsDao(this._db);

  final AppDatabase _db;

  /// Paid sales are periodized by payment time, not order creation time.
  Future<List<OrderRecord>> paidOrders(DateTime start, DateTime end) async {
    final payments = await _paymentsInRange(start, end);
    final eligibleIds = await _eligiblePaidOrderIds(payments);
    if (eligibleIds.isEmpty) {
      return [];
    }
    return (_db.select(
      _db.orders,
    )..where((tbl) => tbl.id.isIn(eligibleIds.toList()))).get();
  }

  Future<List<OrderRecord>> unpaidOrders(DateTime start, DateTime end) {
    return (_db.select(_db.orders)..where(
          (tbl) =>
              tbl.paymentStatus.equals('unpaid') &
              tbl.orderStatus.isNotIn(['cancelled']) &
              tbl.createdAt.isBiggerOrEqualValue(start) &
              tbl.createdAt.isSmallerThanValue(end),
        ))
        .get();
  }

  Future<List<OrderRecord>> cancelledOrders(DateTime start, DateTime end) {
    return (_db.select(_db.orders)..where(
          (tbl) =>
              tbl.orderStatus.equals('cancelled') &
              tbl.cancelledAt.isBiggerOrEqualValue(start) &
              tbl.cancelledAt.isSmallerThanValue(end),
        ))
        .get();
  }

  Future<List<PaymentRecord>> paidPayments(DateTime start, DateTime end) async {
    final payments = await _paymentsInRange(start, end);
    final eligibleIds = await _eligiblePaidOrderIds(payments);
    return payments
        .where((payment) => eligibleIds.contains(payment.orderId))
        .toList();
  }

  Future<List<OrderItemRecord>> itemsForOrders(List<String> orderIds) {
    if (orderIds.isEmpty) {
      return Future.value([]);
    }
    return (_db.select(
      _db.orderItems,
    )..where((tbl) => tbl.orderId.isIn(orderIds))).get();
  }

  Future<List<PaymentRecord>> _paymentsInRange(DateTime start, DateTime end) {
    return (_db.select(_db.payments)..where(
          (tbl) =>
              tbl.paidAt.isBiggerOrEqualValue(start) &
              tbl.paidAt.isSmallerThanValue(end),
        ))
        .get();
  }

  Future<Set<String>> _eligiblePaidOrderIds(
    List<PaymentRecord> payments,
  ) async {
    if (payments.isEmpty) {
      return {};
    }
    final orderIds = payments.map((payment) => payment.orderId).toSet();
    final orders =
        await (_db.select(_db.orders)..where(
              (tbl) =>
                  tbl.id.isIn(orderIds.toList()) &
                  tbl.paymentStatus.equals('paid') &
                  tbl.orderStatus.isNotIn(['cancelled']),
            ))
            .get();
    return orders.map((order) => order.id).toSet();
  }
}
