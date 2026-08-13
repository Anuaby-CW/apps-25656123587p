import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/utils/id_generator.dart';
import '../../domain/models/cart_models.dart';
import '../../domain/models/enums.dart';
import '../../domain/repositories/checkout_repository_contract.dart';
import '../database/app_database.dart';
import '../database/daos/catalog_dao.dart';
import '../database/daos/orders_dao.dart';

/// Concrete implementation of [CheckoutRepositoryContract].
///
/// Encapsulates all direct DAO / database operations previously done inside
/// the domain use-cases, ensuring the domain layer never touches Drift
/// Companion classes or raw database transactions.
class CheckoutRepository implements CheckoutRepositoryContract {
  CheckoutRepository({
    required OrdersDao ordersDao,
    required CatalogDao catalogDao,
  }) : _ordersDao = ordersDao,
       _catalogDao = catalogDao;

  final OrdersDao _ordersDao;
  final CatalogDao _catalogDao;

  AppDatabase get _db => _ordersDao.database;

  @override
  Future<int> countOrdersForPrefix(String prefix) {
    return _ordersDao.countOrdersForPrefix(prefix);
  }

  @override
  Future<int> countTransactionsForPrefix(String prefix) {
    return _ordersDao.countTransactionsForPrefix(prefix);
  }

  @override
  Future<OrderRecord?> findOrder(String orderId) {
    return _ordersDao.findOrder(orderId);
  }

  @override
  Future<InventoryRecord?> inventoryForProduct(String productId) {
    return _catalogDao.inventoryForProduct(productId);
  }

  @override
  Future<void> updateInventoryQuantity(
    String productId,
    int quantity,
    DateTime now,
  ) {
    return _catalogDao.updateInventory(productId, quantity, now);
  }

