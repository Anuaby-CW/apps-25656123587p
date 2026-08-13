import '../../domain/models/report_models.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/reports_repository_contract.dart';
import '../database/daos/reports_dao.dart';

class ReportsRepository implements ReportsRepositoryContract {
  ReportsRepository(this._dao);

  final ReportsDao _dao;

  @override
  Future<ReportSummary> summary(DateTime start, DateTime end) async {
    final paidOrders = await _dao.paidOrders(start, end);
    final unpaidOrders = await _dao.unpaidOrders(start, end);
    final cancelledOrders = await _dao.cancelledOrders(start, end);
    final payments = await _dao.paidPayments(start, end);
    final items = await _dao.itemsForOrders(
      paidOrders.map((order) => order.id).toList(),
    );

    final productQty = <String, int>{};
    final salesByCategory = <String, int>{};
    for (final item in items) {
      productQty[item.productNameSnapshot] =
          (productQty[item.productNameSnapshot] ?? 0) + item.quantity;
      salesByCategory[item.categoryNameSnapshot] =
          (salesByCategory[item.categoryNameSnapshot] ?? 0) + item.subtotal;
    }

    final bestSellingProduct = productQty.entries.isEmpty
        ? '-'
        : (productQty.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    return ReportSummary(
      totalRevenue: paidOrders.fold(0, (sum, order) => sum + order.total),
      paidTransactionCount: paidOrders.length,
      unpaidOrderCount: unpaidOrders.length,
      bestSellingProduct: bestSellingProduct,
      salesByCategory: salesByCategory,
      totalCashReceived: payments.fold(
        0,
        (sum, payment) =>
            sum +
            (PaymentMethod.cashDbValues.contains(payment.paymentMethod)
                ? payment.amountPaid - payment.changeAmount
                : 0),
      ),
      cancelledOrderCount: cancelledOrders.length,
      productQuantities: productQty,
    );
  }
}
