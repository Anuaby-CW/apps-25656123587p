/// Domain contract for CheckoutRepository. Concrete implementation in data layer.
library;

import '../../data/database/app_database.dart';
import '../models/cart_models.dart';
import '../models/enums.dart';

abstract class CheckoutRepositoryContract {
  Future<int> countOrdersForPrefix(String prefix);

  Future<int> countTransactionsForPrefix(String prefix);

  Future<OrderRecord?> findOrder(String orderId);

  Future<InventoryRecord?> inventoryForProduct(String productId);

  Future<void> updateInventoryQuantity(
    String productId,
    int quantity,
    DateTime now,
  );

  Future<void> saveOrder({
    required String orderId,
    required String orderNumber,
    required String cashierUserId,
    required List<CartItem> items,
    required OrderType orderType,
    required int total,
    required DateTime now,
    required bool payNow,
    String? customerName,
    String? customerPhone,
    String? tableNumber,
    String? notes,
    int? amountPaid,
    String? paymentId,
    String? transactionId,
    String? transactionNumber,
    required bool applyInventory,
  });

  Future<void> recordPayment({
    required String orderId,
    required int orderTotal,
    required String cashierUserId,
    required int amountPaid,
    required String paymentId,
    required String transactionId,
    required String transactionNumber,
    required DateTime now,
  });

  Future<void> insertStockMovement({
    required String productId,
    required int quantityChange,
    required int quantityAfter,
    required String orderId,
    required DateTime now,
  });
}