  @override
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
  }) async {
    await _db.transaction(() async {
      // 1. Create customer if name or phone provided.
      String? customerId;
      if (_hasValue(customerName) || _hasValue(customerPhone)) {
        customerId = IdGenerator.create();
        await _db
            .into(_db.customers)
            .insert(
              CustomersCompanion.insert(
                id: customerId,
                name: customerName?.trim().isNotEmpty == true
                    ? customerName!.trim()
                    : 'Pelanggan umum',
                phone: Value(_clean(customerPhone)),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // 2. Create the order.
      await _db
          .into(_db.orders)
          .insert(
            OrdersCompanion.insert(
              id: orderId,
              orderNumber: orderNumber,
              cashierUserId: cashierUserId,
              customerId: Value(customerId),
              customerName: Value(_clean(customerName)),
              customerPhone: Value(_clean(customerPhone)),
              tableNumber: Value(
                orderType == OrderType.dineIn ? _clean(tableNumber) : null,
              ),
              orderType: orderType.name,
              orderStatus: OrderStatus.preparing.name,
              paymentStatus: payNow
                  ? PaymentStatus.paid.name
                  : PaymentStatus.unpaid.name,
              subtotal: total,
              discount: const Value(0),
              tax: const Value(0),
              total: total,
              notes: Value(_clean(notes)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 3. Create order items.
      for (final item in items) {
        await _db
            .into(_db.orderItems)
            .insert(
              OrderItemsCompanion.insert(
                id: IdGenerator.create(),
                orderId: orderId,
                productId: Value(item.productId),
                productNameSnapshot: item.productName,
                categoryNameSnapshot: item.categoryName,
                unitPrice: item.effectiveUnitPrice,
                quantity: item.quantity,
                subtotal: item.subtotal,
                temperatureOption: Value(item.temperatureOption),
                sugarOption: Value(item.sugarOption),
                manualBrewMethodNameSnapshot: Value(item.manualBrewMethodName),
                beanNameSnapshot: Value(item.beanName),
                addonsJson: item.addons.isEmpty
                    ? const Value(null)
                    : Value(
                        jsonEncode(
                          item.addons.map((addon) => addon.toJson()).toList(),
                        ),
                      ),
                notes: Value(_clean(item.notes)),
              ),
            );
      }

      // 4. Apply stock movements if inventory is enabled.
      if (applyInventory) {
        await _applyStockMovements(items, orderId, now);
      }

      // 5. Create payment + transaction if paying now.
      if (payNow && amountPaid != null) {
        final pid = paymentId ?? IdGenerator.create();
        final tid = transactionId ?? IdGenerator.create();
        final tnum = transactionNumber ?? '';
        await _db
            .into(_db.payments)
            .insert(
              PaymentsCompanion.insert(
                id: pid,
                orderId: orderId,
                cashierUserId: cashierUserId,
                paymentMethod: PaymentMethod.cash.name,
                amountPaid: amountPaid,
                changeAmount: amountPaid - total,
                paidAt: now,
                createdAt: now,
              ),
            );
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: tid,
                transactionNumber: tnum,
                orderId: orderId,
                paymentId: pid,
                cashierUserId: cashierUserId,
                total: total,
                createdAt: now,
              ),
            );
      }
    });
  }

  @override
  Future<void> recordPayment({
    required String orderId,
    required int orderTotal,
    required String cashierUserId,
    required int amountPaid,
    required String paymentId,
    required String transactionId,
    required String transactionNumber,
    required DateTime now,
  }) async {
    await _db.transaction(() async {
      final currentOrder = await _ordersDao.findOrder(orderId);
      if (currentOrder == null) {
        throw StateError('Pesanan tidak ditemukan');
      }
      if (currentOrder.paymentStatus != PaymentStatus.unpaid.name) {
        throw StateError('Pesanan sudah lunas atau tidak dapat dibayar');
      }
      if (currentOrder.orderStatus != OrderStatus.preparing.name &&
          currentOrder.orderStatus != OrderStatus.ready.name) {
        throw StateError('Status pesanan tidak dapat menerima pembayaran');
      }
      if (currentOrder.total != orderTotal) {
        throw StateError('Total pesanan berubah. Muat ulang pesanan.');
      }
      if (amountPaid < currentOrder.total) {
        throw StateError('Nominal pembayaran kurang');
      }
      final existingPayments = await (_db.select(
        _db.payments,
      )..where((tbl) => tbl.orderId.equals(orderId))).get();
      final existingTransactions = await (_db.select(
        _db.transactions,
      )..where((tbl) => tbl.orderId.equals(orderId))).get();
      if (existingPayments.isNotEmpty || existingTransactions.isNotEmpty) {
        throw StateError('Data pembayaran pesanan sudah tercatat');
      }

      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              id: paymentId,
              orderId: orderId,
              cashierUserId: cashierUserId,
              paymentMethod: PaymentMethod.cash.name,
              amountPaid: amountPaid,
              changeAmount: amountPaid - currentOrder.total,
              paidAt: now,
              createdAt: now,
            ),
          );
      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: transactionId,
              transactionNumber: transactionNumber,
              orderId: orderId,
              paymentId: paymentId,
              cashierUserId: cashierUserId,
              total: currentOrder.total,
              createdAt: now,
            ),
          );
      await _ordersDao.updateOrder(
        orderId,
        OrdersCompanion(
          paymentStatus: Value(PaymentStatus.paid.name),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> insertStockMovement({
    required String productId,
    required int quantityChange,
    required int quantityAfter,
    required String orderId,
    required DateTime now,
  }) async {
    await _db
        .into(_db.stockMovements)
        .insert(
          StockMovementsCompanion.insert(
            id: IdGenerator.create(),
            productId: productId,
            type: 'sale',
            quantityChange: quantityChange,
            quantityAfter: quantityAfter,
            referenceId: Value(orderId),
            notes: const Value('Pesanan dikonfirmasi'),
            createdAt: now,
          ),
        );
  }

  // ── Private helpers ──────────────────────────────────────────────────

  Future<void> _applyStockMovements(
    List<CartItem> items,
    String orderId,
    DateTime now,
  ) async {
    final requiredByProduct = <String, int>{};
    for (final item in items.where((item) => item.trackInventory)) {
      requiredByProduct[item.productId] =
          (requiredByProduct[item.productId] ?? 0) + item.quantity;
    }
    for (final entry in requiredByProduct.entries) {
      final inventory = await _catalogDao.inventoryForProduct(entry.key);
      if (inventory == null) continue;
      final nextQty = inventory.quantity - entry.value;
      await _catalogDao.updateInventory(entry.key, nextQty, now);
      await _db
          .into(_db.stockMovements)
          .insert(
            StockMovementsCompanion.insert(
              id: IdGenerator.create(),
              productId: entry.key,
              type: 'sale',
              quantityChange: -entry.value,
              quantityAfter: nextQty,
              referenceId: Value(orderId),
              notes: const Value('Pesanan dikonfirmasi'),
              createdAt: now,
            ),
          );
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
