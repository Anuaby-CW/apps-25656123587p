// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_dao.dart';

// ignore_for_file: type=lint
mixin _$ResetDaoMixin on DatabaseAccessor<AppDatabase> {
  $OrdersTable get orders => attachedDatabase.orders;
  $OrderItemsTable get orderItems => attachedDatabase.orderItems;
  $PaymentsTable get payments => attachedDatabase.payments;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $AuditLogsTable get auditLogs => attachedDatabase.auditLogs;
  $PrinterLogsTable get printerLogs => attachedDatabase.printerLogs;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $ProductFavoritesTable get productFavorites =>
      attachedDatabase.productFavorites;
  $AddonsTable get addons => attachedDatabase.addons;
  $ProductAddonsTable get productAddons => attachedDatabase.productAddons;
  $BeansTable get beans => attachedDatabase.beans;
  $ManualBrewMethodsTable get manualBrewMethods =>
      attachedDatabase.manualBrewMethods;
  $InventoryTable get inventory => attachedDatabase.inventory;
  $CustomersTable get customers => attachedDatabase.customers;
  ResetDaoManager get managers => ResetDaoManager(this);
}

class ResetDaoManager {
  final _$ResetDaoMixin _db;
  ResetDaoManager(this._db);
  $$OrdersTableTableManager get orders =>
      $$OrdersTableTableManager(_db.attachedDatabase, _db.orders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db.attachedDatabase, _db.orderItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db.attachedDatabase, _db.payments);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db.attachedDatabase, _db.transactions);
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
        _db.attachedDatabase,
        _db.stockMovements,
      );
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db.attachedDatabase, _db.auditLogs);
  $$PrinterLogsTableTableManager get printerLogs =>
      $$PrinterLogsTableTableManager(_db.attachedDatabase, _db.printerLogs);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ProductFavoritesTableTableManager get productFavorites =>
      $$ProductFavoritesTableTableManager(
        _db.attachedDatabase,
        _db.productFavorites,
      );
  $$AddonsTableTableManager get addons =>
      $$AddonsTableTableManager(_db.attachedDatabase, _db.addons);
  $$ProductAddonsTableTableManager get productAddons =>
      $$ProductAddonsTableTableManager(_db.attachedDatabase, _db.productAddons);
  $$BeansTableTableManager get beans =>
      $$BeansTableTableManager(_db.attachedDatabase, _db.beans);
  $$ManualBrewMethodsTableTableManager get manualBrewMethods =>
      $$ManualBrewMethodsTableTableManager(
        _db.attachedDatabase,
        _db.manualBrewMethods,
      );
  $$InventoryTableTableManager get inventory =>
      $$InventoryTableTableManager(_db.attachedDatabase, _db.inventory);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
}
